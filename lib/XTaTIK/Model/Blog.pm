
package XTaTIK::Model::Blog;

use Mojo::Base -base;

use Text::Markdown 'markdown';
use File::Glob qw/bsd_glob/;
use File::Slurp::Tiny 'read_file';
use List::UtilsBy qw/sort_by/;
use Encode;

use experimental 'postderef';

sub brief_list {
    my $self = shift;

    my @posts= bsd_glob 'blog_src/*';

    for ( @posts ) {
        s{^blog_src/}{};
        my ( $date, $title ) = /(\d{4}-\d{2}-\d{2})-(.+)\.md/;
        $title =~ tr/-/ /;
        $_ = {
            date    => $date,
            title   => $title,
            url     => s/.md$//r,
        };
    }

    @posts = reverse sort_by { $_->{date} } @posts;

    return \@posts;
}

sub post {
    my $self = shift;
    my $post = shift;
    my ( $date, $title ) = $post =~ /(\d{4}-\d{2}-\d{2})-(.+)/;
    $title =~ tr/-/ /;

    my $post_src = 'blog_src/' . $post =~ s/[^\w-]//rg . '.md';

    return unless -e $post_src;

    my ( $next, $prev, $found_next );
    for ( $self->brief_list->@* ) {
        if ( $_->{url} eq $post ) {
            $found_next = 1;
            next;
        }

        $next = $_ unless $found_next;

        if ( $found_next ) {
            $prev = $_ ;
            last;
        }
    }

    for ( $next, $prev ) {
        defined or next;
        my $post_src = 'blog_src/' .
            $_->{url} =~ s/[^\w-]//rg . '.md';
        my $content = decode 'utf8', read_file $post_src;
        my %metas;
        $metas{ $1 } = $2 while $content =~ s/^%\s+(\w+)\s+(.+)$//m;
        $_->{description} = $metas{description};
    }

    my $content = decode 'utf8', read_file $post_src;
    my %metas;
    $metas{ $1 } = $2 while $content =~ s/^%\s+(\w+)\s+(.+)$//m;

    return (
        $title,
        $date,
        \%metas,
        markdown($content),
        $prev,
        $next,
    );
}

1;

__END__