package Git::Database::Object::Commit;

use Moo;

with 'Git::Database::Role::Object';

use Git::Database::Actor;
use DateTime;
use Encode qw( decode );

sub kind {'commit'}

has commit_info => (
    is        => 'lazy',
    required  => 0,
    predicate => 1,
);

for my $attr (
    qw(
    tree_digest
    author
    authored_time
    committer
    committed_time
    comment
    encoding
    )
    )
{
    no strict 'refs';
    *$attr = sub { $_[0]->commit_info->{$attr} };
}

sub parents_digest { @{ $_[0]->commit_info->{parents_digest} ||= [] }; }

my %method_map = (
    'tree'      => 'tree_digest',
    'parent'    => '@parents_digest',
    'author'    => 'authored_time',
    'committer' => 'committed_time'
);

# ensure at least one but not both content or commit_info is defined
sub BUILD {
    my ($self) = @_;
    die "At least one of 'content' or 'commit_info' must be defined"
        if !$self->has_content && !$self->has_commit_info;
    die "At most one of 'content' and 'commit_info' can be defined"
        if $self->has_content && $self->has_commit_info;
}

# assumes commit_info is set
sub _build_content {
    my ($self) = @_;
    my $content;
    $content .= 'tree ' . $self->tree_digest . "\n";
    $content .= "parent $_\n" for $self->parents_digest;
    $content .= join(
        ' ',
        author => $self->author->ident,
        $self->authored_time->epoch,
        DateTime::TimeZone->offset_as_string( $self->authored_time->offset )
    ) . "\n";
    $content .= join(
        ' ',
        committer => $self->committer->ident,
        $self->committed_time->epoch,
        DateTime::TimeZone->offset_as_string( $self->committed_time->offset )
    ) . "\n";
    $content .= "\n";
    my $comment = $self->comment;
    chomp $comment;
    $content .= "$comment\n";

    return $content;
}

# assumes content is set
sub _build_commit_info {
    my $self = shift;
    my $commit_info = { parents_digest => [] };

    my @lines = split "\n", $self->content;
    my %header;
    while ( my $line = shift @lines ) {
        my ( $key, $value ) = split ' ', $line, 2;
        push @{ $header{$key} }, $value;
    }
    $header{encoding} = ['utf-8'];
    my $encoding = $header{encoding}->[-1];
    for my $key ( keys %header ) {
        for my $value ( @{ $header{$key} } ) {
            $value = decode( $encoding, $value );
            if ( $key eq 'committer' or $key eq 'author' ) {
                my @data = split ' ', $value;
                my ( $email, $epoch, $tz ) = splice( @data, -3 );
                $commit_info->{$key} = Git::Database::Actor->new(
                    name => join( ' ', @data ),
                    email => substr( $email, 1, -1 ),
                );
                $key = $method_map{$key};
                $commit_info->{$key} = DateTime->from_epoch(
                    epoch     => $epoch,
                    time_zone => $tz
                );
            }
            else {
                my $mkey = $method_map{$key} || $key;
                if ( $mkey =~ s/^\@// ) {
                    push @{ $commit_info->{$mkey} }, $value;
                }
                else { $commit_info->{$mkey} = $value; }
            }
        }
    }
    $commit_info->{comment} = decode( $encoding, join "\n", @lines );
    return $commit_info;
}

1;
