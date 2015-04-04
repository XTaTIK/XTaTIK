package XTaTIK::Model::Products;

use Mojo::Base -base;
use DBI;
use List::UtilsBy qw/sort_by/;

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

    # We'll get rid of any cats that are too high above of where we are
    my $is_deep = (() = $cat_line =~ /\Q*::*\E/g) > 1 ? 1 : 0;
    my @cat_bits = split /\Q*::*\E/, $cat_line;
    splice @cat_bits, -2 if @cat_bits > 2;
    my $unwanted_cat = join '*::*', @cat_bits;

    # TODO: we'll need good tests for this category matching business,
    # 1) Check that the regex works in common SQL servers
    # 2) Check that weird stuff like same-name cat/subcat combinations
    #       work fine
    my $data = $dbh->selectall_arrayref(
        'SELECT * FROM `products` WHERE `category`
            REGEXP(?)'
            . ($is_deep ? 'AND NOT REGEXP(?)' : ''),
        { Slice => {} },
        '\[' . quotemeta($cat_line),
        (
            $is_deep ? ( '\[' . quotemeta($unwanted_cat) ) : ()
        ),
    ) || [];

    # Right now we might have products that should not show up, since
    # they are deeper than where we are right now. We need to
    # get just cat names that lead to them and we'll only show them
    # at the current level

    # We basically have 3 cases:
    #   1) Products at current level
    #   2) Products in 1 category below that we're listing under
    #       subcat headers
    #   3) Products in >1 category below and we'll just
    #       show subcats for them

    my $current_level_re = qr/\Q[$cat_line]\E/;

    # we have a special case of being at the top-most of the chain
    # solve it like this for now:
    my $top_most_sep = length $cat_line ? '\*::\*' : '';

    my $one_below_re     = qr/
        \Q[$cat_line\E      # our current location in the chain
        $top_most_sep       # separator for a subcat
        ((?:.(?!\*::\*))*?) # ensure there are no more cat separators
                            # ... but test only until the closing category
                            # ... block, since we can have multiple category
                            # ... blocks past our current point
        \]                  # end of current category block
    /x;
    my $sub_only_re      = qr/
        \Q[$cat_line\E      # our current location in the chain
        $top_most_sep
        (.*?)\*::\*         # we check we have more than one separator
                            # ... which means there's more than one subcat
                            # ... below us in this category block
    /x;

    my %subs;
    for ( @$data ) {
        say "\n\nCurrent category: $_->{category}";
        if ( $_->{category} =~ /$current_level_re/ ) {
            $_->{no_sub} = 1;
            say "\tcurrent_level";
            next;
        }
        elsif ( $_->{category} =~ /$one_below_re/ ) {
            $subs{ $1 }++;
            $_->{sub} = $1;
            say "\tone below";
        }
        elsif ( $_->{category} =~ /$sub_only_re/ ) {
            $subs{ $1 }++;
            say "\tsub only";
        }
    }

    return [
        map +{
            cat_name    => $_,
            cat_url     => ( length $category ? "$category/$_" : $_ ),
        }, sort keys %subs
    ];
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

