package Git::Simple;

use Moo;
use Sub::Quote;

extends 'Git::Repository';

has _object_factory => (
    is  => 'lazy',
    isa => quote_sub(
        q{ die 'Not a Git::Repository::Command' if ! $_[0]->isa('Git::Repository::Command' ) }
    ),
    required => 0,
    predicate => 1,
);

sub _build__object_factory { $_[0]->command( 'cat-file', '--batch' ); }

use Git::Simple::Blob;
my %kind2class = (
    blob => 'Git::Simple::Blob',
);

sub get_object {
    my ( $self, $digest ) = @_;
    my $factory = $self->_object_factory;

    # request the object
    print { $factory->stdin } $digest, "\n";

    # process the reply
    my $out = $factory->stdout;
    local $/ = "\012";
    chomp( my $reply = <$out> );
    my ( $sha1, $kind, $size ) = split / /, $reply;

    # object does not exist in the git object database
    return if $kind eq 'missing';

    # TODO - return an object when it exists
    my $res = read $out, (my $content), $size;
    if( $res != $size ) {
         $factory->close; # in case the exception is trapped
         die "Read $res/$size of content from git";
    }

    # read the last byte
    $res = read $out, (my $junk), 1;
    if( $res != 1 ) {
         $factory->close; # in case the exception is trapped
         die "Unable to finish reading content from git";
    }

    # careful with utf-8!
    # create a new object with digets, content and size
    return $kind2class{$kind}->new(
        repository => $self,
        size       => $size,
        content    => $content,
        digest     => $sha1
    );
}

sub DEMOLISH {
    my ($self) = @_;
    $self->_object_factory->close if $self->_has_object_factory;
}

1;

__END__

# ABSTRACT: Git repositories made easy
