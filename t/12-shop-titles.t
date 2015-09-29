#!perl

############
# This test performs checks that <title> elements get correctly
# Updated when viewing products and shop categories
############

use Test::Most;

unless ( $ENV{XTATIK_TESTING} ) {
    diag 'Set XTATIK_TESTING env var to true, to run the tests';
    ok 1; done_testing; exit;
}

use Test::Mojo::WithRoles 'ElementCounter';
my $t = Test::Mojo::WithRoles->new('XTaTIK');

use lib 't';
eval 'use Test::XTaTIK';

# Set free shipping above $50
$t->app->config('text')->{shipping_free} = 50;

Test::XTaTIK->load_test_products( _get_test_products() );

{
    $t->dive_reset->get_ok('/products')->status_is(200)
        ->text_like( title => qr{^Shop /} )
        ->text_is(   h2    => 'Shop'      )

        ->get_ok('/products/Test Cat 1')->status_is(200)
        ->text_like( title => qr{^Test Cat 1 /} )
        ->text_is(   h2    => 'Test Cat 1'      )

        ->get_ok('/products/Test Cat 1/Test SubCat 1')->status_is(200)
        ->text_like( title => qr{^Test Cat 1 / Test SubCat 1 /} )
        ->text_is(   h2    => 'Test Cat 1 / Test SubCat 1'      )

        ->get_ok('/products/Test Cat 1/Test SubCat 2')->status_is(200)
        ->text_like( title => qr{^Test Cat 1 / Test SubCat 2 /} )
        ->text_is(   h2    => 'Test Cat 1 / Test SubCat 2'      )

        ->get_ok('/products/Test Cat 1/Test SubCat 2/Test SubSubCat 1')
            ->status_is(200)
        ->text_like( title => qr{^Test SubCat 2 / Test SubSubCat 1 /} )
        ->text_is(   h2    => 'Test SubCat 2 / Test SubSubCat 1'      )

        ->get_ok('/products/Test Cat 1/Test SubCat 2/Test SubSubCat 2')
            ->status_is(200)
        ->text_like( title => qr{^Test SubCat 2 / Test SubSubCat 2 /} )
        ->text_is(   h2    => 'Test SubCat 2 / Test SubSubCat 2'      )

        ->get_ok('/products/Test Cat 1/Test SubCat 2/'
                . 'Test SubSubCat 2/Test SubSubSubCat 2')->status_is(200)
        ->text_like( title => qr{^Test SubSubCat 2 / Test SubSubSubCat 2 /} )
        ->text_is(   h2    => 'Test SubSubCat 2 / Test SubSubSubCat 2'      )
        ;

    # for ( 1 .. 7 ) {
    #     $t->get_ok("/product/Test-Product-$_-001-TEST$_")->status_is(200)
    #         ->text_like( title => qr{^Test Product $_ /} )
    #         ->text_is(   h2    => "Test Product $_"      );
    # }
}

Test::XTaTIK->restore_db;

done_testing();

sub _get_test_products {
    return [
        { category => '[]', },
        { category => '[Test Cat 1]', },
        { category => '[Test Cat 1*::*Test SubCat 1]', },
        { category => '[Test Cat 1*::*Test SubCat 2]', },
        { category => '[Test Cat 1*::*Test SubCat 2'
                                    . '*::*Test SubSubCat 1]', },
        { category => '[Test Cat 1*::*Test SubCat 2'
                                    . '*::*Test SubSubCat 2]', },
        { category => '[Test Cat 1*::*Test SubCat 2'
                                    . '*::*Test SubSubCat 2'
                                    . '*::*Test SubSubSubCat 2]', },
    ];
}
