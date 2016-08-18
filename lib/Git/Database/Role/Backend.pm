package Git::Database::Role::Backend;

use Moo::Role;

requires
  'hash_object',
  ;

has store => (
    is       => 'ro',
    required => 1,
);

1;

__END__

=pod

=head1 NAME

Git::Database::Role::Backend - Abstract role for a Git database backend

=head1 SYNOPSIS

    package MyGitBackend;

    use Moo;
    use namespace::clean;

    with 'Git::Database::Role::Backend';

    sub hash_object { ... }

    1;

=head1 DESCRIPTION

The C<Git::Database::Role::Backend> role encapsulate code for the user-facing
store objects. To be usable as a L<backend|Git::Repository::Tutorial/backend>,
a class must at least do this role.

=head1 REQUIRED ATTRIBUTES

=head2 store

The L<store|Git::Database::Tutorial/store> that will store and retrieve
data from the Git repository.

=head1 REQUIRED METHODS

These methods are I<required> by the role, classes consuming this role
B<must> provide them.

=head2 hash_object

    # the empty tree
    my $tree = Git::Database::Object::Tree->new( content => '' );
    
    # 4b825dc642cb6eb9a060e54bf8d69288fbee4904
    my $digest = $backend->hash_object( $tree );

Compute and return the SHA-1 digest for the given object.

May be called from the L<digest|Git::Database::Role::Object/digest>
builder for one of the object classes (L<Git::Database::Object::Blob>,
L<Git::Database::Object::Tree>, L<Git::Database::Object::Commit>,
L<Git::Database::Object::Tag>), so the implementation should not try to
shortcut and call C<< $object->digest >>.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>

=head1 COPYRIGHT

Copyright 2016 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
