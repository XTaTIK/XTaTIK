package XTaTIK::Utilities::ToadFarmer;

use Toadfarm -init;
use File::Find::Rule;
use experimental 'autoderef';

sub farm {
    my @sites = grep length, map s'^silo/?''r,
        File::Find::Rule->directory->maxdepth(1)->in('silo');

    my $main_conf = do 'XTaTIK.conf'
        or die "Failed to load main config file: $@ $!";
    for my $site ( @sites ) {
        my $site_conf = do "silo/$site/XTaTIK.conf"
            or die "Failed to load silo [$site] config file: $@ $!";

        mount XTaTIK => {
            Host       => qr{^\Q$site\E(:3000)?$},
            local_port => 3000,
            config     => {
                _merge_conf( $main_conf, $site_conf ),
                site => $site,
            },
        };
    }

    start;
}

sub _merge_conf {
    my ( $main_conf, $site_conf ) = @_;
    my $conf = { %$main_conf, %$site_conf };

    if ( $site_conf->{text} ) {
        $conf->{text}{$_} = exists $site_conf->{text}{$_}
            ? $site_conf->{text}{$_} : $main_conf->{text}{$_}
                for keys $site_conf->{text}, keys $main_conf->{text};
    }

    return %$conf;
}

1;