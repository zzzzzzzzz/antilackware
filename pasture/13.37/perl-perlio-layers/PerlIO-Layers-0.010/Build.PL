
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Data::Dumper" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => "0.82"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Querying your filehandle's capabilities",
  "dist_author" => [
    "Leon Timmermans <fawaka\@gmail.com>"
  ],
  "dist_name" => "PerlIO-Layers",
  "dist_version" => "0.010",
  "license" => "perl",
  "module_name" => "PerlIO::Layers",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Exporter" => "5.57",
    "List::MoreUtils" => 0,
    "List::Util" => 0,
    "PerlIO" => 0,
    "XSLoader" => 0,
    "perl" => "5.008_001",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
