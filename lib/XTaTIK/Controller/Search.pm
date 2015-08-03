package XTaTIK::Controller::Search;

# VERSION

use Mojo::Base 'Mojolicious::Controller';
use XTaTIK::Common qw/n_to_br/;

sub search {
    my $self = shift;

    $self->stash(
        template => 'root/search',
        products => [
            $self->products->get_by_id(
                $self->product_search->search( $self->param('term') )
            )
        ],
    );
}

1;

__END__