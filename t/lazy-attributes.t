use strict;
use warnings;
use Test::More;
use Git::Database;

use t::Util;

# this set of tests mostly targets the builders:
#
# it creates the object with each supported attribute,
# lets the builders build the other attributes,
# and tests the results

test_kind(
    blob => sub {
        my ( $backend, $is_empty, @items ) = @_;
        my $is_reader = $backend->does('Git::Database::Role::ObjectReader');

        for my $test (@items) {
            subtest(
                $test->{desc},
                sub {

                    # digest
                    is(
                        Git::Database::Object::Blob->new(
                            backend => $backend,
                            digest  => $test->{digest},
                          )->content,
                        $test->{content},
                        'digest -> content'
                    ) if $is_reader && !$is_empty;

                    # content
                    is(
                        Git::Database::Object::Blob->new(
                            backend => $backend,
                            content => $test->{content},
                          )->digest,
                        $test->{digest},
                        'content -> digest'
                    );

                    done_testing;
                }
            );
        }
    },
);

done_testing;
