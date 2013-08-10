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

for my $test ( @{ $objects{tag} } ) {
    for my $args (
        [ content  => $test->{content} ],
        [ tag_info => $test->{tag_info} ],
        )
    {
        diag "$test->{desc} with $args->[0]";

        # create from scratch
        my $tag = Git::Database::Object::Tag->new( @$args, repository => $r );
        test_tag( $tag, $test );

        # obtain from the git object database
        $tag = $r->get_object( $test->{digest} );
        test_tag( $tag, $test );
    }
}

done_testing;
