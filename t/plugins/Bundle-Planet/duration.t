use strict;
use FindBin;
use File::Path;
use t::TestPlagger;

test_requires('Time::Duration::Parse');

plan 'no_plan';

our $dir    = "$FindBin::Bin/planet";
our $output = "$dir/index.html";

run_eval_expected;

END {
    rmtree $dir if $dir && -e $dir;
}

__END__

=== Test duration = 0
--- input config output_file
global:
  log:
    level: error
  assets_path: $FindBin::Bin/../../../assets
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file:///$FindBin::Bin/../../samples/nasty.xml
  - module: Bundle::Planet
    config:
      dir: $main::dir
      title: Planet Foobar
      url: http://planet.plagger.org/
      theme: sixapart-std
      stylesheet: foo.css
      duration: 0
--- expected
like $block->input, qr!<p>foo bar <a href="foo\.html">baz</a></p>!;
