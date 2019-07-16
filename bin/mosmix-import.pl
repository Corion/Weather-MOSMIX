package Weather::MOSMIX::Writer;
use strict;
use Moo 2;
use feature 'signatures';
no warnings 'experimental::signatures';
use DBI;
require POSIX;
use JSON;

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
	        name, forecasts, expiry
	    ) values (
	        ?,    ?,        ?
	    )
SQL
}

sub purge_expired_records( $self, $date = POSIX::strftime('%Y-%m-%d %H:%M:%S', gmtime()) ) {
	$self->dbh->do(<<'SQL', $date);
	    delete from forecast
	        where expiry <= ?
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
		[$rec->{name}, $f, $expiry]
	});
};

sub commit( $self ) {
	$self->dbh->commit;
}

package Weather::MOSMIX::Reader;
use strict;
use Moo 2;
use Archive::Zip;

use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

use Scalar::Util 'weaken';

use Archive::Zip;
use PerlIO::gzip;

has 'twig' => (
    is => 'lazy',
    default => sub {
        my( $self ) = @_;
        weaken $self;
        require XML::Twig;
        XML::Twig->new(
            no_xxe => 1,
            keep_spaces => 1,
            twig_handlers => {
                'kml:Placemark' => sub { $self->handle_place( $_[0], $_[1] ) },
            },
        )
    },
);

has 'expiry' => (
    is => 'lazy',
    default => POSIX::strftime( '%Y-%m-%d %H:%M:%S', gmtime ),
);

has 'writer' => (
    is => 'ro',
);

# This could be in its own module?! IO::ReadZipContent ?
sub read_zip( $self, $filename ) {
    my $reader = Archive::Zip->new( $filename );
    my @members = $reader->members;
    $members[0]->rewindData();
    my $stream = $members[0]->fh;
    binmode $stream => ':gzip(none)';
    $self->parse_fh($stream);
}

sub parse_fh( $self, $fh ) {
    $self->writer->start;
    $self->twig->parse($fh);
    $self->writer->commit;
}

sub handle_place( $self, $twig, $place ) {
    my $description = $place->first_child_text('kml:description');

		my ($long,$lat,$el) = split /,/, $place->first_descendant('kml:coordinates')->text;

		# filter for
		#     "ww"  - significant weather
		#     "TTT" - temperature 2m above ground
		my @forecasts = (
		    grep { $_->{type} =~ /^(ww|TTT)$/ }
		    map {+{ type => $_->att('dwd:elementName'), values => $_->first_descendant('dwd:value')->text }}
		    map {; $_->descendants('dwd:Forecast') } $place->descendants('kml:ExtendedData') );
		for (@forecasts) {
			$_->{values} = [ map { $_ eq '-' ? undef : $_ } split /\s+/, $_->{values} ];
		};

		my %info = (
		    name        => scalar $place->first_child_text('kml:name'),
		    description => scalar  $place->first_child_text('kml:description'),
			longitude => $long,
			latitude  => $lat,
			elevation => $el,
			forecasts => \@forecasts,
		);
		$self->writer->insert( $self->expiry, \%info );

        $place->purge;

    $twig->purge;
};

package main;
use strict;
my $w = Weather::MOSMIX::Writer->new(
    dsn => 'dbi:SQLite:dbname=db/forecast.sqlite',
);
my $r = Weather::MOSMIX::Reader->new(
    writer => $w,
    expiry => '2019-06-23 22:08:00',
);
$r->read_zip( $ARGV[0] );
