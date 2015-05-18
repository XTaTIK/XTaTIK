package XTaTIK::Model::Users;

use Mojo::Base -base;
use Digest;
use MIME::Base64;
use Data::Entropy::Algorithms qw/rand_bits/;

has [qw/pg/];

my @VALID_ROLES = sort qw/
    users
    products
/;

sub check {
    my ( $self, $login, $pass ) = @_;

    my $user = $self->get( $login );

    unless ( $user ) {
        # we don't want a possible attacker to know whether or not they
        # got the login right, just by seeing the page returns fast
        _hash(rand);
        return 0;
    }

    my ( $hash ) = _hash( $pass, $user->{salt} );
    use Acme::Dump::And::Dumper;
    die DnD [ $hash, $user ];
    return $hash eq $user->{pass} ? 1 : 0;
}

sub valid_roles {
    return @VALID_ROLES;
}

sub add {
    my $self = shift;
    my %params = @_;

    $_ //= '' for values %params;
    $params{roles} =~ s/\s*,\s*/,/g;
    $params{login} = lc($params{login}) =~ s/^\s+|\s+$//gr;
    @params{qw/pass salt/} = _hash($params{pass});

    $self->pg->db->query(
        'INSERT INTO users (login, pass, salt, name, email, phone, roles)
            VALUES (?, ?, ?, ?, ?, ?, ?)',
        map $params{$_}, qw/login  pass  salt  name  email  phone  roles/,
    );

    return 1;
}

sub update {
    my ( $self, $id, %values ) = @_;

    $self->pg->db->query(
        'UPDATE users SET
            login = ?, name = ?, email = ?, phone = ?, roles = ?
                WHERE id = ?',
        @values{qw/login  name  email  phone  roles/},
        $id,
    );
}

sub delete {
    my ( $self, $login ) = @_;
    $self->pg->db->query( 'DELETE FROM users WHERE login = ?', $login );
}

sub get {
    my ( $self, $login ) = @_;

    my $user = $self->pg->db->query(
        'SELECT login, pass, salt, name, email, phone, roles            FROM users WHERE login = ?',
        lc($login) =~ s/^\s+|\s+$//gr,
    )->hash or return;

    $_ = +{ map +( $_ => 1 ), split /,/ } for $user->{roles};

    return $user;
}

sub get_all {
    my $self = shift;

    return $self->pg->db->query(
        'SELECT login, pass, salt, name, email, phone, roles
            FROM users ORDER BY login',
    )->hashes;
}

sub _hash {
    my ( $pass, $salt ) = @_;
    $salt = defined $salt ? decode_base64($salt) : rand_bits 8*16;
    use Acme::Dump::And::Dumper;
    say DnD [ $salt ];
    my $hash = Digest->new("Bcrypt")->cost(15)->salt( $salt )
                        ->add( $pass )->hexdigest;

    return ( $hash, encode_base64 $salt, '' );
}

1;

__END__

CREATE TABLE users (
    id      SERIAL PRIMARY KEY,
    login   TEXT,
    name    TEXT,
    email   TEXT,
    phone   TEXT,
    roles   TEXT
);