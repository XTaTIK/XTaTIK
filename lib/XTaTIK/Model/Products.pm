package XTaTIK::Model::Products;

use Mojo::Base -base;
use DBI;

has _dbh => sub {
    DBI->connect("dbi:SQLite:dbname=XTaTIK.db","","")
};

sub exists {
    my $self    = shift;
    my $number  = shift;

    my $dbh = $self->_dbh;

    return @{
        $dbh->selectall_arrayref(
            'SELECT * FROM `products` WHERE `number` = ?',
            { Slice => {} },
            $number,
        ) || []
    };
}

sub add {
    my $self = shift;
    my %values = @_;
    my $dbh = $self->_dbh;

    $dbh->do(
        'INSERT INTO `products` (`number`, `image`, `title`,
                `category`, `group_master`, `group_desc`,
                `unit`, `description`, `tip_description`,
                `quote_description`, `recommended`)
            VALUES (?, ?, ?,  ?, ?, ?,  ?, ?, ?,  ?, ?)',
        undef,
        @values{qw/number  image  title  category  group_master
                    group_desc unit description  tip_description  quote_description recommended/},
    );

    return 1;
}

sub delete {
    my $self = shift;
    my @to_delete = @_;

    $self->_dbh->do(
        'DELETE FROM `products` WHERE `number` IN(' .
                (join ',', ('?')x@to_delete )
            .');',
        undef,
        @to_delete,
    );

    return 1;
}

sub update {
    my $self = shift;
    my $id = shift;
    my %values = @_;

    $self->_dbh->do(
        'UPDATE `products`
            SET `number` = ?, `image` = ?, `title` = ?,
                `category` = ?, `group_master` = ?, `group_desc` = ?,
                `unit` = ?, `description` = ?, `tip_description` = ?,
                `quote_description` = ?, `recommended` = ?
            WHERE `id` = ?',
        undef,
        @values{qw/number  image  title  category  group_master
                    group_desc unit description  tip_description  quote_description recommended/},
        $id,
    );

    return 1;
}

sub get_all {
    my $self = shift;
    my $dbh = $self->_dbh;

    return $dbh->selectall_arrayref(
        'SELECT * FROM `products` ORDER BY `number`',
        { Slice => {} },
    ) || [];
}

1;

__END__
CREATE TABLE `products` (
    `id`            INTEGER PRIMARY KEY AUTOINCREMENT,
    `number`        TEXT,
    `image`         TEXT,
    `title`         TEXT,
    `category`      TEXT,
    `group_master`  TEXT,
    `group_desc`    TEXT,
    `unit`          TEXT,
    `description`   TEXT,
    `tip_description`   TEXT,
    `quote_description` TEXT,
    `recommended`       TEXT
);

