#!/usr/bin/env perl

use Mojolicious::Lite;
plugin 'Config';
plugin 'FormChecker';
plugin 'mail';

require 'lib/data.html';
push @{ app->renderer->classes }, 'Fake';

######### HELPERS

helper xtext => sub {
    my ( $c, $var ) = @_;
    return $c->config('text')->{$var};
},


######### ROUTES

get '/' => 'index';

get $_ for qw(/products /about );

get '/contact' => sub {
    my $c = shift;
};

post '/contact' => sub {
    my $c = shift;

    $c->form_checker(
        rules => {
            name => { max => 2, },
            email => { max => 200, },
        },
    );

    return $c->render( template => 'contact' )
        unless $c->form_checker_ok;

    # Check CSRF token
    return $c->render(text => 'Bad CSRF token!', status => 403)
        if $c->validation->csrf_protect->has_error('csrf_token');

    return $c->render( template => 'contact' );
};

######### SUBS


######### START APP

app->start;

__DATA__