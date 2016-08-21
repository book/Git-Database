use strict;
use warnings;

# don't load extra subs, or run any import
use File::Spec          ();
use File::Temp          ();
use File::Basename      ();
use Test::Requires::Git ();

# all the following functions will end up in the caller's namespace

# test data
sub objects_from {
    my ($name) = @_;
    my $perl = File::Spec->catfile( qw( t bundles ), "$name.perl" );

    # TODO: looks in @INC, saves in %INC, is it really wanted?
    # we could just slurp and eval the content of the file.
    my $objects = do $perl;

    # add extra information
    for my $kind ( keys %$objects ) {
        for my $object ( @{ $objects->{$kind} } ) {
            $object->{kind} = $kind;
            $object->{sha1} = $object->{digest};
            $object->{size} = length $object->{content};
            $object->{string} ||= $object->{content};
        }
    }

    return $objects;
}

sub repository_from {
    my ($name) = @_;
    my $bundle = File::Spec->catfile( qw( t bundles ), "$name.bundle" );
    my $dir = File::Temp::tempdir( CLEANUP => 1 );

    Test::Requires::Git::test_requires_git '1.6.5';
    `git clone $bundle $dir`;
    die "Cloning $bundle in $dir failed" if $?;

    return $dir;
}

# helpers
my %test_data;
for my $file ( glob File::Spec->catfile(qw( t bundles * )) ) {
    my ( $name, undef, $ext ) =
      File::Basename::fileparse( $file, qw( .perl .bundle ) );
    $test_data{$name}{$ext} = $file;
}

sub available_objects {
    return grep exists $test_data{$_}{'.perl'}, keys %test_data;
}

sub available_bundles {
    return grep exists $test_data{$_}{'.bundle'}, keys %test_data;
}

sub bundle_for { return $test_data{ $_[0] }{'.bundle'} }

# extra kind-specific tests
my %test_for = (
    tree => sub {
        my ( $tree, $test ) = @_;
        is_deeply(
            $tree->directory_entries,
            [
                sort { $a->filename cmp $b->filename }
                  @{ $test->{directory_entries} }
            ],
            '- directory_entries'
        );
    },
    commit => sub {
        my ( $commit, $test ) = @_;

        # can't use is_deeply here
        my $commit_info = $commit->commit_info;
        for my $attr (qw( tree_digest authored_time committed_time comment )) {
            is(
                $commit_info->{$attr},
                $test->{commit_info}{$attr},
                "- commit_info $attr"
            );
        }
        for my $attr (qw( author committer )) {
            is(
                $commit_info->{$attr}->ident,
                $test->{commit_info}{$attr}->ident,
                "- commit_info $attr"
            );
        }
        is(
            join( ' ', @{ $commit_info->{parents_digest} } ),
            join( ' ', @{ $test->{commit_info}{parents_digest} || [] } ),
            '- commit_info parents_digest'
        );
    },
    tag => sub {
        my ( $tag, $test ) = @_;

        # can't use is_deeply here
        my $tag_info = $tag->tag_info;
        for my $attr (qw( object type tag tagged_time comment )) {
            is( $tag_info->{$attr}, $test->{tag_info}{$attr},
                "- tag_info $attr" );
        }
        is(
            $tag_info->{tagger}->ident,
            $test->{tag_info}{tagger}->ident,
            '- tag_info tagger'
        );
    },
);

# test routines
sub test_object {
    my ( $object, $test ) = @_;

    my $kind = $object->kind;
    isa_ok( $object, "Git::Database::Object::\u$kind" );

    # read content in memory early
    is( $object->kind,      $test->{kind},    '- kind' );
    is( $object->content,   $test->{content}, '- content' );
    is( $object->size,      $test->{size},    '- size' );
    is( $object->digest,    $test->{digest},  '- digest' );
    is( $object->as_string, $test->{string},  '- as_string' );

    # run the kind-specific tests
    $test_for{$kind}->( $object, $test ) if exists $test_for{$kind};
}

1;