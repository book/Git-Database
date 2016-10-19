package Git::Database::Role::ExpandAbbrev;

use Moo::Role;

requires
  'all_digests',
  ;

# this is really when the backend does not support abbreviations
sub expand_abbrev {
    my ( $self, $abbrev ) = @_;

    # some shortcuts
    return ''         if !defined $abbrev;
    return lc $abbrev if $abbrev =~ /^[0-9a-fA-F]{40}$/;
    return ''         if length $abbrev < 4;

    # basic implementation
    my @matches = grep /^$abbrev/, $self->all_digests;
    warn "error: short SHA1 $abbrev is ambiguous.\n" if @matches > 1;
    return @matches == 1 ? shift @matches : '';
}

1;

