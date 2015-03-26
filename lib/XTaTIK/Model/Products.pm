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

    # TODO: we'll need good tests for this category matching business,
    # 1) Check that the regex works in common SQL servers
    # 2) Check that weird stuff like same-name cat/subcat combinations
    #       work fine
    my $products = $dbh->selectall_arrayref(
        'SELECT * FROM `products` WHERE `category`
            REGEXP(?)',
        { Slice => {} },
        '\[' . quotemeta($cat_line) . '(\*::\*)?(.(?!\*::\*))*\]',
    ) || [];

    # This would be a nice thing to do with a variable-length
    # look-behind in SQL (or at least in Perl)
    # Let's filter out products from categories that are too high
    # up the chain from where we currently are

    my @cat_bits = map reverse, split /\Q*::*\E/, reverse $category, 3;
    splice @cat_bits, 0, -3;

    my ( $up_cat, $cur_cat, $down_cat ) = map quotemeta, @cat_bits;

    @$products = grep $_->{category} =~ /
    /x, @$products;
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

