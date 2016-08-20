package Git::Database;

use Sub::Quote;
use Module::Runtime qw( use_module );

use Moo;
use namespace::clean;

has backend => (
    is       => 'ro',
    required => 1,
    default  => sub { use_module('Git::Database::Backend::None')->new; },
    isa      => sub {
        die "$_[0] DOES not Git::Database::Role::Backend"
          if !eval { $_[0]->does('Git::Database::Role::Backend') };
    },
    handles => [
        'hash_object',        # Git::Database::Role::Backend
        'get_object_meta',    # Git::Database::Role::ObjectReader
        'get_object',
        'get_hashes',
        'has_object',
        'put_object',         # Git::Database::Role::ObjectWriter
        'resolve_ref',        # Git::Database::Role::RefReader
        'get_refs',
        'put_ref',            # Git::Database::Role::RefWriter
        'delete_ref'
    ],
);

1;

__END__

# ABSTRACT: Access to the Git object database

=for Pod::Coverage::TrustPod DEMOLISH

=head1 SYNOPSIS

    my $r = Git::Database->new( work_tree => $dir );

=head1 DESCRIPTION

Git::Database is a L<Moo>-based subclass of L<Git::Repository> that
provides access from Perl to the object database stored in a Git
repository.

=head1 ATTRIBUTES

The public attributes are all provided by L<Git::Repository>.

=head1 METHODS

=head2 has_object( $digest )

Given a digest value (possibly abbreviated), C<has_object> returns (in
scalar context) a a boolean indicating if the corresponding object is
in the database. In list context and if the object is in the database,
it returns the complete digest, the object type and its size. Otherwise
it returns the requested C<$digest>, the string C<missing> and the
C<undef> value.

Example:

    # assuming 4b825dc642cb6eb9a060e54bf8d69288fbee4904 (the empty tree)
    # is in the database and 123456 is not

    # scalar context
    $bool = $r->has_object('4b825dc642cb6eb9a060e54bf8d69288fbee4904'); # true
    $bool = $r->has_object('4b825d');    # also true
    $bool = $r->has_object('123456');    # false

    # list context
    # ( '4b825dc642cb6eb9a060e54bf8d69288fbee4904', 'tree', 0 );
    ( $digest, $kind, $size ) = $r->has_object('4b825d');

    # ( '123456', 'missing, undef )
    ( $digest, $kind, $size ) = $r->has_object('123456');

=head2 get_object( $digest )

Given a digest value (possibly abbreviated), C<get_object>
returns the full object extracted from the Git database (one of
L<Git::Database::Object::Blob>, L<Git::Database::Object::Tree>,
L<Git::Database::Object::Commit>, or L<Git::Database::Object::Tag>).

Returns C<undef> if the object is not in the Git database.

Example:

    # a Git::Database::Object::Tree representing the empty tree
    $tree = $r->get_object('4b825dc642cb6eb9a060e54bf8d69288fbee4904');
    $tree = $r->get_object('4b825d');    # idem

    # undef
    $tree = $r->get_object('123456');

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Git::Database

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Git-Database>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Git-Database>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Git-Database>

=item * Search CPAN

L<http://search.cpan.org/dist/Git-Database>

=item * MetaCPAN

L<http://metacpan.org/release/Git-Database>

=back

=head1 COPYRIGHT

Copyright 2013 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
