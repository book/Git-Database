package Git::Database::Backend::Git::Sub;

use Cwd ();
use Sub::Quote;
use Git::Sub;
use Git::Version::Compare ();

use Moo;
use namespace::clean;

# the store attribute is a directory name
# or an object representing a directory
# (e.g. Path::Class, Path::Tiny, File::Fu)

# stuff used to generate subroutines
my $package = 'Git::Database::Backend::Git::Sub';
my $wrapper = q{
    my $home = Cwd::cwd();
    my $dir  = $self->store;
    chdir $dir or die "Can't chdir to $dir: $!";
    %s
    chdir $home or die "Can't chdir to $home: $!";
};

# Git::Database::Role::Backend
quote_sub "${package}::hash_object", q{
    my ( $self, $object ) = @_;
} . sprintf( $wrapper, q{
    my $hash = git::hash_object
      '-t'      => $object->kind,
      '--stdin' => \$object->content;
} ) . q{
    return $hash;
};

# Git::Database::Role::ObjectReader
quote_sub "${package}::get_object_meta", q{
    my ( $self, $digest ) = @_;
} . sprintf( $wrapper, q{
    my $meta = git::cat_file
      '--batch-check' => \"$digest\n";
} ) . q{
    # protect against weird cases like if $digest contains a space
    my @parts = split / /, $meta;
    return ( $digest, 'missing', undef ) if $parts[-1] eq 'missing';

    my ( $kind, $size ) = splice @parts, -2;
    return join( ' ', @parts ), $kind, $size;
};

quote_sub "${package}::get_object_attributes", q{
    my ( $self, $digest ) = @_;
} . sprintf( $wrapper, q{
    my $out = do {
        local $/;
        git::cat_file '--batch' => \"$digest\n";
    };
} ) . q{
    my ( $meta, $content ) = split "\n", $out, 2;

    # protect against weird cases like if $digest contains a space
    my ( $sha1, $kind, $size ) = my @parts = split / /, $meta;

    # object does not exist in the git object database
    return if $parts[-1] eq 'missing';

    return {
        kind       => $kind,
        size       => $size,
        content    => substr( $content, 0, $size ),
        digest     => $sha1
    };
};

quote_sub "${package}::all_digests", q{
    my ( $self, $kind ) = @_;
} . sprintf( $wrapper, q{
    local $_;    # Git::Sub seems to clobber $_ in list context
    my $re = $kind ? qr/ \Q$kind\E / : qr/ /;
    my @digests;

    # the --batch-all-objects option appeared in v2.6.0-rc0
    if ( Git::Version::Compare::ge_git git::version, '2.6.0.rc0' ) {
        @digests = map +( split / / )[0],
          grep /$re/,
          git::cat_file '--batch-check', '--batch-all-objects';
    }
    else {    # this won't return unreachable objects
        @digests =
          map +( split / / )[0], grep /$re/,
          git::cat_file '--batch-check', \join '', map +( split / / )[0] . "\n",
          sort +git::rev_list '--all', '--objects';
    }
} ) . q{
    return @digests;
};

# Git::Database::Role::ObjectWriter
quote_sub "${package}::put_object", q{
    my ( $self, $object ) = @_;
} . sprintf( $wrapper, q{
    my $hash = git::hash_object
      '-w',
      '-t'      => $object->kind,
      '--stdin' => \$object->content;
} ) . q{
    return $hash;
};

# Git::Database::Role::RefReader
quote_sub "${package}::refs", q{
    my ($self) = @_;
} . sprintf( $wrapper, q{
    local $_;    # Git::Sub seems to clobber $_ in list context
    my %digest = reverse map +( split / / ),
      git::show_ref '--head';
} ) . q{
    return \%digest;
};

# Git::Database::Role::RefWriter
quote_sub "${package}::put_ref", q{
    my ( $self, $refname, $digest ) = @_;
} . sprintf( $wrapper, q{
    git::update_ref( $refname, $digest );
} );

quote_sub "${package}::delete_ref", q{
    my ( $self, $refname ) = @_;
} . sprintf( $wrapper, q{
    git::update_ref( '-d', $refname );
} );

with
  'Git::Database::Role::Backend',
  'Git::Database::Role::ObjectReader',
  'Git::Database::Role::ObjectWriter',
  'Git::Database::Role::RefReader',
  'Git::Database::Role::RefWriter',
  ;

1;

__END__

=pod

=for Pod::Coverage
  has_object_checker
  has_object_factory
  DEMOLISH
  hash_object
  get_object_attributes
  get_object_meta
  all_digests
  put_object
  refs
  put_ref
  delete_ref

=head1 NAME

Git::Database::Backend::Git::Sub - A Git::Database backend based on Git::Sub

=head1 SYNOPSIS

    # Git::Sub does not offer an OO interface
    $dir = 'path/to/some/git/repository/';

    # let Git::Database figure it out by itself
    my $db = Git::Database->new( store => $dir );

=head1 DESCRIPTION

This backend reads and write data from a Git repository using the
L<Git::Sub> Git wrapper.

=head2 Git Database Roles

This backend does the following roles
(check their documentation for a list of supported methods):
L<Git::Database::Role::Backend>,
L<Git::Database::Role::ObjectReader>,
L<Git::Database::Role::ObjectWriter>,
L<Git::Database::Role::RefReader>,
L<Git::Database::Role::RefWriter>.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>

=head1 COPYRIGHT

Copyright 2016 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
