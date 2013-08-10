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
    isa_ok( $blob, 'Git::Database::Blob' );
    is( $blob->kind,      $test->{kind},    'kind' );
    is( $blob->content,   $test->{content}, 'content' );
    is( $blob->size,      $test->{size},    'size' );
    is( $blob->digest,    $test->{digest},  'digest' );
    is( $blob->as_string, $test->{string},  'as_string' );
}

1;
