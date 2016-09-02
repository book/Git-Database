use strict;
use warnings;
use Test::More;
use Git::Database;

use t::Util;

my $zero = '0' x 40;

test_backends(
    sub {
        my ( $backend, $is_empty, $source ) = @_;
        plan
          skip_all => sprintf '%s does not Git::Database::Role::ObjectReader',
          ref $backend
          if !$backend->does('Git::Database::Role::ObjectReader');

        # this digest should not exist anywhere
        for my $kind (qw( blob tree commit tag )) {
            my $object = "Git::Database::Object::\u$kind"->new(
                backend => $backend,
                digest  => $zero,
            );
            ok( !eval { $object->content },
                "$kind $zero not found in $backend" );
            like(
                $@,
                qr/^$kind 0{40} not found in \Q$backend\E /,
                '... expected error message'
            );
        }
    },
    ''    # will force an empty repository
);

done_testing;
