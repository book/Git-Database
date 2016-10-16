package Git::Database::Backend::Git::Wrapper;

use Cwd qw( cwd );
use Git::Wrapper;
use Git::Version::Compare qw( ge_git );
use Sub::Quote;

use Moo;
use namespace::clean;

with
  'Git::Database::Role::Backend',
  'Git::Database::Role::ObjectReader',
  ;

has '+store' => (
    isa => quote_sub( q{
        die 'store is not a Git::Wrapper object'
          if !eval { $_[0]->isa('Git::Wrapper') }
    } ),
    default => sub { Git::Wrapper->new( cwd() ) },
);

# Git::Database::Role::Backend
sub hash_object {
    my ( $self, $object ) = @_;
    my @out = $self->store->hash_object( { -STDIN => $object->content },
        '--stdin', '-t', $object->kind );
    return shift @out;
}

# Git::Database::Role::ObjectReader
sub get_object_meta {
    my ( $self, $digest ) = @_;
    my ($meta) =
      $self->store->cat_file( { -STDIN => "$digest\n" }, '--batch-check' );

    # protect against weird cases like if $digest contains a space
    my @parts = split / /, $meta;
    return ( $digest, 'missing', undef ) if $parts[-1] eq 'missing';

    my ( $kind, $size ) = splice @parts, -2;
    return join( ' ', @parts ), $kind, $size;
}

sub get_object_attributes {
    my ( $self, $digest ) = @_;

    # I don't see how this can't break on binary data
    my @out = $self->store->cat_file( { -STDIN => "$digest\n" }, '--batch' );
    my $meta = shift @out;

    # protect against weird cases like if $digest contains a space
    my ( $sha1, $kind, $size ) = my @parts = split / /, $meta;

    # object does not exist in the git object database
    return undef if $parts[-1] eq 'missing';

    return {
        kind       => $kind,
        size       => $size,
        content    => join( $/, @out ),
        digest     => $sha1
    };
}

sub all_digests {
    my ( $self, $kind ) = @_;
    my $store = $self->store;
    my $re = $kind ? qr/ \Q$kind\E / : qr/ /;

    # the --batch-all-objects option appeared in v2.6.0-rc0
    if ( ge_git( $store->version, '2.6.0.rc0' ) ) {
        return map +( split / / )[0],
          grep /$re/,
          $store->cat_file(qw( --batch-check --batch-all-objects ));
    }
    else {    # this won't return unreachable objects
        my $batch = $store->command(qw( cat-file --batch-check ));
        my ( $stdin, $stdout ) = ( $batch->stdin, $batch->stdout );
        my @digests =
          map +( split / / )[0], grep /$re/,
          map { print {$stdin} ( split / / )[0], "\n"; $stdout->getline }
          sort $store->rev_list(qw( --all --objects ));
        $batch->close;
        return @digests;
    }
}

1;
