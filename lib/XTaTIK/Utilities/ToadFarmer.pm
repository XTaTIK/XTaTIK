package XTaTIK::Utilities::ToadFarmer;

use Toadfarm -init;
use File::Find::Rule;

sub farm {
    my @sites = grep length, map s'^silo/?''r,
        File::Find::Rule->directory->in('silo');

    for my $site ( @sites ) {
        mount XTaTIK => {
            Host       => qr{^\Q$site\E(:3000)?$},
            local_port => 3000,
            config     => {
                %{ do 'XTaTIK.conf'; },
                %{ do "silo/$site/XTaTIK.conf"; },
                site => $site,
            },
        };
    }

    start;
}
1;