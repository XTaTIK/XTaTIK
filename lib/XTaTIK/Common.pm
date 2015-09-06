package XTaTIK::Common;

# VERSION

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(n_to_br  find_product_pic);

use strict;
use warnings;
use HTML::Entities;
use File::Spec::Functions qw/catfile/;

sub n_to_br {
    my $data = shift;
    return '' unless length $data;
    return encode_entities($data) =~ s/\n\r?|\r\n/<br>/gr;
}

sub find_product_pic {
    my $c = shift;

    $_[0] = 'nopic.png'
        unless $c->app->static
            ->file( catfile 'product-pics', $_[0]//'' );
}