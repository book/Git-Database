package Git::Database::Backend::Git::PurePerl;

use Sub::Quote;

use Moo;
use namespace::clean;

with
  'Git::Database::Role::Backend',
  'Git::Database::Role::ObjectReader',
  'Git::Database::Role::ObjectWriter',
  ;

has '+store' => (
    isa => quote_sub( q{
        die 'store is not a Git::PurePerl object'
          if !eval { $_[0]->isa('Git::PurePerl') }
    } ),
);

sub get_object_meta {
    my ( $self, $digest ) = @_;

    my $attr = $self->get_object_attributes($digest);
    return $attr
      ? ( @{$attr}{qw( digest kind size )} )
      : ( $digest, 'missing', undef );
}

sub get_object_attributes {
    my ( $self, $digest ) = @_;

    # search packs
    for my $pack ( $self->store->packs ) {
        my ( $kind, $size, $content ) = $pack->get_object($digest);
        if ( defined($kind) && defined($size) && defined($content) ) {
            return {
                kind    => $kind,
                digest  => $digest,
                content => $content,
                size    => $size,
            };
        }
    }

    # search loose objects
    my ( $kind, $size, $content ) = $self->store->loose->get_object($digest);
    if ( defined($kind) && defined($size) && defined($content) ) {
        return {
            kind    => $kind,
            digest  => $digest,
            content => $content,
            size    => $size,
        };
    }

    return undef;
}

sub all_digests {
    my ( $self, $kind ) = @_;
    return $self->store->all_sha1s->all if !$kind;
    return map $_->sha1, grep $_->kind eq $kind, $self->store->all_objects->all;
}

sub put_object {
    my ( $self, $object ) = @_;
    my $class = ref $object;

    # temporarily acquire sha1 and raw methods
    require Role::Tiny;
    $self->store->put_object(
        Role::Tiny->apply_roles_to_object(
            $object, 'Git::Database::Role::WithRaw'
        )
    );

    # go back to our former self
    bless $object, $class;

    return $object->digest;
}

1;

__END__

=head1 NAME

Git::Database::Backend::Git::PurePerl - A Git::Database backend based on Git::PurePerl

=head1 SYNOPSIS

    # get a store
    my $r  = Git::PurePerl->new();

    # provide the backend
    my $b  = Git::Database::Backend::Git::PurePerl->new( store => $r );
    my $db = Git::Database->new( backend => $b );

    # let Git::Database figure it out by itself
    my $db = Git::Database->new( store => $r );

=head1 DESCRIPTION

This backend reads data from a Git repository using the
L<Git::PurePerl> Git wrapper.

=head2 Git Database Roles

This backend does the following roles
(check their documentation for a list of supported methods):
L<Git::Database::Role::Backend>,
L<Git::Database::Role::ObjectReader>,
L<Git::Database::Role::ObjectWriter>.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>

=head1 COPYRIGHT

Copyright 2016 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
