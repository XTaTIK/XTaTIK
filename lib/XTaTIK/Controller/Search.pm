package XTaTIK::Controller::Search;

# VERSION

use Mojo::Base 'Mojolicious::Controller';
use XTaTIK::Common qw/n_to_br  find_product_pic/;

sub search {
    my $self = shift;

    my @prods = $self->products->get_by_id(
        $self->product_search->search( $self->param('term') )
    );

    find_product_pic( $self, $_->{image} ) for @prods;

    $self->stash(
        template => 'root/search',
        products => \@prods,
    );
}

1;

__END__