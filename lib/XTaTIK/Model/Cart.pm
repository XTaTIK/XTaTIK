package XTaTIK::Model::Cart;

use Mojo::Base -base;
use XTaTIK::Model::Products;
use DBI;
use JSON::MaybeXS;

my $Blank_Cart_Data = {
    contents => [],
    total    => '0.00',
};

has [qw/_dbh  _products  id   contents  total  dollars  cents
    _is_modified
/];

sub new_cart {
    my $self = shift;

    $self->_dbh->do(
        'INSERT INTO `carts` (`created_on`, `data`) VALUES (?, ?)',
        undef,
        time(),
        encode_json( $Blank_Cart_Data ),
    );

    $self->id( $self->_dbh->last_insert_id("","","","") );

    return $self->id;
}

sub add {
    my ( $self, $quantity, $number ) = @_;

    my $product = $self->_products->get_by_number( $number )
        or return;

    my $added = 0;
    for ( @{ $self->contents } ) {
        if ( $_->{n} eq $product->{number} ) {
            $added = 1;
            $_->{q} += $quantity;
            last;
        }
    }

    $added or push @{ $self->contents }, +{
        n   => $number,
        q   => $quantity,
        p   => $product->{price},
    };

    $self->_recalculate_total;
    return $product;
}

sub load {
    my $self = shift;

    my $id = $self->id
        or die "MISSING CART ID on load";

    my $cart_row = (
        $self->_dbh->selectall_arrayref(
            'SELECT * FROM `carts` WHERE `id` = ?',
            { Slice => {} },
            $id,
        ) || []
    )->[0];

    my $cart = eval { decode_json $cart_row->{data} }
        // decode_json encode_json $Blank_Cart_Data;

    $self->contents( $cart->{contents} );
    $self->_recalculate_total;

    return 1;
}

sub save {
    my $self = shift;

    return unless $self->_is_modified;

    my $id = $self->id
        or die "MISSING CART ID on save";

    $self->_dbh->do(
        'UPDATE `carts` SET `data` = ? WHERE `id` = ?',
        undef,
        encode_json({
            contents    => $self->contents,
            total       => $self->total,
        }),
        $id,
    );

    return 1;
}


sub _recalculate_total {
    my $self = shift;

    my $total = 0;
    $total += $_->{p} * $_->{q}
        for @{ $self->contents };

    $self->_is_modified( 1 );

    $total = sprintf '%.2f', $total;
    $self->total( $total );
    $self->dollars( (split /\./, $total)[0] );
    $self->cents(   (split /\./, $total)[1] );
    return $self->total;
}


1;

__END__

CREATE TABLE `carts` (
    `id` INTEGER PRIMARY KEY,
    `created_on` INT,
    `data` TEXT
);

