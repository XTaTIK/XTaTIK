#!/usr/bin/env perl

use Mojolicious::Lite;
use lib qw/lib/;
use XTaTIK::Model::Users;
use XTaTIK::Model::Products;
plugin 'Config';
plugin 'FormChecker';
use HTML::Entities;

### CONFIGURATION PREPROCESSING

my $mconf = {
    how     => app->config('mail')->{how},
    howargs => app->config('mail')->{howargs},
};
plugin mail => $mconf;

app->secrets([ app->config('mojo_secrets') ]);

require 'lib/data.html';
push @{ app->renderer->classes }, 'Fake';

my $locations = app->config('text')->{locations};
for ( @$locations ) {
    $_->{address} = join "<br>\n", map encode_entities($_),
        split /\n/, $_->{address};
}

######### HELPERS

helper xtext => sub {
    my ( $c, $var ) = @_;
    return $c->config('text')->{$var};
},

helper users => sub {
    state $users = XTaTIK::Model::Users->new,
},

helper products => sub {
    state $products = XTaTIK::Model::Products->new,
},


######### ROUTES

get '/' => 'index';

get $_ for qw(/about  /history  /login);

get '/products(*category)' => { category => '' } => sub {
    my $c = shift;
    my ( $products, $return_path, $return_name )
    = $c->products->get_category( $c->stash('category') );

    # use Acme::Dump::And::Dumper;
    # die DnD [ $return_path, $return_name ];

    $c->stash(
        products    => $products,
        return_path => $return_path,
        return_name => $return_name,
    );
} => 'products';


get '/contact' => sub {
    my $c = shift;
};

post '/contact' => sub {
    my $c = shift;

    $c->form_checker(
        error_class => 'message error',
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

    return $c->render( template => 'contact' )
        unless $c->form_checker_ok;

    # Check CSRF token
    return $c->render(text => 'Bad CSRF token!', status => 403)
        if $c->validation->csrf_protect->has_error('csrf_token');

    $c->stash( visitor_ip => $c->tx->remote_address );

    $c->mail(
        to       => app->config('mail')->{to}{quicknote},
        from     => app->config('mail')->{from}{quicknote},
        subject  => 'Quicknote from '
            . app->config('text')->{website_domain},

        type => 'text/html',
        data => $c->render_to_string('email-templates/quicknote'),
    );

    return $c->render( template => 'contact' );
};

post '/login' => sub {
    my $c = shift;

    if ( $c->users->check( $c->param('login'), $c->param('pass') ) ) {
        $c->session( is_logged_in => 1 );
        $c->redirect_to('user/index');
    }
    else {
        $c->stash( is_login_failed => 1 );
    }

};

any '/logout' => sub {
    my $c = shift;
    $c->session( is_logged_in => 0 );
    $c->redirect_to('/login');
};

############# LOGGED IN ROUTES

under '/user' => sub {
    my $c = shift;

    return 1 if $c->session('is_logged_in');
    return $c->redirect_to('/login');
};

get '/' => 'user/index';
get '/master-products-database' => sub {
    my $c = shift;
    $c->stash( products => $c->products->get_all );
} => 'user/master-products-database';

post '/master-products-database' => sub {
    my $c = shift;

    $c->form_checker(
        error_class => 'message error',
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

    return $c->render( template => 'user/master-products-database' )
        unless $c->form_checker_ok;

    # Check CSRF token
    return $c->render(text => 'Bad CSRF token!', status => 403)
        if $c->validation->csrf_protect->has_error('csrf_token');

    if ( $c->products->exists( $c->param('number') ) ) {
        $c->stash( already_have_this_product => 1 );
        return $c->render( template => 'user/master-products-database' );
    }

    $c->stash( product_add_ok => 1 );
    $c->products->add(
        map +( $_ => $c->param( $_ ) ),
            qw/number  image  title  category  group_master
                    group_desc unit description  tip_description  quote_description recommended/,
    );

} => 'user/master-products-database';

post '/master-products-database/update' => sub {
    my $c = shift;

    # Check CSRF token
    return $c->render(text => 'Bad CSRF token!', status => 403)
        if $c->validation->csrf_protect->has_error('csrf_token');

    my @ids = map /\d+/g, grep /^id/, @{$c->req->body_params->names};

    for my $id ( @ids ) {
        $c->products->update(
            $id,
            map +( $_ => $c->param( $_ . '_' . $id ) ),
            qw/number  image  title  category  group_master
                    group_desc unit description  tip_description  quote_description recommended/,
        );
    }

    $c->flash( product_update_ok => 1 );
    return $c->redirect_to('user/master-products-database');

};

post '/master-products-database/delete' => sub {
    my $c = shift;

    # Check CSRF token
    return $c->render(text => 'Bad CSRF token!', status => 403)
        if $c->validation->csrf_protect->has_error('csrf_token');

    $c->products->delete( split ' ', $c->param('to_delete') );

    $c->flash( product_delete_ok => 1 );
    return $c->redirect_to('user/master-products-database');

};

######### SUBS


######### START APP

app->start;

__DATA__
