package Git::Simple::Blob;

use Moo;

with 'Git::Simple::Role::Object';

sub kind { 'blob' }

1;
