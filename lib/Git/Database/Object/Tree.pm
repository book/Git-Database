package Git::Database::Object::Tree;

use Moo;

with 'Git::Database::Role::Object';

use Git::Database::DirectoryEntry;

sub kind {'tree'}

has directory_entries => (
    is        => 'rwp',
    required  => 0,
    predicate => 1,
    lazy      => 1,
    builder   => 1,
);

# ensure at least one but not both content or directory_entries is defined
sub BUILD {
    my ($self) = @_;
    die "At least one of 'content' or 'directory_entries' must be defined"
        if !$self->has_content && !$self->has_directory_entries;
    die "At most one of 'content' and 'directory_entries' can be defined"
        if $self->has_content && $self->has_directory_entries;

    # sort directory entries
    $self->_set_directory_entries(
        [   sort { $a->filename cmp $b->filename }
                @{ $self->directory_entries }
        ]
    ) if $self->has_directory_entries;
}

# assumes directory_entries is set
sub _build_content {
    return join '', map $_->as_content, @{ $_[0]->directory_entries };
}

# assumes content is set
sub _build_directory_entries {
    my $self    = shift;
    my $content = $self->content;
    return [] unless $content;

    my @directory_entries;
    while ($content) {
        my $space_index = index( $content, ' ' );
        my $mode = substr( $content, 0, $space_index );
        $content = substr( $content, $space_index + 1 );
        my $null_index = index( $content, "\0" );
        my $filename = substr( $content, 0, $null_index );
        $content = substr( $content, $null_index + 1 );
        my $digest = unpack( 'H*', substr( $content, 0, 20 ) );
        $content = substr( $content, 20 );
        push @directory_entries,
            Git::Database::DirectoryEntry->new(
            mode     => $mode,
            filename => $filename,
            digest   => $digest,
            );
    }
    return \@directory_entries;
}

sub as_string {
    return join '', map $_->as_string, @{ $_[0]->directory_entries };
}

1;
