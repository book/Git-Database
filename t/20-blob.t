use strict;
use warnings;
use Test::More;
use Test::Git;

use Git::Database;
use t::TestData;

has_git();

my $t = test_repository();
my $r = Git::Database->new( work_tree => $t->work_tree );

our %objects;

for my $test ( @{ $objects{blob} } ) {
    my ( $kind, $digest, $size ) = @{$test}{qw( kind digest size )};

    diag $test->{desc};

    # object is not in the object database yet
    # scalar context
    ok( !$r->has_object($digest), "has_object( $digest ): missing" );

    # list context
    is_deeply(
        [ $r->has_object($digest) ],
        [ $digest, 'missing', undef ],
        "has_object( $digest ): missing (list context)"
    );

    # fetching the object
    is( $r->get_object($digest), undef, "get_object( $digest ): missing" );

    # this test computes the digest
    my $blob = Git::Database::Blob->new(
        content    => $test->{content},
        repository => $r
    );
    test_blob( $blob, $test );

    # the object is now in the object database
    ok( $r->has_object($digest), "$digest now saved" );
    is_deeply(
        [ $r->has_object($digest) ],
        [ $digest, $kind, $size ],
        "has_object($digest): blob (list context)"
    );

    # using the shortened digest
    my $short = substr( $digest, 0, 6 );
    ok( $r->has_object($short), "$short now saved" );
    is_deeply(
        [ $r->has_object($short) ],
        [ $digest, $kind, $size ],
        "has_object($short): blob (list context)"
    );

    # fetch the object back from the git database
    $blob = $r->get_object($digest);
    test_blob( $blob, $test );
}

done_testing;
