package Git::Database::Object::Blob;

use Moo;

with 'Git::Database::Role::Object';

sub kind { 'blob' }

1;
