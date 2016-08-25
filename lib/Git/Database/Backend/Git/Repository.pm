package Git::Database::Backend::Git::Repository;

use Sub::Quote;

use Moo;
use namespace::clean;

with
  'Git::Database::Role::Backend',
  ;

has '+store' => (
    isa => quote_sub( q{
        die 'store is not a Git::Repository object'
          if !eval { $_[0]->isa('Git::Repository') }
        # die version check
    } ),
);

has object_checker => (
    is        => 'lazy',
    init_arg  => undef,
    builder   => sub { $_[0]->store->command( 'cat-file', '--batch-check' ); },
    predicate => 1,
    clearer   => 1,
);

sub hash_object {
    my ($self, $object ) = @_;
    return scalar $self->store->run( 'hash-object', '-t', $object->kind,
        '--stdin', { input => $object->content } );
}

sub DEMOLISH {
    my ( $self, $in_global_destruction ) = @_;
    return if $in_global_destruction;    # why bother?

    $self->object_checker->close if $self->has_object_checker;
}

1;
