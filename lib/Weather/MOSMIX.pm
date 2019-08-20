package Weather::MOSMIX;
use strict;
use Moo 2;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';
use DBI;
use JSON;

our $VERSION = '0.01';

=head1 NAME

Reader for MOSMIX weather forecast files

=head1 SYNOPSIS

=cut

# This should be MooX::Role::DBConnection
with 'Moo::Role::DBIConnection';

our $TIMESTAMP = '%Y-%m-%dT%H:%M:%S';

has 'json' => (
    is => 'lazy',
    default => sub {
		JSON->new()
	},
);

sub forecast( $self, %options ) {
    my $cos_lat_sq = cos( $options{ latitude } ) ^ 2;

    my $res =
    $self->dbh->selectall_arrayref(<<'SQL', { Slice => {}}, $options{latitude}, $options{latitude}, $options{longitude},$options{longitude}, $cos_lat_sq);
        select *,
              ((l.latitude - ?)*(l.latitude - ?))
            + ((l.longitude - ?)*(l.longitude - ?)*?) as distance
            from forecast_location l
            join forecast f on l.name = f.name
            order by distance asc, expiry desc
            limit 1
SQL
    for (@$res) {
        $_->{forecasts} = $self->json->decode($_->{forecasts})
    };
    $res->[0]
};

=head1 SEE ALSO

German Weather Service

L<https://opendata.dwd.de/weather/>

L<https://opendata.dwd.de/weather/local_forecasts/mos/MOSMIX_S/all_stations/kml/>

Other Weather APIs

L<https://openweathermap.org/api> - international, signup required

L<https://www.weatherbit.io/api> - international, signup required

L<https://developer.accuweather.com/> - international, signup required

L<https://darksky.net/dev> - paid, international, signup required

L<http://api.weather2020.com/> - international, signup required

Overview of Open Data

L<https://index.okfn.org/place/de/weather/>
L<https://index.okfn.org/place/us/weather/>
L<https://index.okfn.org/place/lv/weather/>
L<https://index.okfn.org/place/cy/weather/>

Cyprus forecast

L<http://www.moa.gov.cy/moa/ms/ms.nsf/DMLforecast_general_gr/DMLforecast_general_gr?opendocument>

=head2 Icons

L<https://github.com/zagortenay333/Tempestacons>

=cut

1;
