#!perl
use strict;
use Weather::MOSMIX;
use Data::Dumper;
my $w = Weather::MOSMIX->new(
    dsn => 'dbi:SQLite:dbname=db/forecast.sqlite',
);
print Dumper
    $w->forecast(latitude => 50.11, longitude => 8.68 );
