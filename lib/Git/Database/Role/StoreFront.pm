package Git::Database::Role::StoreFront;

use Moo::Role;

requires
  'has_object',
  'get_object',
;

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

=head2 get_object

    my $object = $store->get_object($digest);

Return an object doing the L<Git::Database::Role::Object> role, or
C<undef> if the store does not contain an object for the given digest.

If the given digest is a "short SHA1" and it is ambiguous (matches more
than one object), no object will be returned. Depending on the actual
store class, a warning might be emitted.

=cut
