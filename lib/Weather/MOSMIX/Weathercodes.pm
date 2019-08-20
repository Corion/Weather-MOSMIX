package Weather::MOSMIX::Weathercodes;
use strict;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

use Exporter 'import';

our @EXPORT_OK = 'mosmix_weathercode';

our $VERSION = '0.01';

our $as_emoji = "\x{fe0f}";

our %weathercodes = (
    # Should we separate these into day/night ?!
    # We should add the textual description, even if only to translate that later on
    '00' => { emoji => "\N{SUN}",                        svg => 'day.svg',
              text  => 'sunny' },
    '01' => { emoji => "\N{WHITE SUN WITH SMALL CLOUD}", svg => 'day-partly-cloudy.svg',
              text  => 'partly cloudy', },
    '02' => { emoji => "\N{WHITE SUN WITH SMALL CLOUD}", svg => 'day-partly-cloudy.svg' },
    '03' => { emoji => "\N{SUN BEHIND CLOUD}",           svg => 'day-cloudy.svg' },
    '04' => { emoji => "\N{CLOUD}",                      svg => 'day-cloudy.svg' },
    '45' => { emoji => "\N{FOG}",                        svg => 'fog.svg' },
    '49' => { emoji => "\N{FOG}",                        svg => 'fog.svg' },
    '61' => { emoji => "\N{CLOUD WITH RAIN}",            svg => 'rain.svg', text => 'slight rain, not freezing, continuous' },
    '63' => { emoji => "\N{CLOUD WITH RAIN}",            svg => 'rain.svg' },
    '80' => { emoji => "\N{CLOUD WITH RAIN}",            svg => 'day-light-rain.svg' }, # light rain
    '81' => { emoji => "\N{RAIN}",                       svg => 'day-rain.svg'       }, # medium rain
    '82' => { emoji => "\N{RAIN}",                       svg => 'day-showers.svg'    }, # strong rain
    '95' => { emoji => "\N{RAIN}",                       svg => 'thundershowers.svg',
              text  => 'slight or moderate thunderstorm with rain or snow'
            },
);

sub mosmix_weathercode($code, $type = undef) {
    if( $type ) {
        my $c = $weathercodes{$code}->{ $type };
        return $c ? $c . $as_emoji : $code;
    } else {
        return $weathercodes{ $code }
    }
}

1;

=head1 NAME

Weather::MOSMIX::Weathercodes - weather codes for MOSMIX data

=head1 SYNOPSIS

  use Weather::MOSMIX::Weathercodes 'mosmix_weathercode';
  print mosmix_weathercode('01')->{text}; # sunny
  print mosmix_weathercode('01')->{emoji}; # \N{SUN} emoji

=head1 FUNCTIONS

=head2 C<< mosmix_weathercode >>

  my $c = mosmix_weathercode('01');

This function returns a reference to a hash of items representing a
weather code. The hash keys are:

=over 4

=item B<<emoji>>

Emoji representing this weather code

=item B<<svg>>

SVG filename representing this weather code, taken from the Tempestacons

=item B<<text>>

English text description as provided by DWD

=back

=head1 SEE ALSO

L<https://www.dwd.de/DE/leistungen/opendata/help/schluessel_datenformate/kml/mosmix_element_weather_xls.html>

L<Tempestacons|https://github.com/zagortenay333/Tempestacons/>

=cut
