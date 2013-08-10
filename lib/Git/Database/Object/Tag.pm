package Git::Database::Object::Tag;

use Moo;

with 'Git::Database::Role::Object';

use Git::Database::Actor;
use DateTime;
use Encode qw( decode );

sub kind {'tag'}

has tag_info => (
    is        => 'lazy',
    required  => 0,
    predicate => 1,
);

for my $attr (
    qw(
    object
    type
    tag
    tagger
    tagged_time
    comment
    )
    )
{
    no strict 'refs';
    *$attr = sub { $_[0]->tag_info->{$attr} };
}

my %method_map = ( 'tagger' => 'tagged_time' );

sub _build_tag_info {
    my $self     = shift;
    my $tag_info = {};
    my @lines    = split "\n", $self->content;
    while ( my $line = shift @lines ) {
        last unless $line;
        my ( $key, $value ) = split ' ', $line, 2;

        if ( $key eq 'tagger' ) {
            my @data = split ' ', $value;
            my ( $email, $epoch, $tz ) = splice( @data, -3 );
            $tag_info->{$key} = Git::Database::Actor->new(
                name => join( ' ', @data ),
                email => substr( $email, 1, -1 )
            );
            $tag_info->{ $method_map{$key} } = DateTime->from_epoch(
                epoch     => $epoch,
                time_zone => $tz
            );
        }
        else {
            $tag_info->{ $method_map{$key} || $key } = $value;
        }
    }
    $tag_info->{comment} = join "\n", @lines;
    return $tag_info;
}

sub _build_content {
    my ($self) = @_;
    my $content;
    $content .= "$_ " . $self->$_ . "\n" for qw( object type tag );
    $content .= join(
        ' ',
        tagger => $self->tagger->ident,
        $self->tagged_time->epoch,
        DateTime::TimeZone->offset_as_string( $self->tagged_time->offset )
    ) . "\n";
    $content .= "\n";
    my $comment = $self->comment;
    chomp $comment;
    $content .= "$comment\n";

    return $content;
}

1;
