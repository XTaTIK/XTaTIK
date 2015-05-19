package XTaTIK::Plugin::Cart::PayPal;

# VERSION

use Mojo::Base -base;
use utf8;

sub __cur($) {
    return sprintf '%.02f', shift;
}

sub checkout {
    my ( $self, $c ) = @_;

    my $custom = $c->xtext('paypal')->{custom};
    $custom =~ s/\$promo_code/$c->param('promo_code')/ge;

    $c->stash(
        $c->cart->all_items_cart_quote_kv,
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

    return $c->redirect_to('/cart/')
        unless @{$c->cart->all_items};

    my $order_num = sprintf $c->xtext('order_number'), $c->cart->id;
    my $quote_num = sprintf $c->xtext('quote_number'), $c->cart->id;

    my ( $cart, $quote ) = $c->cart->all_items_cart_quote;
    my $cart_title  = @$cart  ? "Order #$order_num " : '';
    my $quote_title = @$quote ? "Quote #$quote_num " : '';
    $c->stash(
        cart          => $cart,
        quote         => $quote,
        visitor_ip    => $c->tx->remote_address,
        order_number  => $order_num,
        quote_number  => $quote_num,
        __costs($c),
        title => "Your $cart_title $quote_title on "
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
        title => "New $cart_title $quote_title on "
                . $c->config('text')->{website_domain},
        promo_code => $c->session('customer_data')->{promo_code} // 'N/A',
        map +( "cust_$_" => $c->session('customer_data')->{$_} ),
            qw/address1  address2  city  email  lname  name  phone
                province  zip/
    );

    #Send order email to ourselves
    $c->mail(
        test    => $c->config('mail')->{test},
        to      => $c->config('mail')->{to}{order},
        from    => $c->config('mail')->{from}{order},
        subject => $c->stash('title'),
        type    => 'text/html',
        data    => $c->render_to_string('email-templates/order-to-company'),
    );

    # TODO: there's gotta be a nicer way of doing this:
    $c->stash(__cart => undef);
    $c->session(cart_id => undef);
    $c->cart;
    $c->cart_dollars('refresh');
    $c->cart_cents('refresh');

    return $c->render_to_string( inline => $self->_template_thank_you );
}

sub __costs {
    my $c = shift;

    my ( $shipping, $gst, $hst, $pst, $total_d, $total_c);
    my $xtext_tax = $c->xtext('PST')->{
        $c->param('province')
        // ($c->session('customer_data') || {})->{province}
    };

    # TODO: are we sure shipping charges get the full tax??
    if ( ref $xtext_tax ) {
        my $hst_rate = $$xtext_tax / 100;
        $hst      = __cur $c->cart->total * $hst_rate;
        $shipping = __cur $c->xtext('shipping');
        ( $total_d, $total_c ) = split /\./,
            __cur +($c->cart->total + $shipping) * (1+$hst_rate);
        $shipping *=  1 + $hst_rate;
    }
    else {
        my $pst_rate = $xtext_tax / 100;
        my $gst_rate = $c->xtext('GST') / 100;
        $gst = __cur $c->cart->total * $gst_rate;
        $pst = __cur $c->cart->total * $pst_rate;
        $shipping = __cur $c->xtext('shipping');
        ( $total_d, $total_c ) = split /\./,
            __cur +($c->cart->total + $shipping) * (1+$pst_rate+$gst_rate);
        $shipping *= 1 + $pst_rate + $gst_rate;

    }

    return (
        gst             => __cur $gst//0,
        pst             => __cur $pst//0,
        hst             => __cur $hst//0,
        shipping        => __cur $shipping,
        total_dollars   => $total_d,
        total_cents     => $total_c,
    );
}

sub _template_thank_you {
    return <<'END_HTML';

% if ( @{stash('cart')} ) {
    <ul class="checkout_crumbs text-center">
       <li class="col-md-15 label-success">Review products</li>
       <li class="col-md-15 label-success">Enter contact information</li>
       <li class="col-md-15 label-success">Review Pricing</li>
       <li class="col-md-15 label-success">Pay for the order</li>
       <li class="col-md-15 label-primary">Receive confirmation</li>
    </ul>
% } else {
    <ul class="checkout_crumbs text-center">
       <li class="col-md-4 label-success">Review products</li>
       <li class="col-md-4 label-success">Enter contact information</li>
       <li class="col-md-4 label-primary">Receive confirmation</li>
    </ul>
% }

<div class="row">
    <div class="col-md-6">
        % if ( @{stash('quote')} ) {
            <div class="panel panel-primary">
                <div class="panel-heading">
                    <h3 class="panel-title"><i class="glyphicon glyphicon-comment"></i> Your Quote Request</h3>
                </div>
                <div class="panel-body">
                    <p>Thank you for your interest in our products.
                        A sales representative will contact you
                        within 2 business days.
                    </p>

                    <p>Your quote number is
                        <strong><%= stash 'quote_number' %></strong>.
                        Have this number handy if you contact us with
                        any questions about your quote request.
                    </p>
                </div>
            </div>
        % }
    </div>
    <div class="col-md-6">
        % if ( @{stash('cart')} ) {
            <div class="panel panel-primary">
                <div class="panel-heading">
                    <h3 class="panel-title"><i class="glyphicon glyphicon-shopping-cart"></i> Your Purchase</h3>
                </div>
                <div class="panel-body">
                    <p>Thank you for your purchase!
                        Your order will be shipped on the <strong>next
                        business day</strong> and will arrive within
                        <strong>5–7 business days</strong>.
                    </p>

                    <p>Your order number is
                        <strong><%= stash 'order_number' %></strong>.
                        Have this number handy if you contact us with any
                        questions about yourorder.
                    </p>
                </div>
            </div>
        % }
    </div>
</div>
END_HTML
}

sub _template_checkout {
    return <<'END_HTML';

<dl class="dl-horizontal" id="checkout_totals">
    <dt>Cost of products:</dt>
        <dd>$<%= cart->total %></dd>

    % if ( stash('hst')+0 ) {
        <dt><abbr title="Harmonized Sales Tax">HST</abbr>:</dt>
            <dd><strong>$<%= stash 'hst' %></strong></dd>
    % }

    % if ( stash('gst')+0 ) {
        <dt><abbr title="Goods and Services Tax">GST</abbr>:</dt>
            <dd><strong>$<%= stash 'gst' %></strong></dd>
    % }

    % if ( stash('pst')+0 ) {
        <dt><abbr title="Provincial Sales Tax">PST</abbr>:</dt>
            <dd><strong>$<%= stash 'pst' %></strong></dd>
    % }

    <dt>Shipping charge:</dt>
        <dd>$<%= stash 'shipping' %>
            <small>(includes applicable taxes)</small></dd>
    <dt class="total">Total:</dt>
        <dd class="total">$<%= stash 'total_dollars'
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
    %= hidden_field 'tax_cart'          => (stash('pst')+stash('gst')+stash('hst'))
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

    % for ( 1 .. @{stash('cart')} ) {
        % my $p = stash('cart')->[$_-1];
        %= hidden_field 'item_name_'   . $_ => $p->{title}
        %= hidden_field 'item_number_' . $_ => $p->{number}
        %= hidden_field 'amount_'      . $_ => $p->{price}
        %= hidden_field 'quantity_'    . $_ => $p->{quantity}
    % }

    %= submit_button 'Proceed to PayPal to complete this purchase', class => 'btn btn-lg btn-primary'
</form>
END_HTML
}

1;

__END__


=pod

Override C<checkout> and C<thank_you> methods in your own cart plugin

=cut