use strict;
use warnings;
use Test::More;
use Git::Database;

use t::Util;

my %methods_for = (
    'Git::Database::Role::Backend'      => ['hash_object'],
    'Git::Database::Role::ObjectReader' => [
        'get_object_meta', 'get_object_attributes',
        'get_object',      'has_object',
        'all_digests',
    ],
    'Git::Database::Role::ObjectWriter' => ['put_object'],
    'Git::Database::Role::RefReader'    => ['refs'],
    'Git::Database::Role::RefWriter'    => [ 'put_ref', 'delete_ref' ],
);

test_backends(
    sub {
        my ( $backend, $is_empty, $source ) = @_;
        my $class = ref $backend;
        my $db = Git::Database->new( backend => $backend );

        # stuff we're sure of
        ok( $db->can('backend'), "can( backend )" );
        ok( ! $db->can('zlonk'), "cant'( zlonk )" );

        for my $role ( sort keys %methods_for ) {
            if($db->backend->does( $role ) ) {
                ok( $db->can($_), "can( $_ )" ) for @{ $methods_for{$role} };
            }
            else{ 
                ok( !$db->can($_), "can't( $_ )" ) for @{ $methods_for{$role} };
            }
        }
    },
    '', # test each backend once, with an empty repository
);

done_testing;
