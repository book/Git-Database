package Git::Database::Role::ObjectReader;

use Git::Database::Object::Blob;
use Git::Database::Object::Tree;
use Git::Database::Object::Commit;
use Git::Database::Object::Tag;

use Moo::Role;

requires
  'get_object_meta',
  'get_object_attributes',
  'get_hashes',
  ;

sub has_object {
    my ( $self, $digest ) = @_;
    my ( $sha1, $kind, $size ) = $self->get_object_meta($digest);
    return $kind eq 'missing' ? '' : $kind;
}

my %kind2class = (
    blob   => 'Git::Database::Object::Blob',
    tree   => 'Git::Database::Object::Tree',
    commit => 'Git::Database::Object::Commit',
    tag    => 'Git::Database::Object::Tag',
);

sub get_object {
    my ( $self, $digest ) = @_;
    my $attr = $self->get_object_attributes($digest);
    return $attr
      && $kind2class{ $attr->{kind} }->new( %$attr, backend => $self );
}

1;
