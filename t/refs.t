use strict;
use warnings;
use Test::More;
use Git::Database;

use t::Util;

test_backends(
    sub {
        my ( $backend, $is_empty, $source ) = @_;
        plan
          skip_all => sprintf '%s does not Git::Database::Role::RefReader',
          ref $backend
          if !$backend->does('Git::Database::Role::RefReader');

        my $refs = objects_from($source)->{refs};

        is_deeply( $backend->refs, $refs, 'refs' );

        is_deeply( [ $backend->ref_names ], [ sort keys %$refs ], 'ref_names' );

        is_deeply(
            [ $backend->ref_names('heads') ],
            [ sort grep m{^refs/heads/}, keys %$refs ],
            "ref_names('heads')"
        );

        is( $backend->ref_digest($_), $refs->{$_}, "ref_digest('$_')" )
          for (qw( HEAD refs/heads/master refs/remotes/origin/master nil ));
    }
);

done_testing;
