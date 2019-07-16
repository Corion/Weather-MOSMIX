package Moo::Role::DBIConnection;
use Moo::Role;
use feature 'signatures';
no warnings 'experimental::signatures';
use DBI;

=head1 NAME

Moo::Role::DBIConnection

=head1 SYNOPSIS

    { package My::Example;
      use Moo 2;
      with 'Moo::Role::DBIConnection';
    };

    # Connect using the parameters
    my $writer = My::Example->new(
        dbh => {
            dsn  => '...',
            user => '...',
            password => '...',
            options => '...',
        },
    );

    # ... or alternatively if you have a connection already
    my $writer2 = My::Example->new(
        dbh => $dbh,
    );

=cut

has 'dbh' => (
    is => 'lazy',
    default => \&_connect_db,
);

has 'dsn' => (
    is => 'ro',
);

has 'user' => (
    is => 'ro',
);

has 'password' => (
    is => 'ro',
);

has 'options' => (
    is => 'ro',
);

sub _connect_db( $self ) {
    my $dbh = DBI->connect(
        $self->dsn, $self->user, $self->password, $self->options
    );
}

1;
