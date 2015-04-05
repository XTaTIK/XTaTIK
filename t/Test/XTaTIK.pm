package Test::XTaTIK;

use Mojo::Base -base;
use File::Copy;
use XTaTIK::Model::Products;

my $DB_FILE_NAME = 'XTaTIK.db';
my $BACKUP_DB_FILE_NAME = "backup_$DB_FILE_NAME";

sub save_db {
    return unless -e $DB_FILE_NAME;
    return if -e 'squash-db';
    move $DB_FILE_NAME, $BACKUP_DB_FILE_NAME
        or die "FAILED TO SAVE products database $DB_FILE_NAME $!";
}

sub restore_db {
    return if -e 'squash-db';
    unless ( -e $BACKUP_DB_FILE_NAME ) {
        warn "We did not find backup products database. Aborting restore";
        return;
    }

    unlink $DB_FILE_NAME;
    move $BACKUP_DB_FILE_NAME, $DB_FILE_NAME
        or die "Failed to move products database backup file: $!";
}

sub load_test_products {
    my $p = XTaTIK::Model::Products->new;

    save_db();
    $p->_dbh->do('DELETE FROM `products`');
    $p->add( %$_ ) for __get_test_products();
}

sub __get_test_products {
    return (
        {
            number              => '001-TEST1',
            image               => '',
            title               => 'Test Product 1',
            category            => '[]',
            group_master        => '',
            group_desc          => '',
            unit                => '',
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
            unit                => '',
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
    );
}

1;