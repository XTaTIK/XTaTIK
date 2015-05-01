package Test::XTaTIK;

use Mojo::Base -base;
use File::Copy;
use Mojo::Pg;
use XTaTIK::Model::Products;

my $secret = do 'secret.txt' or die "Failed to load secret.txt: $! $@";
my $PG_URL = $secret->{pg_url};
my $DB_FILE_NAME = 'NOOP';
my $BACKUP_DB_FILE_NAME = "backup_$DB_FILE_NAME";

sub save_db {
    warn 'save_db is currently a noop';
    return;
    return unless -e $DB_FILE_NAME;
    return if -e 'squash-db';
    move $DB_FILE_NAME, $BACKUP_DB_FILE_NAME
        or die "FAILED TO SAVE products database $DB_FILE_NAME $!";
}

sub restore_db {
    warn 'restore_db is currently a noop';
    return;
    return if -e 'squash-db' or -e 'do-not-restore-db';
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
    $p->_pg( Mojo::Pg->new($PG_URL) );

    $p->_pg->db->query(
        'drop table if exists carts'
    );
    $p->_pg->db->query(
        'drop table if exists products'
    );

    $p->_pg->db->query(
        'CREATE TABLE carts (
            id            SERIAL PRIMARY KEY,
            created_on INT,
            data TEXT
        )'
    );
    $p->_pg->db->query(
        'CREATE TABLE products (
            id            SERIAL PRIMARY KEY,
            url           TEXT,
            number        TEXT,
            image         TEXT,
            title         TEXT,
            category      TEXT,
            group_master  TEXT,
            group_desc    TEXT,
            price         TEXT,
            unit          TEXT,
            description   TEXT,
            tip_description   TEXT,
            quote_description TEXT,
            recommended       TEXT
        );'
    );
    $p->_pg->db->query('DELETE FROM "products"');
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