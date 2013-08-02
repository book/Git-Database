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

sub get_object {
    my ( $self, $digest ) = @_;
    my $factory = $self->_object_factory;

    # request the object
    print { $factory->stdin } $digest, "\n";

    # process the reply
    my $out = $factory->stdout;
    local $/ = "\012";
    chomp( my $reply = <$out> );
    my ( $sha1, $type, $size ) = split / /, $reply;

    # object does not exist in the git object database
    return if $type eq 'missing';

    # TODO - return a object when it exists
}

sub DEMOLISH {
    my ($self) = @_;
    $self->_object_factory->close if $self->_has_object_factory;
}

1;

__END__

# ABSTRACT: Git repositories made easy
