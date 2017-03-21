package Git::Database::Backend::Git::Raw::Repository;

use Git::Raw;
use Sub::Quote;
use Moo;
use namespace::clean;

with
  'Git::Database::Role::Backend',
  'Git::Database::Role::RefReader',
  'Git::Database::Role::RefWriter',
  ;

has '+store' => (
    isa => quote_sub( q{
        die 'store is not a Git::Raw::Repository object'
          if !eval { $_[0]->isa('Git::Raw::Repository') }
    } ),
);

# Git::Database::Role::ObjectReader
sub get_object_attributes {
    my ( $self, $digest ) = @_;
    my $object = eval { $self->store->lookup($digest) }
      or $@ and do { ( my $at = $@ ) =~ s/ at .* line .*$//; warn "$at\n" };
    return undef if !defined $object;

    require DateTime;
    require Git::Database::Actor;
    require Git::Database::DirectoryEntry;

    my $kind = lc +( split /::/, ref $object )[-1];
    if ( $kind eq 'tree' ) {
        return {
            kind              => $kind,
            digest            => $object->id,
            directory_entries => [
                map Git::Database::DirectoryEntry->new(
                    mode     => sprintf( '%o', $_->file_mode ),
                    filename => $_->name,
                    digest   => $_->id,
                ),
                $object->entries
            ],
        };
    }
    elsif ( $kind eq 'blob' ) {
        return {
            kind    => $kind,
            size    => $object->size,
            content => $object->content,
            digest  => $object->id,
        };
    }
    elsif ( $kind eq 'commit' ) {
        return {
            kind        => $kind,
            digest      => $object->id,
            commit_info => {
                tree_digest    => $object->tree->id,
                parents_digest => [ map $_->id, $object->parents ],
                author         => Git::Database::Actor->new(
                    name  => $object->author->name,
                    email => $object->author->email,
                ),
                author_date => DateTime->from_epoch(
                    epoch     => $object->author->time,
                    time_zone => DateTime::TimeZone->offset_as_string(
                        $object->author->offset * 60
                    ),
                ),
                committer => Git::Database::Actor->new(
                    name  => $object->committer->name,
                    email => $object->committer->email,
                ),
                committer_date => DateTime->from_epoch(
                    epoch     => $object->committer->time,
                    time_zone => DateTime::TimeZone->offset_as_string(
                        $object->committer->offset * 60
                    ),
                ),
                comment => map( { chomp; $_ } $object->message ),
                encoding => 'utf-8',
            },
        };
    }
    elsif ( $kind eq 'tag' ) {
        return {
            kind     => $kind,
            digest   => $object->id,
            tag_info => {
                object => $object->target->id,
                type   => lc +( split /::/, ref $object->target )[-1],
                tag    => $object->name,
                tagger => Git::Database::Actor->new(
                    name  => $object->tagger->name,
                    email => $object->tagger->email,
                ),
                tagger_date => DateTime->from_epoch(
                    epoch     => $object->tagger->time,
                    time_zone => DateTime::TimeZone->offset_as_string(
                        $object->tagger->offset * 60
                    ),
                ),
                comment => map( { chomp; $_ } $object->message ),
            }
        };
    }
    else { die "Unknown object kind: $kind" }
}

# Git::Database::Role::RefReader
sub refs {
    my ($self) = @_;
    return {
        map +( $_->name => $self->_deref($_->target)->id ),
        # we include HEAD explicitly to mimic `show-ref --head`
        Git::Raw::Reference->lookup('HEAD', $self->store), $self->store->refs
    };
}

sub _deref {
    my ($self, $maybe_ref) = @_;
    return $maybe_ref->isa('Git::Raw::Reference')
      ? $self->_deref($maybe_ref->target)
      : $maybe_ref;
}

# Git::Database::Role::RefWriter
sub put_ref {
    my ($self, $refname, $digest) = @_;
    Git::Raw::Reference->create(
      $refname, $self->store, $self->store->lookup($digest));
}

sub delete_ref {
    my ($self, $refname) = @_;
    Git::Raw::Reference->lookup($refname, $self->store)->delete;
}

1;

__END__

=pod

=for Pod::Coverage
  refs
  _deref
  put_ref
  delete_ref

=head1 NAME

Git::Database::Backend::Git::Raw::Repository - A Git::Database backend based on Git::Raw

=head1 SYNOPSIS

    # get a store
    my $r  = Git::Raw::Repository->open('path/to/some/git/repository');

    # let Git::Database produce the backend
    my $db = Git::Database->new( store => $r );

=head1 DESCRIPTION

This backend reads data from a Git repository using the L<Git::Raw>
bindings to the L<libgit2|http://libgit2.github.com> library.

=head2 Git Database Roles

This backend does the following roles
(check their documentation for a list of supported methods):
L<Git::Database::Role::Backend>,
L<Git::Database::Role::RefReader>.
L<Git::Database::Role::RefWriter>.

=head1 AUTHOR

Sergey Romanov <sromanov@cpan.org>

=head1 COPYRIGHT

Copyright 2017 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
