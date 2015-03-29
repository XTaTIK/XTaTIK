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

sub get_category {
    my $self = shift;
    my $category = shift;
    my $dbh = $self->_dbh;

    $category =~ s{^/}{};
    my $cat_line = $category =~ s{/}{*::*}gr;

    my $is_deep = (() = $cat_line =~ /\Q*::*\E/g) > 1 ? 1 : 0;
    my @cat_bits = split /\Q*::*\E/, $cat_line;
    splice @cat_bits, -2;
    my $unwanted_cat = join '*::*', @cat_bits;

    # TODO: we'll need good tests for this category matching business,
    # 1) Check that the regex works in common SQL servers
    # 2) Check that weird stuff like same-name cat/subcat combinations
    #       work fine
    my $products = $dbh->selectall_arrayref(
        'SELECT * FROM `products` WHERE `category`
            REGEXP(?)'
            . ($is_deep ? 'AND NOT REGEXP(?)' : ''),
        { Slice => {} },
        '\[' . quotemeta($cat_line) . '(\*::\*)?(.(?!\*::\*))*\]',
        (
            $is_deep ? ( '\[' . quotemeta($unwanted_cat) ) : ()
        ),
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

