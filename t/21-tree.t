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

for my $test ( @{ $objects{tree} } ) {
    for my $args (
        [ content           => $test->{content} ],
        [ directory_entries => $test->{directory_entries} ],
        )
    {
        diag "$test->{desc} with $args->[0]";

        # create from scratch
        my $tree = Git::Database::Tree->new(@$args, repository => $r);
        test_tree( $tree, $test );

        # obtain from the git object database
        $tree = $r->get_object( $test->{digest} );
        test_tree( $tree, $test );
    }
}

done_testing;

