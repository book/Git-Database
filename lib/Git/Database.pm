package Git::Database;

use Moo;
use Sub::Quote;

extends 'Git::Repository';

has _object_factory => (
    is  => 'lazy',
    isa => quote_sub(
        q{ die 'Not a Git::Repository::Command' if ! $_[0]->isa('Git::Repository::Command' ) }
    ),
    required => 0,
    predicate => 1,
);

sub _build__object_factory { $_[0]->command( 'cat-file', '--batch' ); }

has _object_checker => (
    is  => 'lazy',
    isa => quote_sub(
        q{ die 'Not a Git::Repository::Command' if ! $_[0]->isa('Git::Repository::Command' ) }
    ),
    required  => 0,
    predicate => 1,
);

sub _build__object_checker { $_[0]->command( 'cat-file', '--batch-check' ); }

use Git::Database::Object::Blob;
use Git::Database::Object::Tree;
use Git::Database::Object::Commit;
use Git::Database::Object::Tag;
my %kind2class = (
    blob   => 'Git::Database::Object::Blob',
    tree   => 'Git::Database::Object::Tree',
    commit => 'Git::Database::Object::Commit',
    tag    => 'Git::Database::Object::Tag',
);

sub get_object {
    my ( $self, $digest ) = @_;
    my $factory = $self->_object_factory;

    # request the object
    print { $factory->stdin } $digest, "\n";

    # process the reply
    my $out = $factory->stdout;
    local $/ = "\012";
    chomp( my $reply = <$out> );
    my ( $sha1, $kind, $size ) = split / /, $reply;

    # object does not exist in the git object database
    return if $kind eq 'missing';

    # read the whole content in memory at once
    my $res = read $out, (my $content), $size;
    if( $res != $size ) {
         $factory->close; # in case the exception is trapped
         die "Read $res/$size of content from git";
    }

    # read the last byte
    $res = read $out, (my $junk), 1;
    if( $res != 1 ) {
         $factory->close; # in case the exception is trapped
         die "Unable to finish reading content from git";
    }

    # careful with utf-8!
    # create a new object with digets, content and size
    return $kind2class{$kind}->new(
        repository => $self,
        size       => $size,
        content    => $content,
        digest     => $sha1
    );
}

sub has_object {
    my ( $self, $digest ) = @_;
    my $checker = $self->_object_checker;

    # request the object
    print { $checker->stdin } $digest, "\n";

    # process the reply
    local $/ = "\012";
    chomp( my $reply = $checker->stdout->getline );
    my ( $sha1, $kind, $size ) = split / /, $reply;

    return wantarray ? ( $sha1, $kind, $size ) : defined $size;
}

sub DEMOLISH {
    my ($self) = @_;
    $self->_object_factory->close if $self->_has_object_factory;
    $self->_object_checker->close if $self->_has_object_checker;
}

1;

__END__

# ABSTRACT: Access to the Git object database

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
