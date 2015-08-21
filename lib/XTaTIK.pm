package XTaTIK;

# VERSION

use Mojo::Base 'Mojolicious';

use XTaTIK::Model::Cart;
use XTaTIK::Model::Quotes;
use XTaTIK::Model::Products;
use XTaTIK::Model::Users;
use XTaTIK::Model::Blog;
use XTaTIK::Model::ProductSearch;
use XTaTIK::Model::XVars;
use File::Find::Rule;
use File::Spec::Functions qw/catfile/;

use HTML::Entities;
use Mojo::Pg;

my $PG;

sub startup {
    my $self = shift;
    $self->moniker('XTaTIK');
    $self->plugin('Config');

    if ( $ENV{XTATIK_COMPANY} ) {
        unshift @{ $self->renderer->paths },
            catfile $ENV{XTATIK_COMPANY}, 'templates';

        unshift @{ $self->static->paths },
            catfile $ENV{XTATIK_COMPANY}, 'public';
    }

    my $silo_path = $ENV{XTATIK_SITE_ROOT}
        // catfile 'silo', $self->config('site');

    unshift @{ $self->renderer->paths },
            catfile $silo_path, 'templates';

    unshift @{ $self->static->paths },
        catfile $silo_path, 'public';

    $self->secrets([ $self->config('mojo_secrets') ]);

    $self->config( hypnotoad => {listen => ['http://*:3005'], proxy => 1} );

    $self->plugin('AntiSpamMailTo');
    $self->plugin('FormChecker' => error_class => 'foo');
    $self->plugin('IP2Location');
    $self->plugin('AssetPack');
    $self->plugin('bootstrap3');

    $self->asset(
        'app.css' => qw{
            /CSS/reset.scss
            /CSS/bs-callout.scss
            /CSS/bootstrap-extras.scss
            /CSS/main.scss
        },
        (
            map s{^\Q$silo_path\E[\\/]public[\\/]}{}r,
                File::Find::Rule->name('*.css', '*.scss')
                ->in( catfile($silo_path, 'public', 'CSS') ),
        ),
        (
            $ENV{XTATIK_COMPANY}
            ? (
                map s{^\Q$ENV{XTATIK_COMPANY}\Epublic[\\/]}{}r,
                    File::Find::Rule->name('*.css', '*.scss')
                    ->in( catfile($ENV{XTATIK_COMPANY}, 'public', 'CSS') )
            ) : ()
        )
    );

    $self->asset(
        'app.js' => qw{
            /JS/ie10-viewport-bug-workaround.js
            /JS/main.js
        },
        (
            map s{^\Q$silo_path\E[\\/]public[\\/]}{}r,
                File::Find::Rule->name('*.js')
                ->in( catfile($silo_path, 'public', 'JS') ),
        ),
        (
            $ENV{XTATIK_COMPANY}
            ? (
                map s{^\Q$ENV{XTATIK_COMPANY}\Epublic[\\/]}{}r,
                    File::Find::Rule->name('*.js')
                    ->in( catfile($ENV{XTATIK_COMPANY}, 'public', 'JS') )
            ) : ()
        )
    );

    my $mconf = {
        how     => $self->config('mail')->{how},
        howargs => $self->config('mail')->{howargs},
    };
    $self->plugin(mail => $mconf);

    # Initialize globals (this is probably a stupid way to do things)
    $PG = Mojo::Pg->new( $self->config('pg_url') );

    $self->session( expiration => 60*60*24*7 );

    $self->helper( xtext          => \&_helper_xtext          );
    $self->helper( xvar           => \&_helper_xvar           );
    $self->helper( users          => \&_helper_users          );
    $self->helper( products       => \&_helper_products       );
    $self->helper( quotes         => \&_helper_quotes         );
    $self->helper( cart           => \&_helper_cart           );
    $self->helper( cart_dollars   => \&_helper_cart_dollars   );
    $self->helper( cart_cents     => \&_helper_cart_cents     );
    $self->helper( product_search => \&_helper_product_search );
    $self->helper(
        blog => sub {
            state $blog = XTaTIK::Model::Blog->new(
                blog_root => catfile $silo_path, 'blog_src'
            );
        }
    );
    $self->helper( active_page => sub {
        my ( $c, $name ) = @_;
        my $active = $c->stash('active_page') // '';
        return $active eq $name ? ' class="active"' : '';
    });

    my $r = $self->routes;
    { # Root routes
        $r->get('/'        )->to('root#index'        );
        $r->get('/contact' )->to('root#contact'      );
        $r->get('/about'   )->to('root#about'        );
        $r->get('/search'  )->to('search#search'     );
        $r->get('/history' )->to('root#history'      );
        $r->get('/login'   )->to('root#login'        );
        $r->post('/contact')->to('root#contact_post' );
        $r->get('/feedback')->to('root#feedback'     );
        $r->get('/sitemap' )->to('root#sitemap'      );
        $r->post('/feedback')->to('root#feedback_post');
        $r->get('/product/(*url)')->to('root#product');
        $r->get('/products(*category)')
            ->to('root#products_category', { category => '' });
    }

    { # Cart routes
        my $rc = $r->under('/cart');
        $rc->get( '/'               )->to('cart#index'          );
        $rc->any( '/thank-you'      )->to('cart#thank_you'      );
        $rc->post('/add'            )->to('cart#add'            );
        $rc->post('/checkout'       )->to('cart#checkout'       );
        $rc->post('/checkout-review')->to('cart#checkout_review');
    }

    { # Blog routes
        my $rb = $r->under('/blog');
        $rb->get('/'     )->to('blog#index');
        $rb->get('/*post')->to('blog#read');
    }

    { # User section routes
        $r->post('/login' )->to('user#login' );
        $r->any( '/logout')->to('user#logout');

        my $ru = $r->under('/user')->to('user#is_logged_in');
        $ru->get('/')->to('user#index')->name('user/index');
        $ru->get('/master-products-database')
            ->to('user#master_products_database')
            ->name('user/master_products_database');
        $ru->post('/master-products-database')
            ->to('user#master_products_database_post');
        $ru->post('/master-products-database/update')
            ->to('user#master_products_database_update');
        $ru->post('/master-products-database/delete')
            ->to('user#master_products_database_delete');
        $ru->get('/manage-users')->to('user#manage_users');
        $ru->post('/manage-users/add')->to('user#add_user');
        $ru->post('/manage-users/update')->to('user#update_users');
        $ru->post('/manage-users/delete')->to('user#delete_users');
        $ru->get('/hot-products')->to('user#hot_products');
        $ru->post('/hot-products')->to('user#hot_products_post');
        $ru->get('/quotes')->to('user#quotes_handler');
    }
}

#### HELPERS

sub _helper_xtext {
    my ( $c, $var, $v ) = @_;
    $c->config('text')->{ $var } = $v
        if @_ == 3;

    return $c->config('text')->{ $var };
}

sub _helper_xvar {
    my ( $c, $var, $value ) = @_;
    state $xvars = XTaTIK::Model::XVars->new(pg => $PG);

    if ( defined $value ) {
        $xvars->set($var, $value);
    }
    else {
        return $xvars->get($var);
    }
};

sub _helper_users {
    state $users = XTaTIK::Model::Users->new(
        pg => $PG,
    );
};

sub _helper_product_search {
    state $search = XTaTIK::Model::ProductSearch->new;
};

sub _helper_products {
    my $c = shift;
    state $products = XTaTIK::Model::Products->new(
        pricing_region => $c->geoip_region,
        pg => $PG,
        custom_cat_sorting => $c->config('custom_cat_sorting'),
        site => $c->config('site'),
    );
};

sub _helper_quotes {
    my $c = shift;

    state $quotes = XTaTIK::Model::Quotes->new( pg => $PG );
    return $quotes;
};

sub _helper_cart {
    my $c = shift;

    return $c->stash('__cart') if $c->stash('__cart');

    my $cart = XTaTIK::Model::Cart->new(
        pg       => $PG,
        products => $c->products,
    );

    if ( my $id = $c->session('cart_id') ) {
        $cart->id( $id );
    }
    else {
        $c->session( cart_id => $cart->new_cart );
    }

    $cart->load;

    $c->stash( __cart => $cart );
    return $cart;
};

sub _helper_cart_dollars {
    my $c = shift;
    my $is_refresh = shift;
    my $dollars = $is_refresh
        ? $c->cart->dollars
        : $c->session('cart_dollars') // $c->cart->dollars;
    $c->session( cart_dollars => $dollars );
    return $dollars;
};

sub _helper_cart_cents {
    my $c = shift;
    my $is_refresh = shift;
    my $cents = $is_refresh
        ? $c->cart->cents
        : $c->session('cart_cents') // $c->cart->cents;
    $c->session( cart_cents => $cents);
    return $cents;
};

1;

__END__

=encoding utf8

=for stopwords eCommerce

=head1 NAME

XTaTIK - Rapidly deployable, simple eCommerce website base

=head1 AUTHOR

=for pod_spiffy start author section

=for pod_spiffy author ZOFFIX

=for text Zoffix Znet <zoffix at cpan.org>

=for pod_spiffy end author section

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut
