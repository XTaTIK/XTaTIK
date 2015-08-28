package XTaTIK::Utilities::Misc;

use strict;
use warnings;

# VERSION

use experimental 'autoderef';
use Exporter::Easy  OK => [qw/merge_conf/];

sub merge_conf {
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