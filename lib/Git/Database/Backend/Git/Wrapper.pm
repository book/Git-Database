package Git::Database::Backend::Git::Wrapper;

use Sub::Quote;

use Moo;
use namespace::clean;

with
  'Git::Database::Role::Backend',
  'Git::Database::Role::ObjectWriter',
  'Git::Database::Role::RefReader',
  'Git::Database::Role::RefWriter',
  ;

has '+store' => (
    isa => quote_sub( q{
        die 'store is not a Git::Wrapper object'
          if !eval { $_[0]->isa('Git::Wrapper') }
    } ),
);

# Git::Database::Role::Backend
sub hash_object {
    my ($self, $object ) = @_;
    my ($hash) = $self->store->hash_object( '-t', $object->kind,
        { stdin => 1, -STDIN => $object->content } );
    return $hash;
}

# Git::Database::Role::ObjectWriter
sub put_object {
    my ( $self, $object ) = @_;
    my ($hash) = $self->store->hash_object( '-t', $object->kind, '-w',
        { stdin => 1, -STDIN => $object->content } );
    return $hash;
}

# Git::Database::Role::RefReader
sub refs {
    my ($self) = @_;
    return {
        reverse map +( split / / ),
        $self->store->show_ref( { head => 1 } )
    };
}

# Git::Database::Role::RefWriter
sub put_ref {
    my ($self, $refname, $digest ) = @_;
    $self->store->update_ref( $refname, $digest );
}

sub delete_ref {
    my ($self, $refname ) = @_;
    $self->store->update_ref( '-d', $refname );
}

1;

__END__
=pod

=encoding UTF-8

=for Pod::Coverage
  hash_object
  put_object
  refs
  put_ref
  delete_ref

=head1 NAME

Git::Database::Backend::Git::Wrapper - A Git::Database backend based on Git::Wrapper

=head1 SYNOPSIS

    # get a store
    my $r  = Git::Wrapper->new('/var/foo');

    # let Git::Database produce the backend
    my $db = Git::Database->new( store => $r );

=head1 DESCRIPTION

This backend reads and write data from a Git repository using the
L<Git::Wrapper> module.

=head2 Git Database Roles

This backend does the following roles
(check their documentation for a list of supported methods):
L<Git::Database::Role::Backend>,
L<Git::Database::Role::ObjectWriter>,
L<Git::Database::Role::RefReader>.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>

=head1 COPYRIGHT

Copyright 2016 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
