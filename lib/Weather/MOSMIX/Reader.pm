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
use Weather::MOSMIX::Writer;

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

# Ugly global variable to store state :-/
has 'expiry' => (
    is => 'rw',
);

has 'writer' => (
    is => 'ro',
);

sub file_expiry( $self, $filename ) {
    $filename =~ m/MOSMIX_S_(20\d\d)(\d\d)(\d\d)(\d\d)_/
        or die "Couldn't read file date/time from filename '$filename'";
    my $d = $3 +1; # we'll hang onto the data for 24 hours
    # XXX this should really be a calculation from timelocal instead...
    "$1-$2-$d $4:00:00"
}

# This could be in its own module?! IO::ReadZipContent ?
sub read_zip( $self, $filename, $expiry=$self->file_expiry($filename) ) {
    my $reader = Archive::Zip->new( $filename );
    my @members = $reader->members;
    $members[0]->rewindData();
    my $stream = $members[0]->fh;
    binmode $stream => ':gzip(none)';
    $self->parse_fh($stream, $expiry);
}

sub parse_fh( $self, $fh, $expiry ) {
    $self->writer->start;
    $self->expiry($expiry);
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

1;
