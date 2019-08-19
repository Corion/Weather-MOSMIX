#!perl
package main;
use strict;
use Weather::MOSMIX;
use Data::Dumper;
use charnames ':full';
use Weather::MOSMIX;
use Weather::MOSMIX::Weathercodes 'mosmix_weathercode';

my $w = Weather::MOSMIX->new(
    dsn => 'dbi:SQLite:dbname=db/forecast.sqlite',
);

# Read location from .locationrc
# File::HomeDir
# ~/.config/.locationrc
# ~/.locationrc

my $f =
    $w->forecast(latitude => 50.11, longitude => 8.68 );
# calculate min-temp, max-temp, primary weather for the period
# resp. go from hourly to four-hour windows?!
my ($min, $max) = (1000,0);
my $loc = $f->{description};
(my $temp) = grep{ $_->{type} eq 'TTT' } @{ $f->{forecasts}};
(my $weathercode) = grep{ $_->{type} eq 'ww' } @{ $f->{forecasts}};

# Restrict to relevant slice here, instead of taking all
for my $f (grep { length $_ } @{ $temp->{values} }) {
    if( $f < $min ) {
        $min = $f;
    };
    if( $f > $max ) {
        $max = $f;
    };
};

my $weather = join '', map {
    if( length $_ ) {
        my $v = sprintf '%02d', 0+$_;
        mosmix_weathercode($v)
    }
} @{$weathercode->{values}};

$max -= 273.15;
$min -= 273.15;

binmode STDOUT, ':encoding(UTF-8)';

#print $f->{expiry},"\n";
print "$loc (\x{1F321}$Weather::MOSMIX::Weathercodes::as_emoji $min/$max) $weather\n";
