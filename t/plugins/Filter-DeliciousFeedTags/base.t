use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Filter::DeliciousFeedTags
--- input config
plugins:
  - module: Filter::DeliciousFeedTags
--- expected
ok 1, $block->name;

=== Loading Filter::DeliciousFeedTags
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - http://del.icio.us/rss/nagayama
  - module: Filter::DeliciousFeedTags
--- expected
ok grep scalar @{$_->tags} > 1, $context->update->feeds->[0]->entries;
