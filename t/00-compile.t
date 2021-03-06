use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058
# and adapted to only load backend modules that have their prerequisites installed

use Test::More;
use lib 't/lib';
use TestUtil;

my %backends = map
  +( join( '/', qw( Git Database Backend ), split /::/ ) . ".pm" => 1 ),
  available_backends();
  use Data::Dumper;print Dumper(\%backends);

my @module_files = (
    'Git/Database.pm',
    'Git/Database/Actor.pm',
    ( sort keys %backends ),
    'Git/Database/DirectoryEntry.pm',
    'Git/Database/Object/Blob.pm',
    'Git/Database/Object/Commit.pm',
    'Git/Database/Object/Raw.pm',
    'Git/Database/Object/Tag.pm',
    'Git/Database/Object/Tree.pm',
    'Git/Database/Role/Backend.pm',
    'Git/Database/Role/Object.pm',
    'Git/Database/Role/ObjectReader.pm',
    'Git/Database/Role/ObjectWriter.pm',
    'Git/Database/Role/PurePerlBackend.pm',
    'Git/Database/Role/RefReader.pm',
    'Git/Database/Role/RefWriter.pm'
);

plan tests => @module_files + ($ENV{AUTHOR_TESTING} ? 1 : 0);

# no fake home requested

my @switches = (
    -d 'blib' ? '-Mblib' : '-Ilib',
);

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-e', "require q[$lib]"))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { +require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


