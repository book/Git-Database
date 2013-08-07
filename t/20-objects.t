use strict;
use warnings;
use Test::More;
use Test::Git;

use Git::Simple;

my $t = test_repository();
my $r = Git::Simple->new( work_tree => $t->work_tree );

is( $r->get_object('123456'), undef, '123456 missing' );

# create a blob
my $blob = Git::Simple::Blob->new( repository => $r, content => 'hello' );
isa_ok( $blob, 'Git::Simple::Blob' );
is( $blob->size, 5, 'size' );
is( $blob->digest, 'b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0', 'digest' );

# fetch it back from the git database
my $blob2 = $r->get_object('b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0');
isa_ok( $blob2, 'Git::Simple::Blob' );
is( $blob2->size,    5,                                          'size' );
is( $blob2->digest,  'b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0', 'digest' );
is( $blob2->content, 'hello',                                    'content' );

done_testing;
