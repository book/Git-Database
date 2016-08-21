use strict;
use warnings;
use Test::More;
use Git::Database;

use Git::Database::Object::Blob;
use Git::Database::Object::Tree;
use Git::Database::Object::Commit;
use Git::Database::Object::Tag;

use t::Util;

# a database with no store
my $db = Git::Database->new();
isa_ok( $db,          'Git::Database' );
isa_ok( $db->backend, 'Git::Database::Backend::None' );

# different object kinds work with different possible arguments
my %args_for = (
    blob => sub {
        return
          [ content => $_[0]->{content} ],
          ;
    },
    tree => sub {
        return
          [ content           => $_[0]->{content} ],
          [ directory_entries => $_[0]->{directory_entries} ],
          ;
    },
    commit => sub {
        return
          [ content     => $_[0]->{content} ],
          [ commit_info => $_[0]->{commit_info} ],
          ;
    },
    tag => sub {
        return
          [ content  => $_[0]->{content} ],
          [ tag_info => $_[0]->{tag_info} ],
          ;
    },
);

# test over all available objects
for my $source (available_objects) {
    diag "Using objects from $source";
    my $objects = objects_from($source);

    for my $test ( map @{ $objects->{$_} }, sort keys %$objects ) {
        my ( $kind, $digest, $size ) = @{$test}{qw( kind digest size )};

        diag $test->{desc};

        # create object
        for my $args ( $args_for{$kind}->($test) ) {

            # this test computes the digest
            my $object = "Git::Database::Object::\u$kind"->new( @$args );
            test_object( $object, $test );

            # Git::Database::Role::Backend
            is( $db->hash_object($object), $test->{digest}, 'hash_object' );
        }
    }
}

done_testing;
