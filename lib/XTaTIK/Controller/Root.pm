package XTaTIK::Controller::Root;

# VERSION

use Mojo::Base 'Mojolicious::Controller';
use XTaTIK::Common qw/n_to_br/;
use File::Spec::Functions qw/catfile/;

sub index   {
    my $self = shift;

    $self->stash(
        hot_products => [
            $self->products->get_by_number(
                split /\n/, $self->xvar('hot_products')
            )
        ],
    );
}

sub products_category {
    my $self = shift;

    my ( $products, $return_path, $return_name )
    = $self->products->get_category( $self->stash('category') );

    $self->_find_product_pic( $_->{image} ) for @$products;

    $self->stash(
        products    => $products,
        return_path => $return_path,
        return_name => $return_name,
    );
}

sub _find_product_pic {
    my $self = shift;

    $_[0] = 'nopic.png'
        unless $self->app->static
            ->file( catfile 'product-pics', $_[0]//'' );
}

sub product {
    my $self = shift;
    my ( $product ) = $self->products->get_by_url( $self->stash('url') );
    $product or $self->reply->not_found;

    $self->_find_product_pic( $product->{image} );

    $self->stash( product => $product );
};

sub contact_post {
    my $self = shift;

    $self->form_checker(
        rules => {
            name => { max => 200, },
            email => { max => 200, },
            province => {
                valid_values => [
                    qw/AB  BC  MB  NB  NF  NT  NS  NU  ON  PE  QC  SK  YT/
                ],
                valid_values_error => 'Please choose your province',
            },
            message => { max => 100_000 },
        },
    );

    return $self->render( template => 'root/contact' )
        unless $self->form_checker_ok;

    # Check CSRF token
    return $self->render(text => 'Bad CSRF token!', status => 403)
        if $self->validation->csrf_protect->has_error('csrf_token');

    $self->stash( visitor_ip => $self->tx->remote_address );
    $self->stash( message => n_to_br( $self->param('message')) );

    $self->mail(
        test     => $self->config('mail')->{test},
        to       => $self->config('mail')->{to}{quicknote},
        from     => $self->config('mail')->{from}{quicknote},
        subject  => 'Quicknote from '
            . $self->config('text')->{website_domain},

        type => 'text/html',
        data => $self->render_to_string('email-templates/quicknote'),
    );

    return $self->render( template => 'root/contact' );
}

sub feedback_post {
    my $self = shift;

    $self->form_checker(
        rules => {
            email    => { max => 200, optional => 1, },
            feedback => { max => 100_000, },
        },
    );

    return $self->render( template => 'root/feedback' )
        unless $self->form_checker_ok;

    $self->stash(
        visitor_ip => $self->tx->remote_address,
        feedback   => n_to_br( $self->param('feedback') ),
    );

    $self->mail(
        test     => $self->config('mail')->{test},
        to       => $self->config('mail')->{to}{feedback},
        from     => $self->config('mail')->{from}{feedback},
        subject  => 'Site Feedback from '
            . $self->config('text')->{website_domain},

        type => 'text/html',
        data => $self->render_to_string('email-templates/feedback'),
    );

    return $self->render( template => 'root/feedback' );
}

sub sitemap {
    my $self = shift;

    $self->stash(
        urls => [
            map +{
                freq => 'weekly',
                priority => '0.9',
                url => $self->xtext('website_proto')
                    . '://'
                    . $self->xtext('website_domain')
                    . $_,
            }, qw{
                /
                /blog
                /history
                /about
                /contact
            },
            ( map '/blog/' . $_->{url}, @{$self->blog->brief_list   ||[]}),
            map '/product/' . $_->{url}, @{ $self->products->get_all||[] },
        ],
    );
}

1;

