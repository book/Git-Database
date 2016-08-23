use strict;
use warnings;
use Test::More;
use Git::Database;

use t::Util;

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

test_kind(
    sub {
        my ( $backend, $is_empty, @objects ) = @_;
        my $is_reader = $backend->does('Git::Database::Role::ObjectReader');

        # a database for this backend
        my $db = Git::Database->new( backend => $backend );

        # figure out the store class
        my $class = substr( ref $backend, 24 );  # drop Git::Database::Backend::

        # a database pointing to an empty repository
        my $nil =
          Git::Database->new( store => store_for( $class, empty_repository ) );

        # pick some random sha1 and check it's not in the empty repository
        if ($is_reader) {
            my $sha1 = join '', map sprintf( '%02x', rand 256 ), 1 .. 20;
            is( $nil->has_object($sha1), '', "Database does not have $sha1" );
            is( $nil->get_object($sha1),
                undef, "Database can't get an object for $sha1" );
        }

        for my $test (@objects) {
            my ( $kind, $digest, $size ) = @{$test}{qw( kind digest size )};

            subtest(
                $test->{desc},
                sub {

                    # this test computes the digest
                    for my $args ( $args_for{$kind}->($test) ) {

                        my $object =
                          "Git::Database::Object::\u$kind"->new(@$args);

                        is( $nil->hash_object($object),
                            $test->{digest}, "hash_object: $test->{digest}" );

                        cmp_git_objects( $object, $test );
                    }

                    done_testing;
                }
            );

        }
    }
);

done_testing;
