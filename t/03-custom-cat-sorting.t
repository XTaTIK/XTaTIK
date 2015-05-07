#!perl

use Test::More;

use Test::Mojo::WithRoles 'ElementCounter';
my $t = Test::Mojo::WithRoles->new('XTaTIK');

use lib 't';
use Test::XTaTIK;

Test::XTaTIK->load_test_products( _get_test_products() );

$t->app->config(
    custom_cat_sorting => [
        'Cat4',
        'Cat3',
        'Cat3*::*SubCat3',
        'Cat3*::*SubCat3*::*SubSubCat5',
        'Cat3*::*SubCat3*::*SubSubCat4',
        'Cat3*::*SubCat3*::*SubSubCat3',
        'Cat1',
        'Cat2*::*Cat2',
        'Cat2*::*Cat4',
        'Cat2*::*Cat1',
    ],
);

{
    $t->get_ok('/products')
        ->dive_reset
        ->dive_in('#product_list > li')
        ->element_count_is('', 5)
        ->dived_text_is(':first-child > a' => 'Cat4' )
        ->dived_text_is(':first-child + li > a' => 'Cat3' )
        ->dived_text_is(':first-child + li + li > a' => 'Cat1' )
        ->dived_text_is(':first-child + li + li + li > a' => 'Cat2' )
        ->dived_text_is(':first-child + li + li + li + li > a' => 'Cat5' )

        ->dive_reset
        ->dive_in('#product_list > li:first-child + li ') # Cat3
        ->element_count_is(' li a[href^="/products/"]', 5)
        ->dive_in(' li:first-child ')
        ->dived_text_is(' a' => 'Product 001-TEST3' )
        ->dived_text_is(' + li > a' => 'SubCat3' )
        ->dived_text_is(' + li + li > a' => 'SubCat1' )
        ->dived_text_is(' + li + li + li > a' => 'SubCat2' )
        ->dived_text_is(' + li + li + li + li > a' => 'SubCat4' )
        ->dived_text_is(' + li + li + li + li + li > a' => 'SubCat5' )

        ->dive_reset
        ->dive_in('#product_list > li:first-child + li + li + li') # Cat2
        ->element_count_is(' li a[href^="/products/"]', 5)
        ->dive_in(' li:first-child ')
        ->dived_text_is(' a' => 'Product 001-TEST2' )
        ->dived_text_is(' + li > a' => 'Cat2' )
        ->dived_text_is(' + li + li > a' => 'Cat4' )
        ->dived_text_is(' + li + li + li > a' => 'Cat1' )
        ->dived_text_is(' + li + li + li + li > a' => 'Cat3' )
        ->dived_text_is(' + li + li + li + li + li > a' => 'Cat5' );
}

{
    $t->get_ok('/products/Cat3/SubCat3')
        ->dive_reset
        ->dive_in('#product_list > li')
        ->element_count_is('', 6) # 5 cats + 1 product
        ->dive_in(':first-child + li ')
        ->dived_text_is('> a' => 'SubSubCat5')
        ->dived_text_is('+ li > a' => 'SubSubCat4')
        ->dived_text_is('+ li + li > a' => 'SubSubCat3')
        ->dived_text_is('+ li + li + li > a' => 'SubSubCat1')
        ->dived_text_is('+ li + li + li + li > a' => 'SubSubCat2');

}

Test::XTaTIK->restore_db;

done_testing();

sub _get_test_products {
    return [
        ( map +( { category => "[Cat$_]",                    }, ), 1..5,  ),
        ( map +( { category => "[Cat2*::*Cat$_]",            }, ), 1..5,  ),
        ( map +( { category => "[Cat3*::*SubCat$_]",         }, ), 1..5,  ),
        ( map +( { category => "[Cat3*::*SubCat3*::*SubSubCat$_]", }, ),
            1..5, ),
    ];
}
