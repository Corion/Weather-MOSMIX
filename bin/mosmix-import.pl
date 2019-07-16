#!perl
use strict;
use warnings;
use Weather::MOSMIX::Writer;
use Weather::MOSMIX::Reader;

my $w = Weather::MOSMIX::Writer->new(
    dsn => 'dbi:SQLite:dbname=db/forecast.sqlite',
);
my $r = Weather::MOSMIX::Reader->new(
    writer => $w,
);
$r->read_zip( $ARGV[0] );
