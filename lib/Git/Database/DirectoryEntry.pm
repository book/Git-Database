package Git::Database::DirectoryEntry;

use Moo;
use Sub::Quote;

# Git only uses the following (octal) modes:
# - 040000 for subdirectory (tree)
# - 100644 for file (blob)
# - 100755 for executable (blob)
# - 120000 for a blob that specifies the path of a symlink
# - 160000 for submodule (commit)
#
# See also: cache.h in git.git
has mode => (
    is       => 'ro',
    required => 1,
);

has filename => (
    is => 'ro',
);

has digest => (
    is  => 'ro',
    isa => quote_sub(
        q{ die "Not a SHA-1 digest" unless $_[0] =~ /^[0-9a-f]{40}/; }),
    required => 1,
);

sub as_content {
    my ($self) = @_;
    return
          $self->mode . ' '
        . $self->filename . "\0"
        . pack( 'H*', $self->digest );
}

sub as_string {
    my ($self) = @_;
    my $mode = oct( '0' . $self->mode );
    return sprintf "%06o %s %s\t%s\n", $mode,
        $mode & 0100000 ? 'blob' : 'tree',
        $self->digest, $self->filename;
}

# some helper methods
sub is_tree       { !( oct( '0' . $_[0]->mode ) & 0100000 ) }
sub is_blob       { !!( oct( '0' . $_[0]->mode ) & 0100000 ) }
sub is_executable { !!( oct( '0' . $_[0]->mode ) & 0100 ) }
sub is_link       { $_[0]->mode eq '120000' }
sub is_submodule  { $_[0]->mode eq '160000' }

1;
