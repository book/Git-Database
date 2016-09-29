package Git::Database::Backend::Git::Sub;

use Cwd qw( cwd );
use Git::Sub qw(
  hash_object
);

use Moo;
use namespace::clean;

with
  'Git::Database::Role::Backend',
  'Git::Database::Role::ObjectReader',
  'Git::Database::Role::ObjectWriter',
  'Git::Database::Role::RefReader',
  ;

# the store attribute is a directory name
# or an object representing a directory
# (e.g. Path::Class, Path::Tiny, File::Fu)

# Git::Database::Role::Backend
sub hash_object {
    my ( $self, $object ) = @_;
    my $home = cwd();
    my $dir  = $self->store;
    chdir $dir or die "Can't chdir to $dir: $!";
    my $hash = git::hash_object
      '-t'      => $object->kind,
      '--stdin' => \$object->content;
    chdir $home or die "Can't chdir to $home: $!";
    return $hash;
}

# Git::Database::Role::ObjectReader
sub get_object_meta {
    my ( $self, $digest ) = @_;
    my $home = cwd();
    my $dir  = $self->store;
    chdir $dir or die "Can't chdir to $dir: $!";
    my $meta = git::cat_file
      '--batch-check' => \"$digest\n";
    chdir $home or die "Can't chdir to $home: $!";

    # protect against weird cases like if $digest contains a space
    my @parts = split / /, $meta;
    return ( $digest, 'missing', undef ) if $parts[-1] eq 'missing';

    my ( $kind, $size ) = splice @parts, -2;
    return join( ' ', @parts ), $kind, $size;
}

sub get_object_attributes {
    my ( $self, $digest ) = @_;
    my $home = cwd();
    my $dir  = $self->store;
    chdir $dir or die "Can't chdir to $dir: $!";

    my $out = do {
        local $/;
        git::cat_file '--batch' => \"$digest\n";
    };
    chdir $home or die "Can't chdir to $home: $!";

    my ( $meta, $content ) = split "\n", $out, 2;

    # protect against weird cases like if $digest contains a space
    my ( $sha1, $kind, $size ) = my @parts = split / /, $meta;

    # object does not exist in the git object database
    return if $parts[-1] eq 'missing';

    return {
        kind       => $kind,
        size       => $size,
        content    => substr( $content, 0, $size ),
        digest     => $sha1
    };
}

sub all_digests {
    my ( $self, $kind ) = @_;
    my $home = cwd();
    my $dir  = $self->store;
    chdir $dir or die "Can't chdir to $dir: $!";

    local $_;    # Git::Sub seems to clobber $_ in list context
    my $re = $kind ? qr/ \Q$kind\E / : qr/ /;
    my @digests = map +( split / / )[0],
      grep /$re/,
      git::cat_file '--batch-check', '--batch-all-objects';

    chdir $home or die "Can't chdir to $home: $!";
    return @digests;
}

# Git::Database::Role::ObjectWriter
sub put_object {
    my ( $self, $object ) = @_;
    my $home = cwd();
    my $dir  = $self->store;
    chdir $dir or die "Can't chdir to $dir: $!";
    my $hash = git::hash_object
      '-w',
      '-t'      => $object->kind,
      '--stdin' => \$object->content;
    chdir $home or die "Can't chdir to $home: $!";
    return $hash;
}

# Git::Database::Role::RefReader
sub refs {
    my ($self) = @_;
    my $home   = cwd();
    my $dir    = $self->store;
    chdir $dir or die "Can't chdir to $dir: $!";
    local $_;    # Git::Sub seems to clobber $_ in list context
    my %digest = reverse map +( split / / ),
      git::show_ref '--head';
    chdir $home or die "Can't chdir to $home: $!";
    return \%digest;
}

1;

__END__

=pod

=for Pod::Coverage
  has_object_checker
  has_object_factory
  DEMOLISH
  hash_object
  get_object_attributes
  get_object_meta
  all_digests
  put_object
  refs

=head1 NAME

Git::Database::Backend::Git::Sub - A Git::Database backend based on Git::Sub

=head1 SYNOPSIS

    # Git::Sub does not offer an OO interface
    $dir = 'path/to/some/git/repository/';

    # let Git::Database figure it out by itself
    my $db = Git::Database->new( store => $dir );

=head1 DESCRIPTION

This backend reads and write data from a Git repository using the
L<Git::Sub> Git wrapper.

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
