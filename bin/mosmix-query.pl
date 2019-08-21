#!perl
package main;
use strict;
use Weather::MOSMIX;
use Data::Dumper;
use charnames ':full';
use Weather::MOSMIX;
use Weather::MOSMIX::Weathercodes 'mosmix_weathercode';
use Time::Piece;

my $w = Weather::MOSMIX->new(
    dsn => 'dbi:SQLite:dbname=db/forecast.sqlite',
);

# Read location from .locationrc
# File::HomeDir
# ~/.config/.locationrc
# ~/.locationrc

sub format_forecast_day {
    my( $ts, $temp, $weathercode, $offset, $count ) = @_;

    my ($min, $max) = (1000,0);
    for my $f (grep { length $_ } @{ $temp->{values} }[$offset..$offset+$count-1]) {
        if( $f < $min ) {
            $min = $f;
        };
        if( $f > $max ) {
            $max = $f;
        };
    };

    $max -= 273.15;
    $min -= 273.15;

    my $weather = [];
    my %forecast = (
        date    => $ts->new(),
        weather => $weather,
        min     => $min,
        max     => $max,
    );

    my $time = $ts->new();
    for my $i ($offset..$offset+$count-1) {
        my $c = $weathercode->{values}->[ $i ];
        if( length $c ) {
            my $v = sprintf '%02d', 0+$c;
            push @{ $weather }, {
                timestamp   => $time->new(),
                description => mosmix_weathercode($v),
            };
            $time += 3600;
        };
    };

    return \%forecast,
};

sub format_forecast {
    my( $f ) = @_;
    my $loc = $f->{description};
    (my $temp) = grep{ $_->{type} eq 'TTT' } @{ $f->{forecasts}};
    (my $weathercode) = grep{ $_->{type} eq 'ww' } @{ $f->{forecasts}};

    my $time = Time::Piece->strptime( $f->{issuetime}, '%Y-%m-%dT%H:%M:%SZ' );

    # Find where today ends, and add a linebreak, resp. move to the next array ...
    my @forecasts;
    my %weather = (
        #today    => $weath,
        #tomorrow => [],
        #tomnext  => [],
        days     => \@forecasts,
    );
    my %sequence = (
        today    => 'tomorrow',
        tomorrow => 'tomnext',
    );

    my $offset = 0;
    my $count = 0;
    my $today = $time->truncate(to => 'day');
    my $start = $time->new();
    my $slot = 'today';

    while( $offset < @{$weathercode->{values}} ) {
        $time += 3600;
        $count++;
        if( $time->truncate( to => 'day' ) != $today ) {
            push @forecasts, format_forecast_day( $start, $temp, $weathercode, $offset, $count );
            $offset += $count;
            $count = 0;
            if( defined $slot ) {
                print "$slot ($today) -> $sequence{ $slot } ($time)\n";
                $slot = $sequence{ $slot };
            };
            $today = $time->truncate( to => 'day' );
            $start = $today;
        };
    };

    $weather{ today }    = $forecasts[0];
    $weather{ tomorrow } = $forecasts[1];
    $weather{ tomnext }  = $forecasts[2];

    return {
        issuetime => $f->{issuetime},
        location  => $loc,
        weather   => \%weather,
    }
}

my $f =
    $w->forecast(latitude => 50.11, longitude => 8.68 );
my $out = format_forecast( $f );

binmode STDOUT, ':encoding(UTF-8)';

for my $day ('today', 'tomorrow') {
    print "$out->{location} (\x{1F321}$Weather::MOSMIX::Weathercodes::as_emoji $out->{weather}->{$day}->{min}/$out->{weather}->{$day}->{max})\n";
    for my $w (@{ $out->{weather}->{$day}->{weather}}) {
        print sprintf "%02d %s$Weather::MOSMIX::Weathercodes::as_emoji %s\n", $w->{timestamp}->hour, $w->{description}->{emoji}, $w->{description}->{text};
    };
};
