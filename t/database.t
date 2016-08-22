use strict;
use warnings;
use Test::More;
use Git::Database;

use t::Util;

# a database with no store
my $db = Git::Database->new();
isa_ok( $db,          'Git::Database' );
isa_ok( $db->backend, 'Git::Database::Backend::None' );

# test with
my $dir = empty_repository;
for my $backend ( available_backends() ) {

    # provide backend directly
    $db = Git::Database->new( backend => backend_for( $backend, $dir ) );
    isa_ok( $db,          'Git::Database' );
    isa_ok( $db->backend, "Git::Database::Backend::$backend" );
    isa_ok( $db->backend->store, $backend ) if $backend ne 'None';
}

# some error cases
ok(
    !eval { $db = Git::Database->new( backend => 'fail' ) },
    'backend does not Git::Database::Role::Backend'
);
like(
    $@,
    qr/^isa check for "backend" failed: fail DOES not Git::Database::Role::Backend/,
    '... expected error message'
);

done_testing;
