package Git::Database::Role::RefReader;

use Moo::Role;

requires
  'refs',
  ;

# basic implementations
sub ref_names {
    my ( $self, $type ) = @_;
    return $type
      ? sort grep m{^refs/\Q$type\E/}, keys %{ $self->refs }
      : sort keys %{ $self->refs };
}

sub ref_digest { $_[0]->refs->{ $_[1] } }

1;
