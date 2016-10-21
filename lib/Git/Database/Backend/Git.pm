package Git::Database::Backend::Git;

use Sub::Quote;

use Moo;
use namespace::clean;

with
  'Git::Database::Role::Backend',
  ;

has '+store' => (
    isa => quote_sub( q{
        die 'store is not a Git object'
          if !eval { $_[0]->isa('Git') }
    } ),
);

has object_factory => (
    is        => 'lazy',
    init_arg  => undef,
    builder   => sub { [ $_[0]->store->command_bidi_pipe( 'cat-file', '--batch' ) ] },
    predicate => 1,
    clearer   => 1,
);

sub hash_object {
    my ( $self, $object ) = @_;
    my ( $pid, $in, $out, $ctx ) =
      $self->store->command_bidi_pipe( 'hash-object', '-t', $object->kind,
        '--stdin' );
    print {$out} $object->content;
    close $out;
    chomp( my $digest = <$in> );
    $self->store->command_close_bidi_pipe( $pid, $in, undef, $ctx ); # $out closed
    return $digest;
}

1;

__END__

=pod

=head1 NAME

Git::Database::Backend::Git - A Git::Database backend based on Git

=head1 SYNOPSIS

    # get a store
    my $r  = Git->new();

    # let Git::Database produce the backend
    my $db = Git::Database->new( store => $r );

=head1 DESCRIPTION

This backend reads and write data from a Git repository using the
L<Git> Git wrapper.

=head2 Git Database Roles

This backend does the following roles
(check their documentation for a list of supported methods):
L<Git::Database::Role::Backend>.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>

=head1 COPYRIGHT

Copyright 2016 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
