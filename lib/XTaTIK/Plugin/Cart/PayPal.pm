package XTaTIK::Plugin::Cart::PayPal;

use Mojo::Base -base;

sub checkout {
    my ( $self, $c ) = @_;

    my $custom = $c->xtext('paypal')->{custom};
    $custom =~ s/\$promo_code/$c->param('promo_code')/ge;

    $c->stash(
        cart_products => $c->cart->all_items,
        custom        => $custom,
        __costs($c),
    );
    $c->session(
        customer_data => {
            map +( $_ => $c->param($_) ), qw/
                address1  address2  city  email
                lname  name  phone  promo_code  province  zip
            /
        },
    );

    return $c->render_to_string( inline => $self->_template_checkout );
}

sub thank_you {
    my ( $self, $c ) = @_;

    $c->redirect_to('/cart/')
        unless @{$c->cart->all_items};

    my $order_num = sprintf $c->xtext('order_number'), $c->cart->id;

    $c->stash(
        cart_products => $c->cart->all_items,
        visitor_ip    => $c->tx->remote_address,
        order_number  => $order_num,
        __costs($c),
        title => "Your Order #$order_num on "
            . $c->config('text')->{website_domain},
    );

    # Send order email to customer
    eval { # eval, since we don't know what address we're trying to send to
        $c->mail(
            test     => $c->config('mail')->{test},
            to       => $c->config('mail')->{to}{order},
            from     => $c->config('mail')->{from}{order},
            subject  => $c->stash('title'),
            type     => 'text/html',
            data     => $c->render_to_string('email-templates/order-to-customer'),
        );
    };

    $c->stash(
        title => "New Order #$order_num on "
            . $c->config('text')->{website_domain},
        promo_code => $c->session('customer_data')->{promo_code} // 'N/A',
        map +( "cust_$_" => $c->session('customer_data')->{$_} ),
            qw/address1  address2  city  email  lname  name  phone
                province  zip/
    );

    #Send order email to ourselves
    $c->mail(
        test     => $c->config('mail')->{test},
        to       => $c->config('mail')->{to}{order},
        from     => $c->config('mail')->{from}{order},
        subject  => $c->stash('title'),
        type     => 'text/html',
        data     => $c->render_to_string('email-templates/order-to-company'),
    );

    # TODO: there's gotta be a nicer way of doing this:
    $c->cart->drop;
    $c->stash(__cart => undef);
    $c->session(cart_id => undef);
    $c->cart;
    $c->cart_dollars('refresh');
    $c->cart_cents('refresh');

    return $c->render_to_string( inline => $self->_template_thank_you );
}

sub __costs {
    my $c = shift;

    my $tax_rate = $c->xtext('tax')->{
        $c->param('province')
        // ($c->session('customer_data') || {})->{province}
    } / 100;
    my @total = split /\./, __cur( $c->cart->total * (1+$tax_rate) );
    return (
        tax             => __cur( $c->cart->total * $tax_rate ),
        shipping        => __cur( $c->xtext('shipping') * (1+$tax_rate) ),
        total_dollars   => $total[0],
        total_cents     => $total[1],
    );
}

sub __cur {
    return sprintf '%.02f', shift;
}

sub _template_email {
    return <<'END_HTML';
% layout 'email';
% title 'Quicknote Message';

<p></p>
END_HTML
}

sub _template_thank_you {
    return <<'END_HTML';
    <p>Thank you for your purchase!
        Your order will be shipped on the <strong>next
        business day</strong> and will arrive within
        <strong>5–7 business days</strong>.</p>

    <p>Your order number is <strong><%= stash 'order_number' %></strong>.
    Have this number handy if you contact us with any questions about your
    order.</p>
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

__END__


=pod

Override C<checkout> and C<thank_you> methods in your own cart plugin

=cut