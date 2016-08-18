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

__END__

=head1 NAME

Git::Database::Backend::None - A minimal backend for Git::Database

=head1 SYNOPSIS

    use Git::Database;
    use Git::Database::Backend::None;

    my $backend = Git::Database::Backend::None->new();

    # the empty tree
    my $tree = Git::Database::Object::Tree->new( content => '' );

    # 4b825dc642cb6eb9a060e54bf8d69288fbee4904
    my $digest = $backend->hash_object( $tree );

=head1 DESCRIPTION

C<Git::Database::Backend::None> is the minimal backend class for
L<Git::Database>.

I can't read or write from a L<store|Git::Database::Tutorial/store>,
because it doesn't have one.

=head1 METHODS

=head2 hash_object

Since it's not connected to a store, this class can't delegate the
L<digest|Git::Database::Role::Object/digest> computation to Git itself. It
therefore provides a Perl implementation for it.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>

=head1 COPYRIGHT

Copyright 2016 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
