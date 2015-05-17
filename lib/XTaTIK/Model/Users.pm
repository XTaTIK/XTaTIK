package XTaTIK::Model::Users;

use Mojo::Base -base;

has [qw/pg/];

my @VALID_ROLES = sort qw/
    users
    products
/;

sub check {
    return 1; # TODO: implement actual user verification, user roles, etc.
}

sub valid_roles {
    return @VALID_ROLES;
}

sub add_user {
    my $self = shift;
    my %params = @_;

    $_ //= '' for values %params;
    $params{roles} =~ s/\s*,\s*/,/g;
    $params{login} = lc($params{login}) =~ s/^\s+|\s+$//gr;
    $self->pg->db->query(
        'INSERT INTO users (login, name, email, phone, roles)
            VALUES (?, ?, ?, ?, ?)',
        map $params{$_}, qw/login  name  email  phone  roles/,
    );

    return 1;
}

sub get_user {
    my ( $self, $login ) = @_;

    my $user = $self->pg->db->query(
        'SELECT login, name, email, phone, roles
            FROM users WHERE login = ?',
        lc($login) =~ s/^\s+|\s+$//gr,
    )->hash or return;

    $_ = +{ map +( $_ => 1 ), split /,/ } for $user->{roles};

    return $user;
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