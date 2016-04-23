package Git::Database::Role::RefWriter;

use Moo::Role;

requires
  'put_ref',
  'delete_ref'
;

1;
