
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Config" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "IO::Handle" => 0,
    "IO::Socket::INET" => 0,
    "Module::Build" => "0.3601",
    "Scalar::Util" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0,
    "Test::NoWarnings" => 0,
    "Test::Warn" => 0,
    "Time::HiRes" => 0,
    "if" => 0,
    "open" => 0,
    "utf8" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Memory mapping made simple and safe.",
  "dist_author" => [
    "Leon Timmermans <fawaka\@gmail.com>"
  ],
  "dist_name" => "File-Map",
  "dist_version" => "0.53",
  "license" => "perl",
  "module_name" => "File::Map",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Const::Fast" => 0,
    "PerlIO::Layers" => 0,
    "Sub::Exporter::Progressive" => 0,
    "XSLoader" => 0,
    "perl" => "5.008",
    "strict" => 0,
    "subs" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
