package Git::Simple::Role::Object;

use Moo::Role;
use Sub::Quote;

requires qw( kind );

has repository => (
    is       => 'ro',
    required => 1,
);

has digest => (
    is  => 'lazy',
    isa => quote_sub(
        q{ die "Not a SHA-1 digest" unless $_[0] =~ /^[0-9a-f]{40}/; }),
);

# size in bytes
has size => (
    is      => 'lazy',
    default => sub { length $_[0]->content },
);

has content => (
    is => 'lazy',
);

# to compute the digest of a new object, save it in the object database
sub _build_digest {
    my ($self) = @_;
    return
        scalar $self->repository->run( 'hash-object', '-t', $self->kind,
        '--stdin', '-w', { input => $self->content } );
}

1;

__END__

# ABSTRACT: Role for objects from the Git object database
