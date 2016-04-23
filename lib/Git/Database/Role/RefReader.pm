package Git::Database::Role::RefReader;

use Moo::Role;

requires
  'resolve_ref',
  'get_refs',
  ;

1;
