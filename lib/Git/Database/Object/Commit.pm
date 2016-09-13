package Git::Database::Object::Commit;

use Moo;

with 'Git::Database::Role::Object';

use Git::Database::Actor;
use DateTime;
use Encode qw( decode );

sub kind {'commit'}

has commit_info => (
    is        => 'lazy',
    required  => 0,
    predicate => 1,
);

sub BUILD {
    my ($self) = @_;
    die "One of 'digest' or 'content' or 'commit_info' is required"
      if !$self->has_digest && !$self->has_content && !$self->has_commit_info;
}

for my $attr (
    qw(
    tree_digest
    author
    authored_time
    committer
    committed_time
    comment
    encoding
    )
    )
{
    no strict 'refs';
    *$attr = sub { $_[0]->commit_info->{$attr} };
}

sub parents_digest { @{ $_[0]->commit_info->{parents_digest} ||= [] }; }

my %method_map = (
    'tree'      => 'tree_digest',
    'parent'    => '@parents_digest',
    'author'    => 'authored_time',
    'committer' => 'committed_time'
);

# assumes commit_info is set
sub _build_content {
    my ($self) = @_;

    return Git::Database::Role::Object::_build_content($self)
      if !$self->has_commit_info;

    my $content .= 'tree ' . $self->tree_digest . "\n";
    $content .= "parent $_\n" for $self->parents_digest;
    $content .= join(
        ' ',
        author => $self->author->ident,
        $self->authored_time->epoch,
        DateTime::TimeZone->offset_as_string( $self->authored_time->offset )
    ) . "\n";
    $content .= join(
        ' ',
        committer => $self->committer->ident,
        $self->committed_time->epoch,
        DateTime::TimeZone->offset_as_string( $self->committed_time->offset )
    ) . "\n";
    $content .= "\n";
    my $comment = $self->comment;
    chomp $comment;
    $content .= "$comment\n";

    return $content;
}

# assumes content is set
sub _build_commit_info {
    my $self = shift;
    my $commit_info = { parents_digest => [] };

    my @lines = split "\n", $self->content;
    my %header;
    while ( my $line = shift @lines ) {
        my ( $key, $value ) = split ' ', $line, 2;
        push @{ $header{$key} }, $value;
    }
    $header{encoding} = ['utf-8'];
    my $encoding = $header{encoding}->[-1];
    for my $key ( keys %header ) {
        for my $value ( @{ $header{$key} } ) {
            $value = decode( $encoding, $value );
            if ( $key eq 'committer' or $key eq 'author' ) {
                my @data = split ' ', $value;
                my ( $email, $epoch, $tz ) = splice( @data, -3 );
                $commit_info->{$key} = Git::Database::Actor->new(
                    name => join( ' ', @data ),
                    email => substr( $email, 1, -1 ),
                );
                $key = $method_map{$key};
                $commit_info->{$key} = DateTime->from_epoch(
                    epoch     => $epoch,
                    time_zone => $tz
                );
            }
            else {
                my $mkey = $method_map{$key} || $key;
                if ( $mkey =~ s/^\@// ) {
                    push @{ $commit_info->{$mkey} }, $value;
                }
                else { $commit_info->{$mkey} = $value; }
            }
        }
    }
    $commit_info->{comment} = decode( $encoding, join "\n", @lines );
    return $commit_info;
}

1;

__END__

=pod

=for Pod::Coverage
  BUILD

=head1 NAME

Git::Database::Object::Commit - A commit object in the Git object database

=head1 SYNOPSIS

    my $r      = Git::Database->new();       # current Git repository
    my $commit = $r->get_object('ef25e8');   # abbreviated digest

    # attributes
    $commit->kind;              # commit
    $commit->digest;            # ef25e81ba86b7df16956c974c8a9c1ff2eca1326
    $commit->tree_digest;       # b52168be5ea341e918a9cbbb76012375170a439f
    $commit->parents_digest;    # []
    ...;                        # etc., see below

=head1 DESCRIPTION

Git::Database::Object::Commit represents a C<commit> object
obtained via L<Git::Database> from a Git object database.

=head1 ATTRIBUTES

=head2 kind

The object kind: C<commit>.

=head2 digest

The SHA-1 digest of the commit object.

=head2 content

The object's actual content.

=head2 size

The size (in bytes) of the object content.

=head2 commit_info

A hash reference containing the all the attributes listed below, as
values for the keys with the same names.

=head2 tree_digest

The SHA-1 digest of the tree object corresponding to the commit.

=head2 parents_digest

An array reference containing the list of SHA-1 digests of the
commit's parents.

=head2 author

A L<Git::Database::Actor> object representing the author of
the commit.

=head2 authored_time

A L<DateTime> object representing the date at which the author
created the patch.

=head2 committer

A L<Git::Database::Actor> object representing the committer of
the commit.

=head2 committed_time

A L<DateTime> object representing the date at which the committer
created the commit.

=head2 comment

The text of the commit message.

=head2 encoding

The encoding of the commit message.

=head1 METHODS

=head2 new()

Create a new Git::Object::Database::Commit object.

One (and only one) of the C<content> or C<commit_info> arguments is
required.

C<commit_info> is a reference to a hash containing the keys listed
above, i.e. C<tree_digest>, C<author>, C<authored_time>, C<committer>,
C<committed_time>, C<comment>, and C<encoding> (optional).

=head1 SEE ALSO

L<Git::Database>,
L<Git::Database::Role::Object>.

=head1 COPYRIGHT

Copyright 2013 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
