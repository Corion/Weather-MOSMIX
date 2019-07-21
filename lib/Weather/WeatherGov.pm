package Weather::WeatherGov;
use strict;
use warnings;
our $VERSION = '0.01';

use HTTP::Tiny;
use URI;
use JSON 'decode_json';

use Moo 2;
use feature 'signatures';
no warnings 'experimental::signatures';

our $base_uri = URI->new(
        $ENV{PERL_WEATHER_WEATHERGOV_URI}
    #|| 'https://forecast-v3.weather.gov/'
    || 'https://api.weather.gov/points/'
);

has 'ua' => (
    is => 'lazy',
    default => sub ($self) {
        HTTP::Tiny->new(
        )
    },
);

has 'base_uri' => (
    is => 'ro',
    default => sub { URI->new( $base_uri )},
);

sub forecast( $self, %options ) {
    my $entry = $self->base_uri . sprintf '%s,%s',
        $options{latitude},
        $options{longitude};
    # We should cache this request for office and grid position
    my $loc = $self->json_request($entry);
    $self->json_request(
        $loc->{properties}->{forecastHourly},
    );

}

sub json_request( $self, $uri ) {
    my $response = $self->ua->request(GET => $uri, {
        accept => 'JSON-LD',
    } );
    decode_json( $response->{content} );
}

1;

=head1 SEE ALSO

L<https://www.weather.gov/documentation/services-web-api>

L<https://forecast-v3.weather.gov/documentation>

=cut
