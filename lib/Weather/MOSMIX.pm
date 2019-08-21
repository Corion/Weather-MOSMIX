package Weather::MOSMIX;
use strict;
use Moo 2;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';
use DBI;
use JSON;
use Weather::MOSMIX::Weathercodes 'mosmix_weathercode';

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


sub format_forecast_day {
    my( $self, $ts, $temp, $weathercode, $offset, $count ) = @_;

    my ($min, $max) = (1000,0);
    for my $f (grep { length $_ } @{ $temp->{values} }[$offset..$offset+$count-1]) {
        if( $f < $min ) {
            $min = $f;
        };
        if( $f > $max ) {
            $max = $f;
        };
    };

    $max -= 273.15;
    $min -= 273.15;

    my $weather = [];
    my %forecast = (
        date    => $ts->new(),
        weather => $weather,
        min     => $min,
        max     => $max,
    );

    my $time = $ts->new();
    for my $i ($offset..$offset+$count-1) {
        my $c = $weathercode->{values}->[ $i ];
        if( length $c ) {
            my $v = sprintf '%02d', 0+$c;
            push @{ $weather }, {
                timestamp   => $time->new(),
                description => mosmix_weathercode($v),
            };
            $time += 3600;
        };
    };

    return \%forecast,
};

sub format_forecast {
    my( $self, $f ) = @_;
    my $loc = $f->{description};
    (my $temp) = grep{ $_->{type} eq 'TTT' } @{ $f->{forecasts}};
    (my $weathercode) = grep{ $_->{type} eq 'ww' } @{ $f->{forecasts}};

    my $time = Time::Piece->strptime( $f->{issuetime}, '%Y-%m-%dT%H:%M:%SZ' );

    # Find where today ends, and add a linebreak, resp. move to the next array ...
    my @forecasts;
    my %weather = (
        #today    => $weath,
        #tomorrow => [],
        #tomnext  => [],
        days     => \@forecasts,
    );
    my %sequence = (
        today    => 'tomorrow',
        tomorrow => 'tomnext',
    );

    my $offset = 0;
    my $count = 0;
    my $today = $time->truncate(to => 'day');
    my $start = $time->new();
    my $slot = 'today';

    while( $offset < @{$weathercode->{values}} ) {
        $time += 3600;
        $count++;
        if( $time->truncate( to => 'day' ) != $today ) {
            push @forecasts, $self->format_forecast_day( $start, $temp, $weathercode, $offset, $count );
            $offset += $count;
            $count = 0;
            if( defined $slot ) {
                #print "$slot ($today) -> $sequence{ $slot } ($time)\n";
                $slot = $sequence{ $slot };
            };
            $today = $time->truncate( to => 'day' );
            $start = $today;
        };
    };

    $weather{ today }    = $forecasts[0];
    $weather{ tomorrow } = $forecasts[1];
    $weather{ tomnext }  = $forecasts[2];

    return {
        issuetime => $f->{issuetime},
        location  => $loc,
        weather   => \%weather,
    }
}

sub formatted_forecast( $self, %options ) {
    my $f = $self->forecast( %options );
    $self->format_forecast( $f )
}

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
