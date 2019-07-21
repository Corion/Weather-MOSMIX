package Weather::MOSMIX;
use strict;
use Moo 2;
use feature 'signatures';
no warnings 'experimental::signatures';
use DBI;
use JSON;

our $VERSION = '0.01';

=head1 NAME

Reader for MOSMIX weather forecast files

=cut

# This should be MooX::Role::DBConnection
with 'Moo::Role::DBIConnection';

has 'json' => (
    is => 'lazy',
    default => sub {
		JSON->new()
	},
);

sub forecast( $self, %options ) {
    my $cos_lat_sq = cos( $options{ latitude } ) ^ 2;

    $self->dbh->selectall_arrayref(<<'SQL', { Slice => {}}, $options{latitude}, $options{latitude}, $options{longitude},$options{longitude}, $cos_lat_sq);
        select *,
              ((l.latitude - ?)*(l.latitude - ?))
            + ((l.longitude - ?)*(l.longitude - ?)*?) as distance
            from forecast_location l
            join forecast f on l.name = f.name
            order by distance asc, expiry desc
            limit 1
SQL
};

=head1 SEE ALSO

L<https://opendata.dwd.de/weather/>

L<https://opendata.dwd.de/weather/local_forecasts/mos/MOSMIX_S/all_stations/kml/>

=cut

1;
