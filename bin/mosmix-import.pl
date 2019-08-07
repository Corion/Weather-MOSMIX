#!perl
use strict;
use warnings;
use Weather::MOSMIX::Writer;
use Weather::MOSMIX::Reader;

use HTTP::Tiny;
use File::Temp 'tempfile';

use Getopt::Long;

our $VERSION = '0.01';

GetOptions(
    'import' => \my $import,
    'fetch'  => \my $fetch,
    'verbose' => \my $verbose,
);

sub status {
    if( $verbose ) {
        print "@_\n";
    };
};

my %actions;

if( !@ARGV) {
    $fetch = 1;
} else {
    $import = 1;
};

#warn "$fetch / $import";
if( ! ($import || $fetch )) {
    $fetch = 1;
    $import = 1;
};
$actions{ import } = $import;
$actions{ fetch  } = $fetch;

my @files = @ARGV;

if( $actions{ fetch }) {
    my $base = 'https://opendata.dwd.de/weather/local_forecasts/mos/MOSMIX_S/all_stations/kml/MOSMIX_S_LATEST_240.kmz';
    status( "Fetching $base" );

    my $ua = HTTP::Tiny->new();
    my( $fh, $name ) = tempfile();
    close $fh;

    my $res = $ua->mirror($base => $name);

    if( ! $res->{success}) {
        die $res->{message};
    };
    status( "Fetched " . -s($name)  ." bytes" );

    push @files, $name;
};

if( $actions{ import }) {
    my $w = Weather::MOSMIX::Writer->new(
        dsn => 'dbi:SQLite:dbname=db/forecast.sqlite',
    );
    my $r = Weather::MOSMIX::Reader->new(
        writer => $w,
    );

    for my $file (@files) {
        status("Importing $file\n");
        $r->read_zip( $file );
    };
};
