#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

# This file was automatically generated by Dist::Zilla::Plugin::PodCoverageTests.
# and adapted to only load backend modules that have their prerequisites installed

use Test::Pod::Coverage 1.08;
use Pod::Coverage::TrustPod;

use Test::More;
use lib 't/lib';
use TestUtil;

my %backend = map +( $_ => 1 ), None => available_backends();
my @modules =
  grep /^Git::Database::Backend::(.*)/
  ? exists $backend{$1}
  : 1,
  all_modules();

pod_coverage_ok( $_, { coverage_class => 'Pod::Coverage::TrustPod' } )
  for sort @modules;

done_testing;