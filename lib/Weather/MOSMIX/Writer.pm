package Weather::MOSMIX::Writer;
use strict;
use Moo 2;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';
use DBI;
require POSIX;
use JSON;

our $VERSION = '0.01';

# This should be MooX::Role::DBConnection
with 'Moo::Role::DBIConnection';

has 'insert_location_sth' => (
    is => 'lazy',
    default => \&_prepare_location_sth,
);

has 'insert_forecast_sth' => (
    is => 'lazy',
    default => \&_prepare_forecast_sth,
);

has 'json' => (
    is => 'lazy',
    default => sub {
		JSON->new()
	},
);

sub _prepare_location_sth( $self ) {
	$self->dbh->prepare(<<'SQL');
	    insert or replace into forecast_location (
	        name, description, latitude, longitude, elevation
	    ) values (
	        ?,    ?,           ?,        ?,         ?
	    )
SQL
}

sub _prepare_forecast_sth( $self ) {
	$self->dbh->prepare(<<'SQL');
	    insert into forecast (
	        name, forecasts, expiry, issuetime
	    ) values (
	        ?,    ?,        ?,       ?
	    )
SQL
}

sub purge_expired_records( $self, $date = POSIX::strftime('%Y-%m-%d %H:%M:%SZ', gmtime()) ) {
	$self->dbh->do(<<'SQL', $date);
	    delete from forecast
	        where expiry <= ?
SQL
}

sub purge_outdated_expired_records( $self ) {
	$self->dbh->do(<<'SQL');
	    delete from forecast
	        where expiry < (select max(expiry) from forecast)
SQL
}

sub start( $self ) {
	my $dbh = $self->dbh;
	$dbh->do('PRAGMA synchronous = OFF');
	$dbh->do('PRAGMA journal_mode = MEMORY');
	$dbh->{AutoCommit} = 0;
};

sub insert( $self, $expiry, @records ) {
	my $i = 0;
	$self->insert_location_sth->execute_for_fetch(sub {
		my $rec = $records[$i++];
		return if ! $rec;
		[@{$rec}{qw(name description latitude longitude elevation)}]
	});
	$i = 0;
	$self->insert_forecast_sth->execute_for_fetch(sub {
		my $rec = $records[$i++];
		return if ! $rec;
		my $f = $self->json->encode( $rec->{forecasts} );
		[$rec->{name}, $f, $expiry, $rec->{issuetime}]
	});
};

sub commit( $self ) {
	$self->dbh->commit;
}

1;
