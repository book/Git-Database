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

for my $test ( @{ $objects{commit} } ) {
    for my $args (
        [ content     => $test->{content} ],
        [ commit_info => $test->{commit_info} ],
        )
    {
        diag "$test->{desc} with $args->[0]";

        # create from scratch
        my $commit
            = Git::Database::Object::Commit->new( @$args, repository => $r );
        test_commit( $commit, $test );

        # obtain from the git object database
        $commit = $r->get_object( $test->{digest} );
        test_commit( $commit, $test );
    }
}

done_testing;
