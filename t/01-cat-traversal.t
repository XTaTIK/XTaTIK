#!perl

use Test::More;
use Test::Mojo;

use lib 't';
use Test::XTaTIK;

my $t = Test::Mojo->new('XTaTIK');

Test::XTaTIK->load_test_products;

{
    $t->get_ok('/products')->status_is(200);
        # ->text_is('div#message' => 'Hello!');

}

done_testing();