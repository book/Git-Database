package Git::Database::Role::Object;

use Moo::Role;
use Sub::Quote;

requires qw( kind );

has repository => (
    is       => 'ro',
    required => 1,
);

has digest => (
    is  => 'lazy',
    isa => quote_sub(
        q{ die "Not a SHA-1 digest" unless $_[0] =~ /^[0-9a-f]{40}/; }),
);

# size in bytes
has size => (
    is      => 'lazy',
    default => sub { length $_[0]->content },
);

has content => (
    is => 'lazy',
    predicate => 1,
);

# to compute the digest of a new object, save it in the object database
sub _build_digest {
    my ($self) = @_;
    return
        scalar $self->repository->run( 'hash-object', '-t', $self->kind,
        '--stdin', '-w', { input => $self->content } );
}

sub as_string { $_[0]->content; }

1;

__END__

# ABSTRACT: Role for objects from the Git object database

=pod

=head1 SYNOPSIS

    package Git::Database::Blob;

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

L<Git::Database::Blob>

=head1 COPYRIGHT

Copyright 2013 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
