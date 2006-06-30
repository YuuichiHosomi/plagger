use strict;
use Test::More tests => 5;
use FindBin;
use File::Spec;

use Plagger;

my $db = File::Spec->catfile($FindBin::Bin, 'dedupe.db');
unlink $db if -e $db;

my $config = {
    global => {
        log => {
            level => "debug",
        },
    },
    plugins => [
        {
            module => "CustomFeed::Debug",
            config => {
                title => "foo",
                url => "http://localhost/",
                entry => [
                    {
                        title => "foo1",
                        date => "2006-06-29 19:00:00",
                        link => "http://localhost/1/",
                    },
                    {
                        title => "foo2",
                        date => "2006-06-29 19:00:00",
                        link => "http://localhost/2/",
                    },
                ],
            }
        },
        {
            module => "Filter::Rule",
            rule => {
                module => "Deduped",
                path => $db,
            },
        },
        {
            module => "Test::Deduped",
        },
    ],
};

my $log; $SIG{__WARN__} = sub { $log .= "@_" };

my $expect_count = 2;

Plagger->bootstrap(config => $config);
unlike $log, qr/Deleting/;

Plagger->bootstrap(config => $config);
like $log, qr/Deleting/;

# Add newer entry
unshift @{ $config->{plugins}->[0]->{config}->{entry} }, {
    title => "foo2",
    date => "2006-06-29 19:15:00",
    link => "http://localhost/2/",
};

undef $log;
$expect_count = 1;

Plagger->bootstrap(config => $config);
unlike $log, qr/Deleting/;

unlink $db if -e $db;

package Plagger::Plugin::Test::Deduped;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;

    $context->register_hook(
        $self,
        'publish.feed' => \&test,
    );
}

sub test {
    my($self, $context, $args) = @_;
    ::is $args->{feed}->count, $expect_count;
}
