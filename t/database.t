use strict;
use warnings;
use Test::More;
use Git::Database;

# a database with no store
my $db = Git::Database->new();
isa_ok( $db,          'Git::Database' );
isa_ok( $db->backend, 'Git::Database::Backend::None' );

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
