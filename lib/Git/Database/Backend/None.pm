package Git::Database::Backend::None;

use Digest::SHA;

use Moo;
use namespace::clean;

with 'Git::Database::Role::Backend';

has '+store' => (
    is       => 'ro',
    required => 0,
    init_arg => undef,
);

sub hash_object {
    my ( $self, $object ) = @_;
    my $sha1 = Digest::SHA->new;
    $sha1->add( $object->kind, ' ', $object->size, "\0", $object->content );
    $sha1->hexdigest;
}

1;
