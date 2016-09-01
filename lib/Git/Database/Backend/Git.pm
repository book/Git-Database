package Git::Database::Backend::Git;

use Sub::Quote;

use Moo;
use namespace::clean;

with
  'Git::Database::Role::Backend',
  ;

has '+store' => (
    isa => quote_sub( q{
        die 'store is not a Git object'
          if !eval { $_[0]->isa('Git') }
    } ),
);

has object_factory => (
    is        => 'lazy',
    init_arg  => undef,
    builder   => sub { [ $_[0]->store->command_bidi_pipe( 'cat-file', '--batch' ) ] },
    predicate => 1,
    clearer   => 1,
);

sub hash_object {
    my ( $self, $object ) = @_;
    my ( $pid, $in, $out, $ctx ) =
      $self->store->command_bidi_pipe( 'hash-object', '-t', $object->kind,
        '--stdin' );
    print {$out} $object->content;
    close $out;
    chomp( my $digest = <$in> );
    $self->store->command_close_bidi_pipe( $pid, $in, undef, $ctx ); # $out closed
    return $digest;
}

1;
