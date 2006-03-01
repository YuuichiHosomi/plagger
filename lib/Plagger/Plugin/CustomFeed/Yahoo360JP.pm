package Plagger::Plugin::CustomFeed::Yahoo360JP;
use strict;
use base qw( Plagger::Plugin );

use DateTime::Format::Strptime;
use Encode;
use Time::HiRes;
use WWW::Mechanize;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'subscription.load' => \&load,
        'aggregator.aggregate.yahoo360jp' => \&aggregate,
    );
}

sub load {
    my($self, $context) = @_;

    my $feed = Plagger::Feed->new;
       $feed->type('yahoo360jp');
    $context->subscription->add($feed);
}

sub aggregate {
    my($self, $context, $args) = @_;

    # TODO: save cookies
    my $start = "https://login.yahoo.co.jp/config/login?.src=360&.done=http%3A%2F%2F360.yahoo.co.jp%2F%3F.login%3D1"; # SSL

    my $mech = WWW::Mechanize->new;
    $mech->get($start);
    $mech->submit_form(
        fields => {
            login  => $self->conf->{username},
            passwd => $self->conf->{password},
            '.persistent' => 'y',
        },
    );

    if ($mech->content =~ m!<span class="error">!) {
        $context->log(error => "Login to Yahoo! failed.");
        return;
    }

    $context->log(info => "Login to Yahoo! succeeded.");

    my $feed = Plagger::Feed->new;
    $feed->type('yahoo360jp');
    $feed->title('Yahoo! 360');
    $feed->link('http://360.yahoo.co.jp/friends/content.html');

    # get friends blogs
    $mech->get("http://360.yahoo.co.jp/friends/content.html");

    # preserve link to Hitokoto page here ... used later
    my $link = $mech->find_link( url_regex => qr/form_submitted=friends_content_head/ );

    my $re = decode('utf-8', <<'RE');
<div class="mgc_pic">
<table><tr><td><a href="(http://360\.yahoo\.co\.jp/profile-.*?)" title="(.*?)"><img src="(http://.*?)"  alt=".*?" height="(\d+)" width="(\d+)" border="0"></a></td></tr></table>
</div>


<div class="mgc_txt">
<a href="(http://blog\.360\.yahoo\.co\.jp/blog-.*?)">(.*?)</a><br/>
<a href="http://360\.yahoo\.co\.jp/profile-.*?" title=".*?">.*?</a><span class="fixd_xs">&nbsp;さん</span><br>
<span class="fixd_xs">((\d+)月\d+日 \d\d:\d\d)</span>
</div>
<div class="clear"></div>
</div>
RE

    my $now = Plagger::Date->now;
    my $format = DateTime::Format::Strptime->new(pattern => decode('utf-8', '%Y %m月%d日 %H:%M'));

    my $content = decode('utf-8', $mech->content);
    while ($content =~ /$re/g) {
         my $args = {
             profile  => $1,
             nickname => $2,
             icon     => $3,
             height   => $4,
             width    => $5,
             link     => $6,
             title    => $7,
             date     => $8,
             month    => $9,
         };

         if ($self->conf->{fetch_body}) {
             $args->{body} = $self->fetch_body($mech, $args->{link});
         }
         $self->add_entry($feed, $args, $now, $format);
    }

    $re = decode('utf-8', <<'RE');
<div class="mgc_pic">
<table><tr><td><a href="(http://360\.yahoo\.co\.jp/profile-.*?)" title="(.*?)"><img src="(http://.*?)"  alt=".*?" height="(\d\d)" width="(\d\d)" border="0"></a></td></tr></table>
</div>



<div class="mgc_txt">

<div class=".*?">

<div class="mgbp_blast_stxt">(?:<a href="(.*?)" target="new">(.*?)</a>|(.*?))</div>
<div class="mgbp_blast_sauthor"><span class="fixd_xs">((\d+)月\d+日 \d\d:\d\d)</span>&nbsp;&nbsp;<a href="http://360\.yahoo\.co\.jp/profile-.*?" title=".*?">.*?</a>&nbsp;<span class="fixd_xs">さん</span></div>
RE
    ;

    if ($link) {
        $mech->get($link->url);
        my $content = decode('utf-8', $mech->content);
        while ($content =~ /$re/g) {
            $self->add_entry($feed, {
                profile  => $1,
                nickname => $2,
                icon     => $3,
                height   => $4,
                width    => $5,
                link     => $6 || $1,
                title    => $7 || $8,
                date     => $9,
                month    => $10,
            }, $now, $format);
        }
    } else {
        $context->log(error => "Can't find link to Hitokoto page.");
    }

    $feed->sort_entries;
    $context->update->add($feed);
}

sub add_entry {
    my($self, $feed, $args, $now, $format) = @_;

    # hack for seeing December entries in January
    my $year = $args->{month} > $now->month ? $now->year - 1 : $now->year;
    my $date = "$year $args->{date}";

    my $entry = Plagger::Entry->new;
    $entry->title($args->{title});
    $entry->link($args->{link});
    $entry->author($args->{nickname});
    $entry->date( Plagger::Date->parse($format, $date) );
    $entry->body($args->{body}) if $args->{body};

    $entry->icon({
        title  => $args->{nickname},
        url    => $args->{icon},
        link   => $args->{profile},
        width  => $args->{width},
        height => $args->{height},
    });

    $feed->add_entry($entry);
}

sub fetch_body {
    my($self, $mech, $link) = @_;

    Plagger->context->log(info => "Fetch body from $link");
    $mech->get($link);
    my $content = decode('utf-8', $mech->content);
    if ($content =~ m!<div id="mgbp_body">\n(.*?)</div>!sg) {
        return $1;
    }
    return;
}

1;


