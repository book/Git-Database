use strict;
use warnings;
use Test::More;
use Test::Git;

use Git::Simple;

my $t = test_repository();
my $r = Git::Simple->new( work_tree => $t->work_tree );

is( $r->get_object( '123456' ), undef, '123456 missing' );

done_testing;
