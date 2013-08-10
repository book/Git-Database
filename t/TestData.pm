use strict;
use warnings;
use DateTime;

use Git::Database::DirectoryEntry;

# test data
our %objects = (
    blob => [
        {   desc    => 'empty blob',
            content => '',
            digest  => 'e69de29bb2d1d6434b8b29ae775ad8c2e48c5391',
        },
        {   desc    => 'hello blob',
            content => 'hello',
            digest  => 'b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0',
        },
    ],
    tree => [
        {   desc              => 'empty tree',
            directory_entries => [],
            content           => '',
            digest            => '4b825dc642cb6eb9a060e54bf8d69288fbee4904',
        },
        {   desc              => 'hello tree',
            directory_entries => [
                Git::Database::DirectoryEntry->new(
                    mode     => '100644',
                    filename => 'hello',
                    digest   => 'b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0'
                )
            ],
            content =>
                "100644 hello\0\266\374Lb\13g\331_\225:\\\34\0220\252\253]\265\241\260",
            string =>
                "100644 blob b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0\thello\n",
            digest => 'b52168be5ea341e918a9cbbb76012375170a439f',
        },
        {   desc              => 'tree with subtree',
            directory_entries => [
                Git::Database::DirectoryEntry->new(
                    mode     => '100644',
                    filename => 'hello',
                    digest   => 'b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0'
                ),
                Git::Database::DirectoryEntry->new(
                    mode     => '40000',
                    filename => 'subdir',
                    digest   => 'b52168be5ea341e918a9cbbb76012375170a439f'
                ),
            ],
            content =>
                "100644 hello\0\266\374Lb\13g\331_\225:\\\34\0220\252\253]\265\241\26040000 subdir\0\265!h\276^\243A\351\30\251\313\273v\1#u\27\nC\237",
            string =>
                "100644 blob b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0\thello\n040000 tree b52168be5ea341e918a9cbbb76012375170a439f\tsubdir\n",
            digest => '71ff52fcd190c0a900fffad2ecf2f678554602b6',
        },
        {   desc => 'tree with subtree (unsorted directory_entries)',
            directory_entries => [
                Git::Database::DirectoryEntry->new(
                    mode     => '40000',
                    filename => 'subdir',
                    digest   => 'b52168be5ea341e918a9cbbb76012375170a439f'
                ),
                Git::Database::DirectoryEntry->new(
                    mode     => '100644',
                    filename => 'hello',
                    digest   => 'b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0'
                ),
            ],
            content =>
                "100644 hello\0\266\374Lb\13g\331_\225:\\\34\0220\252\253]\265\241\26040000 subdir\0\265!h\276^\243A\351\30\251\313\273v\1#u\27\nC\237",
            string =>
                "100644 blob b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0\thello\n040000 tree b52168be5ea341e918a9cbbb76012375170a439f\tsubdir\n",
            digest => '71ff52fcd190c0a900fffad2ecf2f678554602b6',
        },
    ],
);

# add extra information
for my $kind ( keys %objects ) {
    for my $object ( @{ $objects{$kind} } ) {
        $object->{kind} = $kind;
        $object->{sha1} = $object->{digest};
        $object->{size} = length $object->{content};
        $object->{string} ||= $object->{content};
    }
}

# test routines
sub test_blob {
    my ( $blob, $test ) = @_;

    # read content in memory early
    isa_ok( $blob, 'Git::Database::Object::Blob' );
    is( $blob->kind,      $test->{kind},    'kind' );
    is( $blob->content,   $test->{content}, 'content' );
    is( $blob->size,      $test->{size},    'size' );
    is( $blob->digest,    $test->{digest},  'digest' );
    is( $blob->as_string, $test->{string},  'as_string' );
}

sub test_tree {
    my ( $tree, $test ) = @_;

    isa_ok( $tree, 'Git::Database::Object::Tree' );
    is( $tree->kind,    $test->{kind},    'kind' );
    is( $tree->content, $test->{content}, 'content' );
    is( $tree->size,    $test->{size},    'size' );
    is( $tree->digest,  $test->{digest},  'digest' );
    is_deeply(
        $tree->directory_entries,
        [   sort { $a->filename cmp $b->filename }
                @{ $test->{directory_entries} }
        ],
        'directory_entries'
    );
    is( $tree->as_string, $test->{string}, 'as_string' );
}

1;
