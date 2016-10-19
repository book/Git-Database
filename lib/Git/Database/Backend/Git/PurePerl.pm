package Git::Database::Backend::Git::PurePerl;

use Sub::Quote;
use Path::Class qw( file );    # used by Git::PurePerl

use Git::Database::Object::Raw;

use Moo;
use namespace::clean;

with
  'Git::Database::Role::Backend',
  'Git::Database::Role::ObjectReader',
  'Git::Database::Role::ObjectWriter',
  'Git::Database::Role::RefReader',
  'Git::Database::Role::ExpandAbbrev',
  ;

has '+store' => (
    isa => quote_sub( q{
        die 'store is not a Git::PurePerl object'
          if !eval { $_[0]->isa('Git::PurePerl') }
    } ),
);

# Git::Database::Role::ObjectReader
sub get_object_attributes {
    my ( $self, $digest ) = @_;

    # expand abbreviated digests
    $digest = $self->expand_abbrev($digest)
      or return undef
      if $digest !~ /^[0-9a-f]{40}$/;

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

# Git::Database::Role::ObjectWriter
sub put_object {
    my ( $self, $object ) = @_;
    $self->store->loose->put_object( Git::Database::Object::Raw->new($object) );
    return $object->digest;
}

# Git::Database::Role::RefReader
sub refs {
    my $store = $_[0]->store;
    my %refs = ( HEAD => $store->ref_sha1('HEAD') );
    @refs{ $store->ref_names } = $store->refs_sha1;

    # get back to packed-refs to pick the primary target of the refs,
    # since Git::PurePerl's ref_sha1 peels everything to reach the commit
    if ( -f ( my $packed_refs = file( $store->gitdir, 'packed-refs' ) ) ) {
        for my $line ( $packed_refs->slurp( chomp => 1 ) ) {
            next if $line =~ /^[#^]/;
            my ( $sha1, $name ) = split ' ', $line;
            $refs{$name} = $sha1;
        }
    }

    return \%refs;
}

1;

__END__

=pod

=for Pod::Coverage
  hash_object
  get_object_attributes
  get_object_meta
  all_digests
  put_object
  refs

=head1 NAME

Git::Database::Backend::Git::PurePerl - A Git::Database backend based on Git::PurePerl

=head1 SYNOPSIS

    # get a store
    my $r  = Git::PurePerl->new();

    # let Git::Database produce the backend
    my $db = Git::Database->new( store => $r );

=head1 DESCRIPTION

This backend reads data from a Git repository using the
L<Git::PurePerl> Git wrapper.

=head2 Git Database Roles

This backend does the following roles
(check their documentation for a list of supported methods):
L<Git::Database::Role::Backend>,
L<Git::Database::Role::ObjectReader>,
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
