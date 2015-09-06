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

Test::XTaTIK->load_test_products( _get_test_products() );

{
    $t->get_ok("/search?term=Test")
        ->dive_in('#product_list ')
        ->element_count_is('> li', 2, 'We have two search results')
        ->dived_text_is('li:first-child a + a' => 'Test Product 1')
        ->dived_text_is('li:first-child + li a + a' => 'Test Product 2');

    $t->get_ok("/search?term=001-TEST2")
        ->dive_reset
        ->dive_in('#product_list ')
        ->element_count_is(' li', 1, 'We have only one search result')
        ->dived_text_is('li:first-child a + a' => 'Test Product 2');
}

Test::XTaTIK->restore_db;

done_testing();

sub _get_test_products {
    return [
        {
            number              => '001-TEST1',
            image               => '',
            title               => 'Test Product 1',
            category            => '[]',
            group_master        => '',
            group_desc          => '',
            unit                => 'box of 50',
            description         => 'Test Desc 1',
            tip_description     => '',
            quote_description   => '',
            recommended         => '',
            price               => '{"default":{"00":58.99}}',
        },
        {
            number              => '001-TEST2',
            image               => '',
            title               => 'Test Product 2',
            category            => '[Test Cat 1]',
            group_master        => '',
            group_desc          => '',
            unit                => 'case of 100',
            description         => 'Test Desc 2',
            tip_description     => '',
            quote_description   => '',
            recommended         => '',
            price               => '{"default":{"00":158.99}}',
        },
    ];
}