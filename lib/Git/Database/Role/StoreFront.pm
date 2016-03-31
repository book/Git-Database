package Git::Database::Role::StoreFront;

use Moo::Role;

requires
  'has_object',
  'get_object',
;

1;
