package Git::Database::Backend::Git::Sub;

use Cwd qw( cwd );
use Git::Sub qw(
  hash_object
);

use Moo;
use namespace::clean;

with
  'Git::Database::Role::Backend',
  ;

# the store attribute is a string
# so the auto-detection of the backend in Git::Database can't work

sub hash_object {
    my ( $self, $object ) = @_;
    my $home = cwd();
    my $dir  = $self->store;
    chdir $dir or die "Can't chdir to $dir: $!";
    my $hash = git::hash_object
      '-t'      => $object->kind,
      '--stdin' => \$object->content;
    chdir $home or die "Can't chdir to $home: $!";
    return $hash;
}

1;
