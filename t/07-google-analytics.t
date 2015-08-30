#!perl

use Test::More;

diag '#TODO: fix the tests when GeoIP database issue is rectified';
ok 1;
done_testing;
__END__

use Test::Mojo::WithRoles 'ElementCounter';
my $t = Test::Mojo::WithRoles->new('XTaTIK');

use lib 't';
use Test::XTaTIK;
use Mojo::DOM;

{
    $t->app->xtext('google_analytics', 0 );

    $t->get_ok('/')
        ->content_unlike(
            qr{GoogleAnalyticsObject},
            'GA code disabled',
        );

    $t->app->xtext('google_analytics', 'UA-00000000-00' );
    $t->get_ok('/products')
        ->content_like(
            qr{\Qga('create', 'UA-00000000-00', 'auto');\E},
            'GA code enabled',
        );
}

done_testing();
