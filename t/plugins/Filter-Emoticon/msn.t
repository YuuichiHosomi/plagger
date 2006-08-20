use strict;
use t::TestPlagger;

test_plugin_deps;
test_requires('Text::Emoticon::MSN', 0.03);
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Filter::Emoticon
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: foo
      entry:
        - title: test entry
          body: hello :)
  - module: Filter::Emoticon
    config:
      driver: MSN
    option:
      strict: 1
      xhtml: 0
--- expected
ok 1, $block->name;
is $context->update->feeds->[0]->entries->[0]->body, 'hello <img src="http://messenger.msn.com/Resource/emoticons/regular_smile.gif" />';
