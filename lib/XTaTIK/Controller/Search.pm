package XTaTIK::Controller::Search;

# VERSION

use Mojo::Base 'Mojolicious::Controller';
use XTaTIK::Common qw/n_to_br/;
use File::Spec::Functions qw/catfile/;

sub search {
    my $self = shift;

    my @prods = $self->products->get_by_id(
        $self->product_search->search( $self->param('term') )
    );

    $self->_find_product_pic( $_->{image} ) for @prods;

    $self->stash(
        template => 'root/search',
        products => \@prods,
    );
}

sub _find_product_pic {
    my $self = shift;

    $_[0] = 'nopic.png'
        unless $self->app->static
            ->file( catfile 'product-pics', $_[0]//'' );
}

1;

__END__