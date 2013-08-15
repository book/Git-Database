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
        my $tree = Git::Database::Object::Tree->new(@$args, repository => $r);
        test_tree( $tree, $test );

        # obtain from the git object database
        $tree = $r->get_object( $test->{digest} );
        test_tree( $tree, $test );
    }
}

# some error cases
my $test = $objects{tree}[0];
my @fail = (
    [   [   content           => $test->{content},
            directory_entries => $test->{directory_entries},
            repository        => $r,
        ],
        qr/^At most one of 'content' and 'directory_entries' can be defined/,
        'content + directory_entries',
    ],
    [   [ repository => $r ],
        qr/^At least one of 'content' or 'directory_entries' must be defined/,
        'no content, no directory_entries',
    ],
);

for my $fail (@fail) {
    my ( $args, $re, $mesg ) = @$fail;
    ok( !eval { Git::Database::Object::Tree->new(@$args) }, $mesg );
    like( $@, $re, '... expected error message' );
}

done_testing;

