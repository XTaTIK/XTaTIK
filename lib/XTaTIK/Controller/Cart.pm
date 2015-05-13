package XTaTIK::Controller::Cart;

use Mojo::Base 'Mojolicious::Controller';

use experimental 'postderef';

my @CHECKOUT_FORM_FIELDS = qw/
    address1  address2  city  do_save_address  email
    lname  name  phone  promo_code  province  toc  zip
/;

sub index {
    my $self = shift;

    $self->stash( $self->cart->all_items_cart_quote_kv );
};

sub thank_you {
    my $self = shift;

    # TODO: refactor this into Module::Plugable
    my $handler = 'XTaTIK::Plugin::Cart::'
        . $self->config('checkout_system');
    eval "require $handler" or die $@;

    $self->stash( thank_you_html => $handler->new->thank_you( $self ) );
}

sub add {
    my $self = shift;

    my $p = $self->cart
        ->add( $self->param('quantity'), $self->param('number') );

    $self->cart_dollars('refresh'); $self->cart_cents('refresh');
    $self->cart->save;
    $self->stash(
        number    => $self->param('number'),
        quantity  => $self->param('quantity'),
        is_quote  => $p->{price} > 0 ? 0 : 1,
        return_to => $self->req->headers->referrer || '/products',
    );
};

sub checkout {
    my $self = shift;

    my @ids = map /(\d+)/, grep /^id/, $self->req->params->names->@*;

    for ( @ids ) {
        $self->cart->alter_quantity(
            $self->param('number_'   . $_),
            $self->param('quantity_' . $_)
        );
    }
    @ids and $self->cart->save;
    $self->cart_dollars('refresh'); $self->cart_cents('refresh');

    for ( @CHECKOUT_FORM_FIELDS ) {
        next if length $self->param($_);

        $self->param( $_ => $self->geoip_region )
            if $_ eq 'province' and not length $self->session($_);

        next unless length $self->session($_);
        $self->param( $_ => $self->session($_) );
    }

    $self->stash(
        $self->cart->all_items_cart_quote_kv,
    );
}

sub checkout_review {
    my $self = shift;

    my ( $cart ) = $self->cart->all_items_cart_quote;
    @$cart or $self->redirect_to('/cart/thank-you');

    if ( $self->param('do_save_address') ) {
        $self->session( $_ => $self->param($_) )
        for @CHECKOUT_FORM_FIELDS;
    }
    else {
        $self->session( $_ => undef )
            for @CHECKOUT_FORM_FIELDS;
    }

    $self->form_checker(
        rules => {
            email    => {
                max => 300,
                email => 'Email',
            },
            name    => {
                max => 300,
                name => 'First name',
            },
            lname    => {
                max => 300,
                name => 'Last name',
            },
            address1 => {
                max => 1000,
                name => 'Address line 1',
            },
            address2 => {
                max => 1000,
                name => 'Address line 2',
                optional => 1,
            },
            city    => {
                max => 300,
            },
            do_save_address => {
                optional => 1,
                select => 1,
            },
            province=> {
                valid_values => [
                    qw/AB BC MB NB NL NT NS NU ON PE QC SK YT/
                ],
                valid_values_error => 'Please specify province',
            },
            zip => {
                max => 20,
                name => 'Postal code',
            },
            phone => {
                name => 'Phone number',
            },
            toc => {
                mandatory_error => 'You must accept Terms and Conditions',
            },
            promo_code => {
                name => 'Promo code',
                optional => 1,
                max => 100,
            },
        },
    );

    unless ( $self->form_checker_ok ) {
        $self->flash(
            form_checker_error_wrapped => $self->form_checker_error_wrapped,
        );
        $self->stash( cart => $cart );
        $self->render(template => 'cart/checkout');
        return;
    }

     # TODO: refactor this into Module::Plugable
    my $handler = 'XTaTIK::Plugin::Cart::' . $self->config('checkout_system');
    eval "require $handler" or die $@;

    $self->stash( checkout_html => $handler->new->checkout( $self ) );

}

1;
