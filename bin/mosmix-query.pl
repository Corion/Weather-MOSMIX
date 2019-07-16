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
    $self->twig->parse($fh)
}

sub handle_place( $self, $twig, $place ) {
    my $description = $place->first_child_text('kml:description');
    #if( $description =~ /\bfrankfurt\b/i ) {
		my ($long,$lat,$el) = split /,/, $place->first_descendant('kml:coordinates')->text;

		# filter for "ww",
		my @forecasts = (
		    map {+{ type => $_->att('dwd:elementName'), values => $_->first_descendant('dwd:value')->text }}
		    map {; $_->descendants('dwd:Forecast') } $place->descendants('kml:ExtendedData') );
		for (@forecasts) {
			$_->{values} = [ map { $_ eq '-' ? undef : $_ } split /\s+/, $_->{values} ];
		};

		my %info = (
		    name        => scalar $place->first_child_text('kml:name'),
		    description => scalar  $place->first_child_text('kml:description'),
		    coordinates => {
				longitude => $long,
				latitude  => $lat,
				elevation => $el,
			},
			forecasts => \@forecasts,
		);

        $place->purge;

        #use Data::Dumper;
        #print Dumper \%info;
    #};
    $twig->purge;
    #$place->flush;
};

package main;
my $r = Weather::MOSMIX::Reader->new();
$r->read_zip( $ARGV[0] );
