package PerlIO::Layers;
{
  $PerlIO::Layers::VERSION = '0.010';
}

use 5.008_001;
use strict;
use warnings FATAL => 'all';
use XSLoader;
use PerlIO ();
use Carp qw/croak/;
use List::Util qw/reduce max/;
use List::MoreUtils qw/natatime/;
use Exporter 5.57 qw/import/;

our @EXPORT_OK = qw/query_handle get_layers get_buffer_sizes/;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

our %FLAG_FOR;
sub _names_to_flags {
	return reduce { $a | $b } map { $FLAG_FOR{$_} } @_;
}

sub _flag_names {
	my $flagbits = shift;
	return grep { $FLAG_FOR{$_} & $flagbits } keys %FLAG_FOR;
}

sub _has_flags {
	my $check_flag = _names_to_flags(@_);
	return sub {
		my ($fh, $layer) = @_;
		my $iterator = natatime(3, PerlIO::get_layers($fh, details => 1));
		while (my ($name, $arguments, $flags) = $iterator->()) {
			next if defined $layer and $name ne $layer;
			my $entry = $flags & $check_flag;
			return 1 if $entry;
		}
		return 0;
	}
}

our %KIND_FOR;
sub _is_kind {
	my $kind = shift;
	return sub {
		my $fh = shift;
		my $kinds = _get_kinds($fh);
		if (@_) {
			my $layer = shift;
			return exists $kinds->{$layer} && $kinds->{$layer} & $KIND_FOR{$kind} ? 1 : 0;
		}
		else {
			return (grep { $kinds->{$_} & $KIND_FOR{$kind} } keys %{$kinds}) ? 1 : 0;
		}
	};
}

my %is_binary = map { ( $_ => 1) } qw/unix stdio perlio crlf flock creat excl mmap/;

my $nonbinary_flags = _names_to_flags('UTF8', 'CRLF');
my $crlf_flags      = _names_to_flags('CRLF');

my %layer_query_for = (
	writeable => _has_flags('CANWRITE'),
	readable  => _has_flags('CANREAD'),
	open      => _has_flags('OPEN'),
	temp      => _has_flags('TEMP'),
	crlf      => _has_flags('CRLF'),
	utf8      => _has_flags('UTF8'),
	binary    => sub {
		my ($fh, $layer) = @_;
		my $iterator = natatime(3, PerlIO::get_layers($fh, details => 1));
		while (my ($name, $arguments, $flags) = $iterator->()) {
			next if defined $layer and $name ne $layer;
			return 0 if not $is_binary{$name} or $flags & $nonbinary_flags;
		}
		return 1;
	},
	mappable  => sub {
		my ($fh, $layer) = @_;
		my $iterator = natatime(3, PerlIO::get_layers($fh, details => 1));
		while (my ($name, $arguments, $flags) = $iterator->()) {
			next if defined $layer and $name ne $layer;
			return 0 if not $is_binary{$name} or $flags & $crlf_flags;
		}
		return 1;
	},
	layer     => sub {
		my ($fh, $layer) = @_;
		my $iterator = natatime(3, PerlIO::get_layers($fh, details => 1));
		while (my ($name, $arguments, $flags) = $iterator->()) {
			return 1 if $name eq $layer;
		}
		return 0;
	},
	buffered => _is_kind('BUFFERED'),
	can_crlf => _is_kind('CANCRLF'),
	line_buffered => _has_flags('LINEBUF'),
	autoflush => _has_flags('UNBUF'),
	buffer_size => sub {
		my ($handle, $size) = @_;
		return max(get_buffer_sizes($handle)) == $size;
	}
);

sub query_handle {
	my ($fh, $query_name, @args) = @_;
	my $layer_query = $layer_query_for{$query_name} or croak "Query $query_name isn't defined";
	return $layer_query->($fh, @args);
}

sub get_layers {
	my $fh = shift;
	my @results;
	my $iterator = natatime(3, PerlIO::get_layers($fh, details => 1));
	while (my ($name, $arguments, $flags) = $iterator->()) {
		push @results, [ $name, $arguments, [ _flag_names($flags) ] ];
	}
	return @results;
}

1;    # End of PerlIO::Layers

# ABSTRACT: Querying your filehandle's capabilities



=pod

=head1 NAME

PerlIO::Layers - Querying your filehandle's capabilities

=head1 VERSION

version 0.010

=head1 SYNOPSIS

 use PerlIO::Layers qw/query_handle/;

 if (!query_handle(\*STDOUT, 'binary')) {
     ...
 }

=head1 DESCRIPTION

Perl's filehandles are implemented as a stack of layers, with the bottom-most usually doing the actual IO and the higher ones doing buffering, encoding/decoding or transformations. PerlIO::Layers allows you to query the filehandle's properties concerning these layers.

=head1 FUNCTIONS

=head2 query_handle($fh, $query_name [, $argument])

This query a filehandle for some information. All queries can take an optional argument, that will test for that layer's properties instead of all layers of the handle. Currently supported queries include:

=over 4

=item * layer

Check the presence of a certain layer. Unlike most other properties C<$argument> is mandatory for this query.

=item * utf8

Check whether the filehandle/layer handles unicode

=item * crlf

Check whether the filehandle/layer does crlf translation

=item * binary

Check whether the filehandle/layer is binary. This test is pessimistic (for unknown layers it will assume it's not binary).

=item * mappable

Checks whether the filehandle/layer is memory mappable. It is the same as binary, except that the C<utf8> layer is accepted.

=item * buffered

Check whether the filehandle/layer is buffered.

=item * readable

Check whether the filehandle/layer is readable.

=item * writeable

Check whether the filehandle/layer is writeable.

=item * open

Check whether the filehandle/layer is open.

=item * temp

Check whether the filehandle/layer refers to a temporary file.

=item * can_crlf

Checks whether layer C<$argument> (or any layer if C<$argument> it not given) can do crlf translation.

=item * line_buffered

Check whether the filehandle is in line-buffering mode.

=item * autoflush

Checks wheter the filehandle is in unbuffering mode. Note that this is not the opposite of buffering, but more similar to autoflush, hence the name of this test.

=item * buffer_size

Check whether the buffer size is equal to C<$argument>.

=back

=head2 get_layers($fh)

Gets information on the layers of a filehandle. It's a list with whose entries have 3 elements: the name of the layer, the arguments of the layer (may be undef) and an arrayref with the flags of the layer as strings. The flags array can contain any of these values. You probably want to use query_layers instead. C<query_handle> provides a more high level interface to this, you should probably use that when you can.

=head2 get_buffer_sizes($fh)

Returns a list of buffer sizes for all buffered layers. Unbuffered layers are skipped.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

