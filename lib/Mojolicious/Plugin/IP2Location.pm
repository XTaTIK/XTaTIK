package Mojolicious::Plugin::IP2Location;

# VERSION

use Mojo::Base 'Mojolicious::Plugin';
# TODO: use IP2Location reader from CPAN
use lib 'ip2location/ip2location-perl-7.0.0/lib';
use Geo::IP2Location;

my $IP_DB_LOCATION = 'ip2location/IP2LOCATION-LITE-DB3.BIN';

my %Province_Map = (
    'Alberta'                   => 'AB',
    'British Columbia'          => 'BC',
    'Manitoba'                  => 'MB',
    'New Brunswick'             => 'NB',
    'Newfoundland and Labrador' => 'NL',
    'Northwest Territories'     => 'NT',
    'Nova Scotia'               => 'NS',
    'Nunavut'                   => 'NU',
    'Ontario'                   => 'ON',
    'Prince Edward Island'      => 'PE',
    'Quebec'                    => 'QC',
    'Saskatchewan'              => 'SK',
    'Yukon Territory'           => 'YT',
);

sub register {
    my ($self, $app) = @_;

    state $geo_ip = Geo::IP2Location->open( $IP_DB_LOCATION );

    $app->helper(
        geoip_region=> sub {
            my $c = shift;

            my $is_debug_ip
            = $c->app->mode eq 'development' && $c->param('DEBUG_GEOIP');

            return $c->session('gip_r')
                if not $is_debug_ip and length $c->session('gip_r');

            my $ip = $is_debug_ip
                ? $c->param('DEBUG_GEOIP') : $c->tx->remote_address;

            $c->session(
                gip_r => $Province_Map{ $geo_ip->get_region( $ip ) } // '00'
            );
            return $c->session('gip_r');
        },
    );
}

1;