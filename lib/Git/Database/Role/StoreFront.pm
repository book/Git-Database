package Git::Database::Role::StoreFront;

use Moo::Role;

requires
  'check_object',
  'get_object',
;

sub has_object {
    my ( $self, $digest ) = @_;
    my ( $sha1, $kind, $size ) = $self->check_object($digest);
    return $kind eq 'missing' ? '' : $kind;
}

1;

__END__

=pod

=head1 NAME

Git::Database::Role::StoreFront - Role for a Git data store frontend

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 has_object

    if ( $store->has_object($digest) ) {
        ...;
    }

Returns a boolean value indicating if the given digest is available in
this store. If true, the returned value will be equal to the object kind
(C<blob>, C<tree>, C<commit> or C<tag>).

=head1 REQUIRED METHODS

These methods are I<required> by the role, classes consuming this role
must provide them.

=head2 check_object

    my ( $sha1, $kind, $size ) = $store->check_object($digest);

Return the full SHA-1, object kind and size in bytes for the object
corresponding to the given digest in the underlying repository.

If C<$digest> is abbreviated, C<$sha1> is the full SHA-1 digest for
the object.

When the digest cannot be resolved to an object in the repository,
C<$sha1> is identical to C<$digest>, C<$kind> is equal to C<missing>,
and <$size> is C<undef>.

=head2 get_object

    my $object = $store->get_object($digest);

Return an object doing the L<Git::Database::Role::Object> role, or
C<undef> if the store does not contain an object for the given digest.

If the given digest is a "short SHA1" and it is ambiguous (matches more
than one object), no object will be returned. Depending on the actual
store class, a warning might be emitted.

=cut
