#!perl
use strict;
use warnings;
use Weather::MOSMIX::Writer;
use Getopt::Long;

our $VERSION = '0.01';

my $w = Weather::MOSMIX::Writer->new(
    dbh => {
        dsn => 'dbi:SQLite:dbname=db/forecast.sqlite',
    }
);
$w->purge_outdated_expired_records();
