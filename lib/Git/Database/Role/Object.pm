package Git::Database::Role::Object;

use Sub::Quote;

use Moo::Role;

requires qw( kind );

has backend => (
    is      => 'lazy',
    builder => sub {
        require Git::Database::Backend::None;
        return Git::Database::Backend::None->new;
    },
    isa => sub {
        die "$_[0] DOES not Git::Database::Role::Backend"
          if !eval { $_[0]->does('Git::Database::Role::Backend') };
    },
);

has digest => (
    is      => 'lazy',
    builder => sub { $_[0]->backend->hash_object( $_[0] ); },
    coerce  => sub { lc $_[0] },
    isa =>
      quote_sub(q{ die "Not a SHA-1 digest" if $_[0] !~ /^[0-9a-f]{40}/; }),
    predicate => 1,
);

has size => (
    is        => 'lazy',
    builder   => sub { length $_[0]->content },
    predicate => 1,
);

has content => (
    is      => 'lazy',
    builder => sub {
        my ( $digest, $backend ) = ( $_[0]->digest, $_[0]->backend );
        my $attr = $backend->get_object_attributes($digest);
        die "$digest not found in $backend" if !$attr;
        return $attr->{content};
    },
    predicate => 1,
);

sub as_string { $_[0]->content; }

1;

__END__

# ABSTRACT: Role for objects from the Git object database

=pod

=head1 SYNOPSIS

    package Git::Database::Object::Blob;

    use Moo;

    with 'Git::Database::Role::Object';

    sub kind { 'blob' }

    1;

=head1 DESCRIPTION

Git::Database::Role::Object provides the generic behaviour for all
L<Git::Database> objects obtained from or stored into the git object
database.

When creating a new object meant to be added to the Git object database,
only the C<content> attribute is actually required. L<Git::Database>
is really the only module that will set all attributes, when it actually
fetches the object data from the Git object database.

Creating a new object with inconsistent C<kind>, C<size>, C<content>
and C<digest> attributes can only end in tears.

=head1 ATTRIBUTES

=head2 repository

The L<Git::Database> repository from which the object comes from
(or will be stored into).

=head2 content

The object's actual content.

=head2 size

The size (in bytes) of the object content.

=head2 digest

The SHA-1 digest of the object, as computed by Git.

=head1 METHODS

=head2 as_string

Return a string representation of the content.

By default, this is the same as C<content()>, but some classes may
override it.

=head1 REQUIRED METHODS

=head2 kind

Returns the object "kind".

In Git, this is one of C<blob>, C<tree>, C<commit>, and C<tag>.

=head1 SEE ALSO

L<Git::Database::Object::Blob>,
L<Git::Database::Object::Tree>,
L<Git::Database::Object::Commit>,
L<Git::Database::Object::Tag>.

=head1 COPYRIGHT

Copyright 2013 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
