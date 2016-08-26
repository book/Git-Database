package Git::Database::Backend::Git::Wrapper;

use Sub::Quote;

use Moo;
use namespace::clean;

with
  'Git::Database::Role::Backend',
  ;

has '+store' => (
    isa => quote_sub( q{
        die 'store is not a Git::Wrapper object'
          if !eval { $_[0]->isa('Git::Wrapper') }
    } ),
);

sub hash_object {
    my ( $self, $object ) = @_;
    my @out = $self->store->hash_object( { -STDIN => $object->content },
        '--stdin', '-t', $object->kind );
    return shift @out;
}

1;
