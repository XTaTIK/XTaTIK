#!/usr/bin/env perl

use strict;
use warnings;
use 5.020;
use Acme::Dump::And::Dumper;

my @input = qw{
    /Foo
    /Foo/Bar
    /Foo/Bar/Ber
    /Foo/Bar/Ber/Bex
};

my @cats = qw{
    [Foo]
    [Foo*::*Bar]
    [Foo*::*Bar*::*Ber]
    [Foo*::*Bar*::*Ber*::*Bex]
    [Foo*::*Bar*::*Ber*::*Bex][Foo*::*Bar*::*Ber]
    [Foo][Foo*::*Bar*::*Ber]
};

for my $input ( @input ) {
    $input =~ s{^/}{};
    my $cat_line = $input =~ s{/}{*::*}gr;
    $cat_line = quotemeta $cat_line;
    say "-- $input matches:";
    say for grep /\[
        $cat_line
        (\*::\*)?
        (.(?!\*::\*))*
    \]/x, @cats;

    say "";
}

__END__