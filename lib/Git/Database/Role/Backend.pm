package Git::Database::Role::Backend;

use Git::Database::Object::Blob;
use Git::Database::Object::Tree;
use Git::Database::Object::Commit;
use Git::Database::Object::Tag;

use Moo::Role;

has store => (
    is        => 'ro',
    required  => 1,
    predicate => 1,
);

sub hash_object {
    my ( $self, $object ) = @_;
    return Digest::SHA->new->add( $object->kind, ' ', $object->size, "\0",
        $object->content )->hexdigest;
}

my %kind2class = (
    blob   => 'Git::Database::Object::Blob',
    tree   => 'Git::Database::Object::Tree',
    commit => 'Git::Database::Object::Commit',
    tag    => 'Git::Database::Object::Tag',
);

sub create_object {
    my $self  = shift;
    my $class = ref $self;

    # inspired by Moo::Object::BUILDARGS
    my %attr = @_ == 1
      ? defined $_[0] && ref $_[0] eq 'HASH'
          ? %{ $_[0] }
          : die "Single parameters to create_object() must be a HASH ref"
          . " data => " . $_[0] . "\n"
      : @_ % 2
          ? die "The create_object() method for $class expects a hash reference"
          . " or a key/value list. You passed an odd number of arguments\n"
          : @_;

    return $kind2class{ $attr{kind} }->new( %attr, backend => $self );
}

1;

__END__

=pod

=for Pod::Coverage
  has_store

=head1 NAME

Git::Database::Role::Backend - Abstract role for a Git database backend

=head1 SYNOPSIS

    package MyGitBackend;

    use Moo;
    use namespace::clean;

    with 'Git::Database::Role::Backend';

    1;

=head1 DESCRIPTION

The C<Git::Database::Role::Backend> role encapsulate code for the user-facing
store objects. To be usable as a L<backend|Git::Repository::Tutorial/backend>,
a class must at least do this role.

=head1 REQUIRED ATTRIBUTES

=head2 store

The L<store|Git::Database::Tutorial/store> that will store and retrieve
data from the Git repository.

There is a C<has_store> predicate method for this attribute.

=head1 METHODS

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

The role provides a Perl implementation for it, but most backends will
want to override it for performance reasons.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>

=head1 COPYRIGHT

Copyright 2016 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
