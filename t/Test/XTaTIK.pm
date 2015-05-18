package Test::XTaTIK;

use Mojo::Base -base;
use Carp;
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
    my ( $self, $products_to_load ) = @_;
    $products_to_load
        or croak 'Must provide test products';

    for my $idx ( 0..$#$products_to_load ) {
        my $p = $products_to_load->[$idx];
        $p = {
            number              => '001-TEST' . ($idx+1),
            image               => '',
            category            => '[]',
            group_master        => '',
            group_desc          => '',
            unit                => '',
            description         => '',
            tip_description     => '',
            quote_description   => '',
            recommended         => '',
            price               => '',

            %$p,
        },

        $p->{title} //= 'Product ' . $p->{number};
        $products_to_load->[$idx] = $p;
    }

    my $p = XTaTIK::Model::Products->new;
    save_db();
    $p->pg( Mojo::Pg->new($PG_URL) );

    $p->pg->db->query(
        'drop table if exists carts'
    );
    $p->pg->db->query(
        'drop table if exists products'
    );

    $p->pg->db->query(
        'CREATE TABLE carts (
            id            SERIAL PRIMARY KEY,
            created_on INT,
            data TEXT
        )'
    );
    $p->pg->db->query(
        'CREATE TABLE users (
            id      SERIAL PRIMARY KEY,
            login   TEXT,
            pass    TEXT,
            salt    TEXT,
            name    TEXT,
            email   TEXT,
            phone   TEXT,
            roles   TEXT
        )'
    );
    $p->pg->db->query(
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
            onprice       TEXT,
            unit          TEXT,
            description   TEXT,
            tip_description   TEXT,
            quote_description TEXT,
            recommended       TEXT
        );'
    );
    $p->pg->db->query('DELETE FROM "products"');
    $p->add( %$_ ) for @$products_to_load;
}


1;