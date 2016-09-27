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
  ;

# the store attribute is a string
# so the auto-detection of the backend in Git::Database can't work

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

1;
