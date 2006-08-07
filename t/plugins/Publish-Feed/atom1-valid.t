use strict;
use t::TestPlagger;

test_requires_network;
test_plugin_deps;

unless (-e "$ENV{HOME}/svn/feedvalidator") {
    plan skip_all => "You need to checkout feedvalidator in $ENV{HOME}/svn to run this test";
}

our $output = "$FindBin::Bin/atom.xml";

plan 'no_plan';
run_eval_expected;

END {
    unlink $output if $output && -e $output;
}

__END__

=== Atom 1.0 validation
--- input config output_file
global:
  log:
    level: error
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file:///$FindBin::Bin/../../samples/rss-full.xml
  - module: Publish::Feed
    config:
      format: Atom
      dir: $FindBin::Bin
      filename: atom.xml
--- expected
my $out = `$ENV{HOME}/svn/feedvalidator/src/demo.py $main::output A`;
like $out, qr/No errors or warnings/;



