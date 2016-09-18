use strict;
use warnings;
use Test::More;
use Git::Database;

use t::Util;

# a database with no store
my $db = Git::Database->new();
ok(
    $db->does('Git::Database::Role::Backend'),
    'db does Git::Database::Role::Backend'
);

# test with
my $dir = empty_repository;
for my $backend ( available_backends() ) {

    # provide backend directly
    $db = Git::Database->new( backend => backend_for( $backend, $dir ) );
    isa_ok( $db, "Git::Database::Backend::$backend" );
    isa_ok( $db->store, $backend ) if $backend ne 'None';

    # build backend from store
    $db = Git::Database->new( store => store_for( $backend, $dir ) );
    isa_ok( $db, "Git::Database::Backend::$backend" );
    isa_ok( $db->store, $backend ) if $backend ne 'None';
}

# some error cases
ok(
    !eval { $db = Git::Database->new( backend => 'fail' ) },
    'backend does not Git::Database::Role::Backend'
);
like(
    $@,
    qr/^fail DOES not Git::Database::Role::Backend /,
    '... expected error message'
);

ok(
    !eval { $db = Git::Database->new( backend => 'backend', store => 'store' ) },
    'backend and store are mutually exclusive'
);
like(
    $@,
    qr/^'store' is incompatible with 'backend' /,
    '... expected error message'
);

ok(
    !eval { $db = Git::Database->new( store => bless( {}, 'Nope' ) ) },
    'Git::Database::Backend::Nope does not exist'
);
like(
    $@,
    qr{^Can't locate Git/Database/Backend/Nope.pm in \@INC },
    '... expected error message'
);


done_testing;
