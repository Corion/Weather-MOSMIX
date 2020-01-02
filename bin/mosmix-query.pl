#!perl
package main;
use strict;
use Weather::MOSMIX;
use Data::Dumper;
use charnames ':full';
use Weather::MOSMIX;
use Time::Piece;

my $w = Weather::MOSMIX->new(
    dsn => 'dbi:SQLite:dbname=db/forecast.sqlite',
);

# Read location from .locationrc
# File::HomeDir
# ~/.config/.locationrc
# ~/.locationrc

my $out =
    $w->formatted_forecast(latitude => 50.11, longitude => 8.68 );

binmode STDOUT, ':encoding(UTF-8)';

for my $day ('today', 'tomorrow') {
    my $issue = substr $out->{issuetime},0,10;
    my $date = $out->{weather}->{$day}->{date}->strftime('%Y-%m-%d');
    print "$out->{location} (\x{1F321}$Weather::MOSMIX::Weathercodes::as_emoji $out->{weather}->{$day}->{min}/$out->{weather}->{$day}->{max}) ($date)\n";
    for my $w (@{ $out->{weather}->{$day}->{weather}}) {
        print $w->{timestamp}, "\n";
        print sprintf "%02d %s$Weather::MOSMIX::Weathercodes::as_emoji %s\n", $w->{timestamp}->hour, $w->{description}->{emoji}, $w->{description}->{text};
    };
};
