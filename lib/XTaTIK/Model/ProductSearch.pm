package XTaTIK::Model::ProductSearch;

# VERSION

use Mojo::Base -base;
use Search::Indexer;
use Mojo::DOM;
use List::UtilsBy qw/nsort_by/;
use experimental 'postderef';

my $Search_Dir = 'search_index';

sub add {
    my ( $self, $id, $keywords ) = @_;

    $keywords = eval { Mojo::DOM->new($keywords)->all_text } // $keywords;

    my @keywords;
    for ( $keywords =~ /[-\w]+/g ) {
        while ( length ) {
            push @keywords, $_;
            $_ = substr $_, 0, length($_)-1;
        }
    }

    Search::Indexer->new( dir => $Search_Dir, writeMode => 1 )
        ->add( $id, join ' ', @keywords );

    return 1;
}

sub delete {
    my ( $self, $id ) = @_;

    Search::Indexer->new( dir => $Search_Dir, writeMode => 1 )
        ->remove( $id );

    return 1;
}

sub search {
    my ( $self, $term ) = @_;

    my $res = Search::Indexer->new( dir => $Search_Dir )->search( $term );
    return nsort_by { $res->{scores}->{$_} } keys $res->{scores}->%*;
}

1;

__END__


