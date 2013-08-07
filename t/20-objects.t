use strict;
use warnings;
use Test::More;
use Test::Git;

use Git::Simple;

has_git();

my $t = test_repository();
my $r = Git::Simple->new( work_tree => $t->work_tree );

# some digests
my $miss = '123456';
my $SHA1 = 'b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0';
my $sha1 = substr( $SHA1, 0, 6 );

# missing
for my $digest ( $miss, $SHA1, $sha1 ) {

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
}

# create a blob
my $blob = Git::Simple::Blob->new( repository => $r, content => 'hello' );
isa_ok( $blob, 'Git::Simple::Blob' );
is( $blob->size,      5,       'size' );
is( $blob->content,   'hello', 'content' );
is( $blob->as_string, 'hello', 'content' );

# so long as we don't request its digest, it's not saved
ok( !$r->has_object($SHA1), "$SHA1 not saved yet" );
ok( !$r->has_object($sha1), "$sha1 not saved yet" );

# compute the digest by saving the object to the git database
is( $blob->digest, $SHA1, 'digest' );

# the object is now in the object database
ok( $r->has_object($SHA1), "$SHA1 now saved" );
is_deeply(
    [ $r->has_object($SHA1) ],
    [ $SHA1, "blob", 5 ],
    "has_object($SHA1): blob (list context)"
);

# using the shortened digest
ok( $r->has_object($sha1), "$sha1 now saved" );
is_deeply(
    [ $r->has_object($sha1) ],
    [ $SHA1, "blob", 5 ],
    "has_object($sha1): blob (list context)"
);

# fetch the object back from the git database
$blob = $r->get_object($sha1);
isa_ok( $blob, 'Git::Simple::Blob' );
is( $blob->size,      5,       'size' );
is( $blob->digest,    $SHA1,   'digest' );
is( $blob->content,   'hello', 'content' );
is( $blob->as_string, 'hello', 'content' );

done_testing;
