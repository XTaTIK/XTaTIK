#!/usr/bin/env perl

use Mojolicious::Lite;
plugin 'Config';

require 'lib/data.html';
push @{ app->renderer->classes }, 'Fake';

helper xtext => sub {
    my ( $c, $var ) = @_;
    return $c->config('text')->{$var};
},

get '/' => 'index';

get $_ for qw(/products /about  /contact);

post '/contact' => sub {
    my $c = shift;

    # Check CSRF token
    my $val= $c->validation;
    return $c->render(text => 'Bad CSRF token!', status => 403)
        if $val->csrf_protect->has_error('csrf_token');

    $val->required('name')->size(1, 200);
    $val->required('email')->size(1, 200);
    $val->required('province')->in(
        qw/AB BC MB NB NF NT NS NU ON PE QC SK YT/
    );

    $c->render(text => "Low orbit ion cannon pointed at ")
        unless $val->has_error;

        say for $val->error;

    return $c->render( template => 'contact' );
};

app->start;

__DATA__