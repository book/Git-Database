package Git::Database::Backend::Git::Repository;

use Sub::Quote;

use Moo;
use namespace::clean;

with
  'Git::Database::Role::Backend',
  ;

has '+store' => (
    isa => quote_sub( q{
        die 'store is not a Git::Repository object'
          if !eval { $_[0]->isa('Git::Repository') }
        # die version check
    } ),
);

has object_checker => (
    is        => 'lazy',
    init_arg  => undef,
    builder   => sub { $_[0]->store->command( 'cat-file', '--batch-check' ); },
    predicate => 1,
    clearer   => 1,
);

sub hash_object {
    my ($self, $object ) = @_;
    return scalar $self->store->run( 'hash-object', '-t', $object->kind,
        '--stdin', { input => $object->content } );
}

sub DEMOLISH {
    my ( $self, $in_global_destruction ) = @_;
    return if $in_global_destruction;    # why bother?

    $self->object_checker->close if $self->has_object_checker;
}

1;

__END__

=head1 NAME

Git::Database::Backend::Git::Repository - A Git::Database backend based on Git::Repository

=head1 SYNOPSIS

    # get a store
    my $r  = Git::Repository->new();

    # provide the backend
    my $b  = Git::Database::Backend::Git::Repository->new( store => $r );
    my $db = Git::Database->new( backend => $b );

    # let Git::Database figure it out by itself
    my $db = Git::Database->new( store => $r );

=head1 DESCRIPTION

This backend reads and write data from a Git repository using the
L<Git::Repository> Git wrapper.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>

=head1 COPYRIGHT

Copyright 2013-2016 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
