package Git::Database::Role::WithRaw;

use Moo::Role;

with 'Git::Database::Role::Object';

*sha1 = \&digest;

sub raw { $_[0]->kind . ' ' . $_[0]->size . "\0" . $_[0]->content }

1;

__END__

=pod

=head1 NAME

Git::Database::Role::WithRaw - Add a raw method to Git::Database objects

=head1 SYNOPSIS

    my $blob = Git::Database::Object::Blob->new( ... );
    Role::Tiny->apply_roles_to_object( $blob, 'Git::Database::Role::WithRaw' );

    # and now, $blob->can('raw')
    print $blob->raw;

=head1 DESCRIPTION

Instead of creating L<Git::PurePerl::NewObject> objects so that the
L<Git::Database::Backend::Git::PurePerl> backend can put them into the
Git object database, this role simply adds the L</sha1> and L</raw>
methods used by L<Git::PurePerl::Loose> when saving an object.

=head1 METHODS

=head2 sha1

Alias for L<digest|Git::Database::Role::Object/digest>.

=head2 raw

Return the raw data, as used by L<Git::PurePerl::Loose> to save an object
in the Git object database.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>

=head1 COPYRIGHT

Copyright 2016 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
