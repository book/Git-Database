use strict;
use warnings;
use Test::More;
use Test::Git;

use Git::Simple;

my $t = test_repository();
my $r = Git::Simple->new( work_tree => $t->work_tree );

is( $r->git_dir,   $t->git_dir,   'git_dir' );
is( $r->work_tree, $t->work_tree, 'work_tree' );
is( $r->version,   $t->version,   'version' );

done_testing;
