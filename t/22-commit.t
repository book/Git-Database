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

# some error cases
my $test = $objects{commit}[0];
my @fail = (
    [   [   content     => $test->{content},
            commit_info => $test->{commit_info},
            repository  => $r,
        ],
        qr/^At most one of 'content' and 'commit_info' can be defined/,
        'content + commit_info',
    ],
    [   [ repository => $r ],
        qr/^At least one of 'content' or 'commit_info' must be defined/,
        'no content, no commit_info',
    ],
);

for my $fail (@fail) {
    my ( $args, $re, $mesg ) = @$fail;
    ok( !eval { Git::Database::Object::Commit->new(@$args) }, $mesg );
    like( $@, $re, '... expected error message' );
}

done_testing;
