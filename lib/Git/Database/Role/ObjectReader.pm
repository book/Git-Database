package Git::Database::Role::ObjectReader;

use Moo::Role;

requires
  'get_object_meta',
  'get_object',
  'get_hashes',
  ;

sub has_object {
    my ( $self, $digest ) = @_;
    my ( $sha1, $kind, $size ) = $self->get_object_meta($digest);
    return $kind eq 'missing' ? '' : $kind;
}

1;
