#!perl

use Test::More;

use Test::Mojo::WithRoles 'ElementCounter';
my $t = Test::Mojo::WithRoles->new('XTaTIK');

use lib 't';
use Test::XTaTIK;
use File::Path qw/remove_tree/;
use File::Copy::Recursive qw/dirmove dircopy/;

-e 'blog_src'
    or BAIL_OUT 'Did not find blog_src dir. Are we in the wrong location?';

dirmove 'blog_src', 'backup_blog_src';
dircopy 't/blog_src', 'blog_src';

{
    $t->get_ok('/blog')->status_is(200)
        ->dive_reset
        ->dive_in('#article_list')
        ->element_count_is(' > li', '3')
        ->dive_in(' > li:first-child')

        ->dived_text_is(' a', 'Test Post 3')
        ->dived_text_is(' a small', '2015-05-14')
        ->element_exists(' a[href="/blog/2015-05-14-Test-Post-3"]')

        ->dived_text_is(' + li a', 'Test Post 2')
        ->dived_text_is(' + li a small', '2015-05-12')
        ->element_exists(' a[href="/blog/2015-05-12-Test-Post-2"]')

        ->dived_text_is(' + li + li a', 'Test Post')
        ->dived_text_is(' + li + li a small', '2015-05-10')
        ->element_exists(' a[href="/blog/2015-05-10-Test-Post"]')
}

{
    $t->get_ok('/blog/2015-05-14-Test-Post-3')->status_is(200)
        ->dive_reset
        ->text_is('article > p:first-child', 'Third post!!')
        ->element_exists('img[alt="Even a pic!"]')

        ->element_count_is('.blog_nav', 2)
        ->element_count_is('.blog_nav li', 2)
        ->element_exists('.blog_nav a[href="/blog/2015-05-12-Test-Post-2"]')
        ->text_is('.blog_nav li a', 'Test Post 2')

        ->element_count_is('.blog_nav ~ .blog_nav li', 1)
        ->element_exists('.blog_nav ~ .blog_nav'
                . ' a[href="/blog/2015-05-12-Test-Post-2"]')
        ->text_is('.blog_nav ~ .blog_nav li a', 'Test Post 2')
}

{
    $t->get_ok('/blog/2015-05-12-Test-Post-2')->status_is(200)
        ->dive_reset
        ->text_is('article > p:first-child', 'Another post \o/')

        ->element_count_is('.blog_nav', 2)
        ->element_count_is('.blog_nav li', 4)
        ->element_exists('.blog_nav'
                . ' li:first-child a[href="/blog/2015-05-14-Test-Post-3"]')
        ->element_exists('.blog_nav'
            . ' li:first-child + li a[href="/blog/2015-05-10-Test-Post"]')
        ->text_is('.blog_nav li:first-child a', 'Test Post 3')
        ->text_is('.blog_nav li:first-child + li a', 'Test Post')

        ->element_count_is('.blog_nav ~ .blog_nav li', 2)
        ->element_exists('.blog_nav ~ .blog_nav'
                . ' li:first-child a[href="/blog/2015-05-14-Test-Post-3"]')
        ->element_exists('.blog_nav ~ .blog_nav'
            . ' li:first-child + li a[href="/blog/2015-05-10-Test-Post"]')
        ->text_is('.blog_nav ~ .blog_nav li:first-child a', 'Test Post 3')
        ->text_is('.blog_nav ~ .blog_nav li:first-child+li a', 'Test Post')
}

{
    $t->get_ok('/blog/2015-05-10-Test-Post')->status_is(200)
        ->dive_reset
        ->text_is('article > p:first-child', 'Just a sample post #1.')

        ->element_count_is('.blog_nav', 2)
        ->element_count_is('.blog_nav li', 2)
        ->element_exists('.blog_nav a[href="/blog/2015-05-12-Test-Post-2"]')
        ->text_is('.blog_nav li a', 'Test Post 2')

        ->element_count_is('.blog_nav ~ .blog_nav li', 1)
        ->element_exists('.blog_nav ~ .blog_nav'
                . ' a[href="/blog/2015-05-12-Test-Post-2"]')
        ->text_is('.blog_nav ~ .blog_nav li a', 'Test Post 2')
}

remove_tree 'blog_src';
dirmove 'backup_blog_src', 'blog_src';

done_testing();

