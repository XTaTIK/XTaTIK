package XTaTIK::Model::Products;

# VERSION

use Mojo::Base -base;
use Mojo::Pg;
use List::AllUtils qw/uniq/;
use List::UtilsBy qw/sort_by  extract_by/;
use Scalar::Util qw/blessed/;

has [qw/pg  pricing_region  custom_cat_sorting  site/];

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
        'SELECT * FROM "products" WHERE sites ~ ? AND "number" IN (' .
                ( join ',', ('?')x@numbers )
            . ')',
        '(^|,)' . quotemeta($self->site) . '(,|$)',
        @numbers,
    )->hashes;

    $result = $self->_process_products( $result );
    return wantarray ? @$result : $result->[0];
}

sub get_by_id {
    my $self = shift;
    my @ids = @_;

    return unless @ids;

    my $result = $self->pg->db->query(
        'SELECT * FROM products WHERE sites ~ ? AND id IN (' .
                ( join ',', ('?')x@ids )
            . ')',
        '(^|,)' . quotemeta($self->site) . '(,|$)',
        @ids,
    )->hashes;

    $result = $self->_process_products( $result );
    return wantarray ? @$result : $result->[0];
}

sub get_by_url {
    my $self = shift;
    my $url  = shift;

    my $product = $self->pg->db->query(
            'SELECT * FROM "products" WHERE sites ~ ? AND "url" = ?',
            '(^|,)' . quotemeta($self->site) . '(,|$)',
            $url,
        )->hash;

    return $self->_process_products( $product );
}

sub add {
    my $self = shift;
    my %values = @_;
    my $url = "$values{title} $values{number}" =~ s/\W+/-/gr;

    for ( keys %values ) { length $values{$_} or delete $values{$_} }

    $values{sites} //= 'default';

    return $self->pg->db->query(
        'INSERT INTO "products" ("number", "image", "title",
                "category", "group_master", "group_desc",
                "unit", "description", "sites", "tip_description",
                "quote_description", "recommended", "price",
                "onprice", "url")
            VALUES (?, ?, ?,  ?, ?, ?,  ?, ?, ?,  ?, ?, ?, ?,  ?, ?)
                RETURNING id',
        @values{qw/number  image  title  category  group_master
                    group_desc unit description  sites  tip_description  quote_description recommended  price
                        ONprice/},
        $url,
    )->hash->{id};
}

sub delete {
    my $self = shift;
    my @to_delete = @_;

    s/^\s+|\s+$//g for @to_delete;

    return $self->pg->db->query(
        'DELETE FROM "products" WHERE "number" IN(' .
                (join ',', ('?')x@to_delete )
            .') RETURNING id',
        @to_delete,
    )->hashes->map(sub { $_->{id} });
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
    my $site = shift;

    return $self->_process_products(
        $self->pg->db->query(
            $site eq '*' ? 'SELECT * FROM "products" ORDER BY "number"'
            : (
               'SELECT * FROM "products" WHERE sites ~ ? ORDER BY "number"',
               '(^|,)' . quotemeta($self->site) . '(,|$)',
            )
        )->hashes
    );
}

sub get_category {
    my $self = shift;
    my $category = shift;

    $category =~ s{^/}{};
    my $cat_line = $category =~ s{/}{*::*}gr;

    my $data = $self->pg->db->query(
        'SELECT * FROM "products" WHERE sites ~ ? AND "category" ~ ?',
        '(^|,)' . quotemeta($self->site) . '(,|$)',
        '\[' . quotemeta($cat_line),
    )->hashes;

    $data = $self->_process_products($data);

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

    for my $cat ( sort { $self->_custom_sort($cat_line) }
        sort keys %cats
    ) {
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
        }, sort { $self->_custom_sort($cat_line, 'sub', $c->{title}) }
            sort keys %sub_cats;
    }

    my ( $return_path, $return_name );
    if ( length $category ) {
        $return_path = $category =~ s{(^|/)[^/]+$}{}r;
        $return_name = (split '/', $return_path)[-1];
    }

    $category =~ s{(^|/)[^/]+}{};

    my @top_no_cat = extract_by { $_->{display_product} } @return;

    unshift @return, {
        contents    => \@top_no_cat,
        'is_subcat' => 1,
        no_cat => 1,
    };

    return ( \@return, $return_path, $return_name );
}

sub _custom_sort {
    my ( $self, $cat_line, $is_subcat, $subcat ) = @_;

    # TODO: refactor this mess
    my @cats;
    if ( $is_subcat ) {
        my $top_bit = length $cat_line ? $cat_line . '*::*' : '';
        @cats = grep /^\Q$top_bit$subcat\E/,
            @{ $self->custom_cat_sorting || [] };
        s/^\Q$top_bit$subcat\E(?:\Q*::*\E)?// for @cats;
    }
    else {
        my $strip_line = $cat_line;
        $cat_line =~ s/\Q*::*\E(?!\Q*::*\E).*//;
        @cats = grep /^\Q$cat_line\E/, @{ $self->custom_cat_sorting || [] };
        s/^\Q$strip_line\E(?:\Q*::*\E)?// for @cats;
    }

    @cats = grep length, uniq @cats;

    my $counter = 1;
    my %order = map +( $_ => $counter++ ), @cats;

    return 0 if ( not $order{$b}
            and not $order{$b}
        ) or not $order{$b};

    return 1 if not $order{$a};
    return $order{$a} <=> $order{$b}
}

sub unset_site {
    my ( $self, $site, $products ) = @_;
    return unless length $site;

    $self->pg->db->query(
        q{UPDATE products SET sites = regexp_replace(sites, ?, '', 'g')}
            . ( $products and scalar(@$products)
            ? ' WHERE number = ANY (?)'
            : ''
        ),
        '(^|,)' . quotemeta($site) . '(,|$)',
        $products ? $products : (),
    );
}

sub set_site {
    my ( $self, $site, $products ) = @_;
    return unless length $site;

    $self->unset_site( $site, $products );
    return unless $products and @$products;

    $self->pg->db->query(
        'UPDATE products SET sites = sites || ?
            WHERE number = ANY (?)',
        ",$site",
        $products,
    );

    # TODO: get rid of this stupid hack
    $self->pg->db->query( q{UPDATE products SET sites
        = regexp_replace(sites, '(^,)|(,,)|(,$)', '', 'g')},
    );
}

sub set_pricing {
    my ( $self, $prods ) = @_;
    return unless $prods and @$prods;

    for my $prod ( @$prods ) {
        $self->pg->db->query(
            'UPDATE products SET price = ? WHERE number = ?',
            $prod->{price} || '0.00',
            $prod->{num},
        );
    }
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

        $product->{image} //= "$product->{number}.jpg" =~ tr{/}{_}r;
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

