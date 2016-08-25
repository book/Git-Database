package Git::Database::Backend::Git::Repository;

use Sub::Quote;

use Moo;
use namespace::clean;

with
  'Git::Database::Role::Backend',
  'Git::Database::Role::ObjectReader',
  ;

has '+store' => (
    isa => quote_sub( q{
        die 'store is not a Git::Repository object'
          if !eval { $_[0]->isa('Git::Repository') }
        # die version check
    } ),
);

has object_factory => (
    is        => 'lazy',
    init_arg  => undef,
    builder   => sub { $_[0]->store->command( 'cat-file', '--batch' ); },
    predicate => 1,
    clearer   => 1,
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

sub get_object_meta {
    my ( $self, $digest ) = @_;
    my $checker = $self->object_checker;

    # request the object
    print { $checker->stdin } $digest, "\n";

    # process the reply
    local $/ = "\012";
    chomp( my $reply = $checker->stdout->getline );

    # protect against weird cases like if $digest contains a space
    my @parts = split / /, $reply;
    return ( $digest, 'missing', undef ) if $parts[-1] eq 'missing';

    my ( $kind, $size ) = splice @parts, -2;
    return join( ' ', @parts ), $kind, $size;
}

sub get_object_attributes {
    my ( $self, $digest ) = @_;
    my $factory = $self->object_factory;

    # request the object
    print { $factory->stdin } $digest, "\n";

    # process the reply
    my $out = $factory->stdout;
    local $/ = "\012";
    chomp( my $reply = <$out> );

    # protect against weird cases like if $sha1 contains a space
    my ( $sha1, $kind, $size ) = my @parts = split / /, $reply;

    # object does not exist in the git object database
    return if $parts[-1] eq 'missing';

    # read the whole content in memory at once
    my $res = read $out, (my $content), $size;
    if( $res != $size ) {
         $factory->close; # in case the exception is trapped
         $self->clear_object_factory;
         die "Read $res/$size of content from git";
    }

    # read the last byte
    $res = read $out, (my $junk), 1;
    if( $res != 1 ) {
         $factory->close; # in case the exception is trapped
         $self->clear_object_factory;
         die "Unable to finish reading content from git";
    }

    # careful with utf-8!
    # create a new hash with kind, digest, content and size
    return {
        kind       => $kind,
        size       => $size,
        content    => $content,
        digest     => $sha1
    };
}

sub all_digests {
    my ( $self, $kind ) = @_;
    my $re = $kind ? qr/ \Q$kind\E / : qr/ /;

    return map +( split / / )[0],
      grep /$re/,
      $self->store->run(qw( cat-file --batch-check --batch-all-objects ));
}

sub DEMOLISH {
    my ( $self, $in_global_destruction ) = @_;
    return if $in_global_destruction;    # why bother?

    $self->object_factory->close if $self->has_object_factory;
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
