package main;
use strict;
use Data::Dumper;
use Weather::MOSMIX;
my $w = Weather::MOSMIX->new(
    dsn => 'dbi:SQLite:dbname=db/forecast.sqlite',
);
print Dumper
    $w->forecast(latitude => 50.11, longitude => 8.68 );
