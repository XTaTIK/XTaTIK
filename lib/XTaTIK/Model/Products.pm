package XTaTIK::Model::Products;

use Mojo::Base -base;
use DBI;
use List::UtilsBy qw/sort_by  extract_by/;

has '_dbh';

sub exists {
    my $self    = shift;
    my $number  = shift;
    return $self->get_by_number( $number )->[0];
}

sub get_by_number {
    my $self    = shift;
    my @numbers = @_;

    my $dbh = $self->_dbh;

    my $result = $dbh->selectall_arrayref(
        'SELECT * FROM `products` WHERE `number` IN (' .
                ( join ',', ('?')x@numbers )
            . ')',
        { Slice => {} },
        @numbers,
    ) || [];

    return wantarray ? $result->[0] : $result;
}

sub get_by_url {
    my $self = shift;
    my $url  = shift;

    my $dbh = $self->_dbh;

    my ( $product ) = @{
        $dbh->selectall_arrayref(
            'SELECT * FROM `products` WHERE `url` = ?',
            { Slice => {} },
            $url,
        ) || []
    };

    return __process_products( $product );
}

sub add {
    my $self = shift;
    my %values = @_;
    my $dbh = $self->_dbh;
    my $url = "$values{title} $values{number}" =~ s/\W+/-/gr;

    for ( keys %values ) { length $values{$_} or delete $values{$_} }

    $dbh->do(
        'INSERT INTO `products` (`number`, `image`, `title`,
                `category`, `group_master`, `group_desc`,
                `unit`, `description`, `tip_description`,
                `quote_description`, `recommended`, `price`, `url`)
            VALUES (?, ?, ?,  ?, ?, ?,  ?, ?, ?,  ?, ?, ?, ?)',
        undef,
        @values{qw/number  image  title  category  group_master
                    group_desc unit description  tip_description  quote_description recommended  price/},
        $url,
    );

    return 1;
}

sub delete {
    my $self = shift;
    my @to_delete = @_;

    s/^\s+|\s+$//g for @to_delete;

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
    my $url = "$values{title} $values{number}" =~ s/\W+/-/gr;

    $self->_dbh->do(
        'UPDATE `products`
            SET `number` = ?, `image` = ?, `title` = ?,
                `category` = ?, `group_master` = ?, `group_desc` = ?,
                `unit` = ?, `description` = ?, `tip_description` = ?,
                `quote_description` = ?, `recommended` = ?, `price` = ?
                `url` = ?

            WHERE `id` = ?',
        undef,
        @values{qw/number  image  title  category  group_master
                    group_desc unit description  tip_description  quote_description recommended  price/},
        $url,
        $id,
    );

    return 1;
}

sub get_all {
    my $self = shift;
    my $dbh = $self->_dbh;

    return __process_products(
        $dbh->selectall_arrayref(
            'SELECT * FROM `products` ORDER BY `number`',
            { Slice => {} },
        ) || []
    );
}

sub get_category {
    my $self = shift;
    my $category = shift;
    my $dbh = $self->_dbh;

    $category =~ s{^/}{};
    my $cat_line = $category =~ s{/}{*::*}gr;

    my $data = $dbh->selectall_arrayref(
        'SELECT * FROM `products` WHERE `category` REGEXP(?)',
        { Slice => {} },
        '\[' . quotemeta($cat_line),
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

    my @cat_bits = split /\Q*::*\E/, $cat_line;
    splice @cat_bits, -2 if @cat_bits > 2;
    my $unwanted_cat = join '*::*', @cat_bits;

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
        ( # grab both, sub cat and sub-sub cat
            (?:.*?)\*::\*
            .*?
        )(?:\*::\*|\])      # we check we have more than one separator
                            # ... which means there's more than one subcat
                            # ... below us in this category block
    /x;

    my %cats;
    for ( @$data ) {
        if ( $_->{category} =~ /$current_level_re/ ) {
            $_->{display_product} = 1;
        }
        elsif ( $_->{category} =~ /$one_below_re/ ) {
            $_->{display_sub_cat} = $1;
            $cats{ $1 }++;
        }
        elsif ( $_->{category} =~ /$sub_only_re/ ) {
            $_->{display_sub_only} = $1;
        }
    }

    my @return = sort_by { $_->{title} }
        extract_by { $_->{display_product} } @$data;

    for my $cat ( sort keys %cats ) {
        push @return, {
            is_subcat => 1,
            title     => $cat,
            cat_url     => (
                length $category ? "$category/$cat" : $cat
            ),
            contents  => [
                extract_by {
                    ($_->{display_sub_cat}//'') eq $cat
                    or ($_->{display_sub_only}//'') =~ /^\Q$cat\E/
                } @$data
            ],
        }
    }

    for my $c ( @return ) {
        $c->{contents} or next;

        my %sub_cats;
        $sub_cats{ (split /\Q*::*\E/, $_->{display_sub_only})[1] }++
            for extract_by { $_->{display_sub_only} } @{ $c->{contents} };

        push @{ $c->{contents} }, map +{
            title => $_,
            cat_url => "$c->{cat_url}/$_",
            is_subsub_cat => 1,
        }, sort keys %sub_cats;
    }

    my ( $return_path, $return_name );
    if ( length $category ) {
        $return_path = $category =~ s{(^|/)[^/]+$}{}r;
        $return_name = (split '/', $return_path)[-1];
    }

    $category =~ s{(^|/)[^/]+}{};

    return ( \@return, $return_path, $return_name );
}

sub __process_products {
    my $data = shift;

    my %units = (
        each    => 'eaches',
        box     => 'boxes',
        pair    => 'pairs',
        case    => 'cases',
        pack    => 'packs',
    );

    for my $product ( ref $data eq 'ARRAY' ? @$data : $data ) {
        $product->{price} = sprintf '%.2f', $product->{price};
        @$product{qw/price_dollars  price_cents/}
        = split /\./, $product->{price};

        for ( qw/unit  image/ ) {
            length $product->{$_} or delete $product->{$_};
        }

        $product->{unit}  //= 'each';
        $product->{image} //= "$product->{number}.jpg";
        $product->{unit_multi} = $units{ $product->{unit} };
    }

    return $data;
}

1;

__END__
CREATE TABLE `products` (
    `url`           TEXT,
    `number`        TEXT,
    `image`         TEXT,
    `title`         TEXT,
    `category`      TEXT,
    `group_master`  TEXT,
    `group_desc`    TEXT,
    `price`         TEXT,
    `unit`          TEXT,
    `description`   TEXT,
    `tip_description`   TEXT,
    `quote_description` TEXT,
    `recommended`       TEXT
);

