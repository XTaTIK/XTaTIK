#!perl

use lib 't';
use Test::More;
use Test::XTaTIK;

diag '#TODO: fix the tests when GeoIP database issue is rectified';
ok 1;
done_testing;
__END__

Test::XTaTIK->load_test_products( _get_test_products() );
ok 1;
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
            price               => '58.99',
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
            price               => '158.99',
        },
        {
            number              => '001-TEST3',
            image               => '',
            title               => 'Test Product 3',
            category            => '[Test Cat 1]',
            group_master        => '',
            group_desc          => '',
            unit                => '',
            description         => 'Test Desc 3',
            tip_description     => '',
            quote_description   => '',
            recommended         => '',
            price               => '1558.99',
        },
        {
            number              => '001-TEST4',
            image               => '',
            title               => 'Test Product 4',
            category            => '[Test Cat 1*::*Test SubCat 1]',
            group_master        => '',
            group_desc          => '',
            unit                => '',
            description         => 'Test Desc 4',
            tip_description     => '',
            quote_description   => '',
            recommended         => '',
            price               => '25458.99',
        },
        {
            number              => '001-TEST5',
            image               => '',
            title               => 'Test Product 5',
            category            => '[Test Cat 1*::*Test SubCat 2]',
            group_master        => '',
            group_desc          => '',
            unit                => '',
            description         => 'Test Desc 5',
            tip_description     => '',
            quote_description   => '',
            recommended         => '',
            price               => '254.00',
        },
        {
            number              => '001-TEST6',
            image               => '',
            title               => 'Test Product 6',
            category            => '[Test Cat 1*::*Test SubCat 2'
                                    . '*::*Test SubSubCat 1]',
            group_master        => '',
            group_desc          => '',
            unit                => '',
            description         => 'Test Desc 6',
            tip_description     => '',
            quote_description   => '',
            recommended         => '',
        },
        {
            number              => '001-TEST7',
            image               => '',
            title               => 'Test Product 7',
            category            => '[Test Cat 1*::*Test SubCat 2'
                                    . '*::*Test SubSubCat 2]',
            group_master        => '',
            group_desc          => '',
            unit                => '',
            description         => 'Test Desc 7',
            tip_description     => '',
            quote_description   => '',
            recommended         => '',
            price               => '88.99',
        },
        {
            number              => '001-TEST8',
            image               => '',
            title               => 'Test Product 8',
            category            => '[Test Cat 1*::*Test SubCat 2'
                                    . '*::*Test SubSubCat 2'
                                    . '*::*Test SubSubSubCat 2]',
            group_master        => '',
            group_desc          => '',
            unit                => '',
            description         => 'Test Desc 8',
            tip_description     => '',
            quote_description   => '',
            recommended         => '',
            price               => '48.99',
        },
        # {
        #     number              => '',
        #     image               => '',
        #     title               => '',
        #     category            => '',
        #     group_master        => '',
        #     group_desc          => '',
        #     unit                => '',
        #     description         => '',
        #     tip_description     => '',
        #     quote_description   => '',
        #     recommended         => '',
        # },
    ];
}