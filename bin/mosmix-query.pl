package main;
use strict;
use Data::Dumper;
use Weather::MOSMIX;
my $w = Weather::MOSMIX->new(
    dsn => 'dbi:SQLite:dbname=db/forecast.sqlite',
);
my $f =
    $w->forecast(latitude => 50.11, longitude => 8.68 );
# calculate min-temp, max-temp, primary weather for the period
# resp. go from hourly to four-hour windows?!
my ($min, $max) = (1000,0);
my $loc = $f->{description};
(my $temp) = grep{ $_->{type} eq 'TTT' } @{ $f->{forecasts}};

# Restrict to relevant slice here, instead of taking all
for my $f (grep { length $_ } @{ $temp->{values} }) {
    if( $f < $min ) {
        $min = $f;
    };
    if( $f > $max ) {
        $max = $f;
    };
};

my $weather = '-';

$max -= 273.15;
$min -= 273.15;

print "$loc ($min/$max) $weather\n";