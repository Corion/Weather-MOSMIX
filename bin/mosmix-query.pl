package Weather::MOSMIX;
use Moo 2;
use feature 'signatures';
no warnings 'experimental::signatures';
use DBI;
use JSON;

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

package main;
use strict;
use Data::Dumper;
my $w = Weather::MOSMIX->new(
    dsn => 'dbi:SQLite:dbname=db/forecast.sqlite',
);
print Dumper
    $w->forecast(latitude => 50.11, longitude => 8.68 );
