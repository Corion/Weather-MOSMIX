#!perl
package main;
use strict;
use Weather::MOSMIX;
use Data::Dumper;
use Charnames ':full';
use Weather::MOSMIX;
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

my %weathercodes = (
    '01' => "\N{SUN}",
    '02' => "\N{WHITE SUN WITH SMALL CLOUD}",
    '03' => "\N{SUN BEHIND CLOUD}",
    '04' => "\N{CLOUD}",
    '45' => "\N{FOG}",
    '49' => "\N{FOG}",
    '61' => "\N{CLOUD WITH RAIN}",
    '63' => "\N{CLOUD WITH RAIN}",
);

my $weather = join '', map { my $v = sprintf '%02d', 0+$_; $weathercodes{$v} || $v } @{$weathercode->{values}};

$max -= 273.15;
$min -= 273.15;

binmode STDOUT, ':encoding(UTF-8)';

print "$loc (\x{1F321} $min/$max) $weather\n";
