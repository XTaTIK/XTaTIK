#!perl

use Test::More;

use Test::Mojo::WithRoles 'ElementCounter';
my $t = Test::Mojo::WithRoles->new('XTaTIK');

use lib 't';
use Test::XTaTIK;

Test::XTaTIK->load_test_products;

my $pi = '#product_list > li';
my $fli = "$pi:first-child ";
my $ap = q{a[href^="/product/"]};
my $ac = q{a[href^="/products/"]};

{
    my $sfli = "$fli + li > ul > li:first-child ";
    $t->get_ok('/products')->status_is(200)
    ->dive_in('#product_list > li')
    ->element_count_is('', '<3')
    ->element_count_is(" > $ap",  1)
    ->element_count_is(" > $ac", 1)
    ->dive_in(' > ul > li')
    ->element_count_is('', 4)
    ->element_count_is(" > $ap", 2)
    ->element_count_is(" > $ac", 2)
    ->dive_reset
    ->text_is("$fli > a"      => 'Test Product 1')
    ->text_is("$fli + li > a" => 'Test Cat 1'    )
    ->text_is("$sfli > a"                => 'Test Product 2')
    ->text_is("$sfli + li > a"           => 'Test Product 3')
    ->text_is("$sfli + li + li > a"      => 'Test SubCat 1' )
    ->text_is("$sfli + li + li + li > a" => 'Test SubCat 2' )

    ->element_count_is(
        '#product_list a[href="/product/Test-Product-1-001-TEST1"]',  1)
    ->element_count_is(
        '#product_list a[href="/product/Test-Product-2-001-TEST2"]',  1)
    ->element_count_is(
        '#product_list a[href="/product/Test-Product-3-001-TEST3"]',  1)

    ->element_exists_not('#back_up_category')
}

{
    my $sfli = "$fli + li + li + li > ul > li:first-child ";
    $t->get_ok('/products/Test Cat 1')->status_is(200)
    ->element_count_is($pi, 4)
    ->element_count_is("$pi > $ap", 2)
    ->element_count_is("$pi > $ac", 2)
    ->element_count_is("$fli + li + li > ul > li", 1)
    ->element_count_is("$fli + li + li > ul $ap", 1)
    ->element_count_is("$fli + li + li + li > ul > li", 3)
    ->element_count_is("$fli + li + li + li > ul $ap", 1)
    ->element_count_is("$fli + li + li + li > ul $ac", 2)

    ->text_is("$fli > a"      => 'Test Product 2')
    ->text_is("$fli + li > a" => 'Test Product 3')
    ->text_is("$fli + li + li > a" => 'Test SubCat 1')
    ->text_is("$fli + li + li > ul > li > a" => 'Test Product 4')

    ->text_is("$fli + li + li + li > a" => 'Test SubCat 2')
    ->text_is("$sfli > a" => 'Test Product 5')
    ->text_is("$sfli + li > a" => 'Test SubSubCat 1')
    ->text_is("$sfli + li + li > a" => 'Test SubSubCat 2')

    ->element_count_is(
        '#product_list a[href="/product/Test-Product-2-001-TEST2"]',  1)
    ->element_count_is(
        '#product_list a[href="/product/Test-Product-3-001-TEST3"]',  1)
    ->element_count_is(
        '#product_list a[href="/product/Test-Product-4-001-TEST4"]',  1)
    ->element_count_is(
        '#product_list a[href="/product/Test-Product-5-001-TEST5"]',  1)

    ->element_exists('#back_up_category a[href="/products"]')
    ->text_is('#back_up_category a' => 'Back to category list')
}

{
    $t->get_ok('/products/Test Cat 1/Test SubCat 1')->status_is(200)
    ->element_count_is('#product_list li', 1)
    ->element_count_is('#product_list a',  1)
    ->element_count_is($pi, 1)
    ->element_count_is("$pi $ap", 1)
    ->element_count_is("$pi $ac", 0)
    ->text_is("#product_list a" => 'Test Product 4')
    ->element_count_is(
        '#product_list a[href="/product/Test-Product-4-001-TEST4"]',  1)

    ->element_exists('#back_up_category a[href="/products/Test Cat 1"]')
    ->text_is('#back_up_category a' => 'Back to Test Cat 1')
}

{
    my $sfli = "$fli + li + li > ul > li:first-child ";
    $t->get_ok('/products/Test Cat 1/Test SubCat 2')->status_is(200)
    ->element_count_is('#product_list li', 6)
    ->element_count_is('#product_list a',  6)
    ->element_count_is('#product_list ul', 2)
    ->element_count_is($pi, 3)
    ->element_count_is("$pi > $ap", 1)
    ->element_count_is("$pi > $ac", 2)
    ->element_count_is("$fli > $ap", 1)
    ->element_count_is("$fli + li > $ac", 1)
    ->element_count_is("$fli + li > ul > li > $ap", 1)
    ->element_count_is("$fli + li + li > $ac", 1)
    ->element_count_is("$sfli > $ap", 1)
    ->element_count_is("$sfli + li > $ac", 1)

    ->text_is("$fli > a" => 'Test Product 5')
    ->text_is("$fli + li > a" => 'Test SubSubCat 1')
    ->text_is("$fli + li > ul > li > a" => 'Test Product 6')
    ->text_is("$fli + li + li > a" => 'Test SubSubCat 2')
    ->text_is("$sfli > a" => 'Test Product 7')
    ->text_is("$sfli + li > a" => 'Test SubSubSubCat 2')

    ->element_count_is(
        '#product_list a[href="/product/Test-Product-5-001-TEST5"]',  1)
    ->element_count_is(
        '#product_list a[href="/product/Test-Product-6-001-TEST6"]',  1)
    ->element_count_is(
        '#product_list a[href="/product/Test-Product-7-001-TEST7"]',  1)
}

{
    $t->get_ok('/products/Test Cat 1/Test SubCat 2/Test SubSubCat 1')
    ->status_is(200)
    ->element_count_is('#product_list li', 1)
    ->element_count_is('#product_list a',  1)
    ->element_count_is($pi, 1)
    ->element_count_is("$pi $ap", 1)
    ->element_count_is("$pi $ac", 0)
    ->text_is("#product_list a" => 'Test Product 6')
    ->element_count_is(
        '#product_list a[href="/product/Test-Product-6-001-TEST6"]',  1)

    ->element_exists('#back_up_category a[href="/products/'
            . 'Test Cat 1/Test SubCat 2"]')
    ->text_is('#back_up_category a' => 'Back to Test SubCat 2')
}

{
    $t->get_ok('/products/Test Cat 1/Test SubCat 2/Test SubSubCat 2')
    ->status_is(200)
    ->element_count_is('#product_list li', 3)
    ->element_count_is('#product_list a',  3)
    ->element_count_is($pi, 2)
    ->element_count_is("$pi $ap", 2)
    ->element_count_is("$pi > $ap", 1)
    ->element_count_is("$pi $ac", 1)
    ->text_is("$fli > a" => 'Test Product 7')
    ->text_is("$fli + li > a" => 'Test SubSubSubCat 2')
    ->text_is("$fli + li > ul > li > a" => 'Test Product 8')

    ->element_count_is(
        '#product_list a[href="/product/Test-Product-7-001-TEST7"]',  1)
    ->element_count_is(
        '#product_list a[href="/product/Test-Product-8-001-TEST8"]',  1)
}

{
    $t->get_ok('/products/Test Cat 1/Test SubCat 2/'
        . 'Test SubSubCat 2/Test SubSubSubCat 2')
    ->status_is(200)
    ->element_count_is('#product_list li', 1)
    ->element_count_is('#product_list a',  1)
    ->element_count_is($pi, 1)
    ->element_count_is("$pi $ap", 1)
    ->element_count_is("$pi $ac", 0)
    ->text_is("#product_list a" => 'Test Product 8')
    ->element_count_is(
        '#product_list a[href="/product/Test-Product-8-001-TEST8"]',  1)
}

Test::XTaTIK->restore_db;

done_testing();
