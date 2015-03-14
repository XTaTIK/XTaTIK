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

get $_ for qw(/products /about /contact);

app->start;

__DATA__