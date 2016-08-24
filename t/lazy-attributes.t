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
                    if ( $is_reader && !$is_empty ) {
                        is(
                            Git::Database::Object::Blob->new(
                                backend => $backend,
                                digest  => $test->{digest},
                              )->content,
                            $test->{content},
                            'digest -> content'
                        );
                        is(
                            Git::Database::Object::Blob->new(
                                backend => $backend,
                                digest  => $test->{digest},
                              )->size,
                            $test->{size},
                            'digest -> size'
                        );
                    }

                    # content
                    is(
                        Git::Database::Object::Blob->new(
                            backend => $backend,
                            content => $test->{content},
                          )->digest,
                        $test->{digest},
                        'content -> digest'
                    );
                    is(
                        Git::Database::Object::Blob->new(
                            backend => $backend,
                            content => $test->{content},
                          )->size,
                        $test->{size},
                        'content -> size'
                    );

                    done_testing;
                }
            );
        }
    },
    tree => sub {
        my ( $backend, $is_empty, @items ) = @_;
        my $is_reader = $backend->does('Git::Database::Role::ObjectReader');

        for my $test (@items) {
            subtest(
                $test->{desc},
                sub {

                    # digest
                    if ( $is_reader && !$is_empty ) {
                        is(
                            Git::Database::Object::Tree->new(
                                backend => $backend,
                                digest  => $test->{digest},
                              )->content,
                            $test->{content},
                            'digest -> content'
                        );
                        is(
                            Git::Database::Object::Tree->new(
                                backend => $backend,
                                digest  => $test->{digest},
                              )->size,
                            $test->{size},
                            'digest -> size'
                        );
                        is_deeply(
                            Git::Database::Object::Tree->new(
                                backend => $backend,
                                digest  => $test->{digest},
                              )->directory_entries,
                            [
                                sort { $a->filename cmp $b->filename }
                                  @{ $test->{directory_entries} }
                            ],
                            'digest -> directory_entries'
                        );
                    }

                    # content
                    is(
                        Git::Database::Object::Tree->new(
                            backend => $backend,
                            content => $test->{content}
                          )->digest,
                        $test->{digest},
                        'content -> digest'
                    );
                    is(
                        Git::Database::Object::Tree->new(
                            backend => $backend,
                            content => $test->{content}
                          )->size,
                        $test->{size},
                        'content -> size'
                    );
                    is_deeply(
                        Git::Database::Object::Tree->new(
                            backend => $backend,
                            content => $test->{content}
                          )->directory_entries,
                        [
                            sort { $a->filename cmp $b->filename }
                              @{ $test->{directory_entries} }
                        ],
                        'content -> directory_entries'
                    );

                    # directory_entries
                    is(
                        Git::Database::Object::Tree->new(
                            backend           => $backend,
                            directory_entries => $test->{directory_entries}
                          )->digest,
                        $test->{digest},
                        'directory_entries -> digest'
                    );
                    is(
                        Git::Database::Object::Tree->new(
                            backend           => $backend,
                            directory_entries => $test->{directory_entries}
                          )->content,
                        $test->{content},
                        'directory_entries -> content'
                    );
                    is(
                        Git::Database::Object::Tree->new(
                            backend           => $backend,
                            directory_entries => $test->{directory_entries}
                          )->size,
                        $test->{size},
                        'directory_entries -> size'
                    );

                    done_testing;
                }
            );
        }
    },
    commit => sub {
        my ( $backend, $is_empty, @items ) = @_;
        my $is_reader = $backend->does('Git::Database::Role::ObjectReader');

        for my $test (@items) {
            subtest(
                $test->{desc},
                sub {
                    # digest
                    if ( $is_reader && !$is_empty ) {
                        is(
                            Git::Database::Object::Commit->new(
                                backend => $backend,
                                digest  => $test->{digest}
                              )->content,
                            $test->{content},
                            'digest -> content'
                        );
                        is(
                            Git::Database::Object::Commit->new(
                                backend => $backend,
                                digest  => $test->{digest}
                              )->size,
                            $test->{size},
                            'digest -> size'
                        );
                        is_deeply(
                            Git::Database::Object::Commit->new(
                                backend => $backend,
                                digest  => $test->{digest}
                              )->commit_info,
                            $test->{commit_info},
                            'digest -> commit_info'
                        );
                    }

                    # content
                    is(
                        Git::Database::Object::Commit->new(
                            backend => $backend,
                            content => $test->{content}
                          )->digest,
                        $test->{digest},
                        'content -> digest'
                    );
                    is(
                        Git::Database::Object::Commit->new(
                            backend => $backend,
                            content => $test->{content}
                          )->size,
                        $test->{size},
                        'content -> size'
                    );
                    is_deeply(
                        Git::Database::Object::Commit->new(
                            backend => $backend,
                            content => $test->{content}
                          )->commit_info,
                        $test->{commit_info},
                        'content -> commit_info'
                    );

                    # commit_info
                    is(
                        Git::Database::Object::Commit->new(
                            backend     => $backend,
                            commit_info => $test->{commit_info}
                          )->digest,
                        $test->{digest},
                        'commit_info -> digest'
                    );
                    is(
                        Git::Database::Object::Commit->new(
                            backend     => $backend,
                            commit_info => $test->{commit_info}
                          )->content,
                        $test->{content},
                        'commit_info -> content'
                    );
                    is(
                        Git::Database::Object::Commit->new(
                            backend     => $backend,
                            commit_info => $test->{commit_info}
                          )->size,
                        $test->{size},
                        'commit_info -> size'
                    );

                    done_testing;
                }
            );
        }
    },
);

done_testing;
