package XTaTIK::Controller::User;

use Mojo::Base 'Mojolicious::Controller';

sub index {}

sub login {
    my $self = shift;

    if ( $self->users->check( $self->param('login'), $self->param('pass') ) ) {
        $self->session( is_logged_in => 1 );
        $self->redirect_to('user/index');
    }
    else {
        $self->stash( is_login_failed => 1 );
    }
}

sub logout {
    my $self = shift;
    $self->session( is_logged_in => 0 );
    $self->redirect_to('/login');
}

sub is_logged_in {
    my $self = shift;

    return 1 if $self->session('is_logged_in');
    return $self->redirect_to('/login');
}

sub master_products_database {
    my $self = shift;
    $self->stash( products => $self->products->get_all );
}

sub master_products_database_post {
    my $self = shift;

    $self->form_checker(
        rules => {
            number => { max => 1000, },
            ( map +( $_ => { optional => 1, max => 1000 } ),
                    qw/image  title  category  group_master
                    group_desc unit/ ),
            ( map +( $_ => { optional => 1, max => 1000_000 } ),
                    qw/description  tip_description  quote_description
                    recommended/ ),
        },
    );

    return $self->render( template => 'user/master_products_database' )
        unless $self->form_checker_ok;

    # Check CSRF token
    return $self->render(text => 'Bad CSRF token!', status => 403)
        if $self->validation->csrf_protect->has_error('csrf_token');

    if ( $self->products->exists( $self->param('number') ) ) {
        $self->stash( already_have_this_product => 1 );
        return $self->render( template => 'user/master_products_database' );
    }

    $self->stash( product_add_ok => 1 );
    $self->products->add(
        map +( $_ => $self->param( $_ ) ),
            qw/number  image  title  category  group_master
                    group_desc unit description  tip_description  quote_description recommended/,
    );

    $self->render( template => 'user/master_products_database');
}

sub master_products_database_update {
    my $self = shift;

    # Check CSRF token
    return $self->render(text => 'Bad CSRF token!', status => 403)
        if $self->validation->csrf_protect->has_error('csrf_token');

    my @ids = map /\d+/g, grep /^id/, @{$self->req->body_params->names};

    for my $id ( @ids ) {
        $self->products->update(
            $id,
            map +( $_ => $self->param( $_ . '_' . $id ) ),
            qw/number  image  title  category  group_master
                    group_desc unit description  tip_description  quote_description recommended  price/,
        );
    }

    $self->flash( product_update_ok => 1 );
    return $self->redirect_to('/user/master-products-database');

}

sub master_products_database_delete {
    my $self = shift;

    # Check CSRF token
    return $self->render(text => 'Bad CSRF token!', status => 403)
        if $self->validation->csrf_protect->has_error('csrf_token');

    $self->products->delete( split ' ', $self->param('to_delete') );

    $self->flash( product_delete_ok => 1 );
    return $self->redirect_to('/user/master-products-database');
}

1;