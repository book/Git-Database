package Git::Database::Role::Backend;

use Moo::Role;

requires
  'hash_object',
  ;

has store => (
    is       => 'ro',
    required => 1,
);

1;
