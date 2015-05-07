package XTaTIK::Model::Products;

use Mojo::Base -base;
use Mojo::Pg;
use File::Spec::Functions qw/catfile/;
use List::UtilsBy qw/sort_by  extract_by/;
use Scalar::Util qw/blessed/;

has [qw/pg  pricing_region  custom_cat_sorting/];

sub exists {
    my $self    = shift;
    my $number  = shift;
    return $self->get_by_number( $number );
}

sub get_by_number {
    my $self    = shift;
    my @numbers = @_;

    return unless @numbers;

    my $result = $self->pg->db->query(
        'SELECT * FROM "products" WHERE "number" IN (' .
                ( join ',', ('?')x@numbers )
            . ')',
        @numbers,
    )->hashes;

    $result = $self->_process_products( $result );
    return wantarray ? @$result : $result->[0];
}

sub get_by_url {
    my $self = shift;
    my $url  = shift;

    my $product = $self->pg->db->query(
            'SELECT * FROM "products" WHERE "url" = ?',
            $url,
        )->hash;

    return $self->_process_products( $product );
}

sub add {
    my $self = shift;
    my %values = @_;
    my $url = "$values{title} $values{number}" =~ s/\W+/-/gr;

    for ( keys %values ) { length $values{$_} or delete $values{$_} }

    $self->pg->db->query(
        'INSERT INTO "products" ("number", "image", "title",
                "category", "group_master", "group_desc",
                "unit", "description", "tip_description",
                "quote_description", "recommended", "price",
                "onprice", "url")
            VALUES (?, ?, ?,  ?, ?, ?,  ?, ?, ?,  ?, ?, ?, ?, ?)',
        @values{qw/number  image  title  category  group_master
                    group_desc unit description  tip_description  quote_description recommended  price
                        ONprice/},
        $url,
    );

    return 1;
}

sub delete {
    my $self = shift;
    my @to_delete = @_;

    s/^\s+|\s+$//g for @to_delete;

    $self->pg->db->query(
        'DELETE FROM "products" WHERE "number" IN(' .
                (join ',', ('?')x@to_delete )
            .');',
        @to_delete,
    );

    return 1;
}

sub update {
    my $self = shift;
    my $id = shift;
    my %values = @_;
    my $url = "$values{title} $values{number}" =~ s/\W+/-/gr;

    $self->pg->db->query(
        'UPDATE "products"
            SET "number" = ?, "image" = ?, "title" = ?,
                "category" = ?, "group_master" = ?, "group_desc" = ?,
                "unit" = ?, "description" = ?, "tip_description" = ?,
                "quote_description" = ?, "recommended" = ?, "price" = ?,
                "url" = ?

            WHERE "id" = ?',
        @values{qw/number  image  title  category  group_master
                    group_desc unit description  tip_description  quote_description recommended  price/},
        $url,
        $id,
    );

    return 1;
}

sub get_all {
    my $self = shift;

    return $self->_process_products(
        $self->pg->db->query(
            'SELECT * FROM "products" ORDER BY "number"',
        )->hashes
    );
}

sub get_category {
    my $self = shift;
    my $category = shift;

    $category =~ s{^/}{};
    my $cat_line = $category =~ s{/}{*::*}gr;

    my $data = $self->pg->db->query(
        'SELECT * FROM "products" WHERE "category" ~ ?',
        '\[' . quotemeta($cat_line),
    )->hashes;

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

    for my $cat ( sort { $self->_custom_sort } sort keys %cats ) {
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

sub _custom_sort {
    my $self = shift;
    my $counter = 1;
    my %order = map +( $_ => $counter++ ),
        @{ $self->custom_cat_sorting || [] };

    return 0 if ( not $order{$b}
            and not $order{$b}
        ) or not $order{$b};

    return 1 if not $order{$a};
    return $order{$a} <=> $order{$b}
}

sub _process_products {
    my ( $self, $data ) = @_;

    my %units = (
        each    => 'eaches',
        box     => 'boxes',
        pair    => 'pairs',
        case    => 'cases',
        pack    => 'packs',
    );

    for my $product ( blessed($data) ? @$data : $data ) {
        $product->{price}
        = $product->{ lc($self->pricing_region) . 'price' }
        // $product->{price} // 0;

        $product->{contact_for_pricing} = 1
            unless $product->{price} > 0;

        $product->{price} = sprintf '%.2f', $product->{price};
        @$product{qw/price_dollars  price_cents/}
        = split /\./, $product->{price};

        for ( qw/unit  image/ ) {
            length $product->{$_} or delete $product->{$_};
        }
        $product->{unit}     //= 'each';
        my ( $unit_noun ) = $product->{unit} =~ /(\w+)/;
        $product->{unit_multi} = $product->{unit}
        =~ s/\Q$unit_noun\E/$units{ $unit_noun }/gr;

        $product->{image} //= "$product->{number}.jpg";
        $product->{image}   = 'nopic.jpg'
            unless -e catfile 'product-pics', $product->{image};
    }

    return $data;
}

1;

__END__



CREATE TABLE products (
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
);

