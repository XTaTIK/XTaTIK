package XTaTIK::Plugin::Cart::PayPal;

use Mojo::Base -base;

sub checkout {
    my ( $self, $c ) = @_;

    my $custom = $c->xtext('paypal')->{custom};
    $custom =~ s/\$promo_code/$c->param('promo_code')/ge;

    my $cart = $c->cart;
    my $tax_rate = $c->xtext('tax')->{ $c->param('province') } / 100;
    my @total = split /\./, _cur( $cart->total * (1+$tax_rate) );
    $c->stash(
        cart_products   => $cart->all_items,
        tax             => _cur( $cart->total * $tax_rate ),
        shipping        => _cur( $c->xtext('shipping') * (1+$tax_rate) ),
        total_dollars   => $total[0],
        total_cents     => $total[1],
        custom          => $custom,
    );

    return $c->render_to_string( inline => $self->_template_checkout );
}

sub thank_you {
    my ( $self, $c ) = @_;

    return $c->render_to_string( inline => $self->_template_thank_you );
}

sub _cur {
    return sprintf '%.02f', shift;
}

sub _template_thank_you {
    return <<'END_HTML';
    <p>Thank you for your purchase!'
        Your order will be shipped on the <strong>next
        business day</strong>. And will arrive within
        <strong>5–7 business days</strong>.</p>
END_HTML
}

sub _template_checkout {
    return <<'END_HTML';

<dl>
    <dt>Cost of products:</dt>
        <dd>$<%= cart->total %></dd>
    <dt><abbr title="Goods and Services Tax">GST</abbr>:</dt>
        <dd>$<%= stash 'tax' %></dd>
    <dt>Shipping charge:</dt>
        <dd>$<%= stash 'shipping' %>
            <small>(includes applicable taxes)</small></dd>
    <dt>Total:</dt>
        <dd>$<%= stash 'total_dollars'
            %><sup>.<%= stash 'total_cents' %></sup></dd>
</dl>

<form action="https://www.paypal.com/ca/cgi-bin/webscr" method="POST"
    id="checkout_paynow_form">
    %= hidden_field 'upload'            => 1
    %= hidden_field 'cmd'               => '_cart'
    %= hidden_field 'custom'            => stash 'custom'
    %= hidden_field 'business'          => xtext('paypal')->{email}
    %= hidden_field 'currency_code'     => xtext 'currency'
    %= hidden_field 'cancel_return'     => xtext('current_site') . 'cart/'
    %= hidden_field 'return' => xtext('current_site') . 'cart/thank-you'
    %= hidden_field 'tax_cart'          => stash 'tax'
    %= hidden_field 'handling_cart'     => stash 'shipping'
    %= hidden_field 'address_override'  => 1
    %= hidden_field 'country'           => 'CA'; # TODO: allow for others
    %= hidden_field 'address1'          => param('address1')
    %= hidden_field 'address2'          => param('address2')
    %= hidden_field 'city'              => param('city')
    %= hidden_field 'state'             => param('province')
    %= hidden_field 'zip'               => param('zip')
    %= hidden_field 'night_phone_a'     => 1; # TODO: sort phones out
    %= hidden_field 'night_phone_b'     => param('phone')

    % for ( 1 .. @{stash('cart_products')||[]} ) {
        % my $p = stash('cart_products')->[$_-1];
        %= hidden_field 'item_name_'   . $_ => $p->{title}
        %= hidden_field 'item_number_' . $_ => $p->{number}
        %= hidden_field 'amount_'      . $_ => $p->{price}
        %= hidden_field 'quantity_'    . $_ => $p->{quantity}
    % }

    %= submit_button 'Proceed to PayPal to complete this purchase'
</form>
END_HTML
}

1;