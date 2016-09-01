package Git::Database::Backend::Git::PurePerl;

use Sub::Quote;

use Moo;
use namespace::clean;

with
  'Git::Database::Role::Backend',
  ;

has '+store' => (
    isa => quote_sub( q{
        die 'store is not a Git::PurePerl object'
          if !eval { $_[0]->isa('Git::PurePerl') }
    } ),
);

sub hash_object {
    my ( $self, $object ) = @_;
    return Digest::SHA->new->add( $object->kind, ' ', $object->size, "\0",
        $object->content )->hexdigest;
}

1;
