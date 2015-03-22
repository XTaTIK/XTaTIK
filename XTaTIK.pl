#!/usr/bin/env perl

use Mojolicious::Lite;
use lib qw/lib/;
use XTaTIK::Model::Users;
plugin 'Config';
plugin 'FormChecker';
use HTML::Entities;

### CONFIGURATION PREPROCESSING

my $mconf = {
    how     => app->config('mail')->{how},
    howargs => app->config('mail')->{howargs},
};
plugin mail => $mconf;

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


######### ROUTES

get '/' => 'index';

get $_ for qw(/products /about /history  /login);

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
        data => $c->render_to_string('quicknote'),
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

######### SUBS


######### START APP

app->start;

__DATA__