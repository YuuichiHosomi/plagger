package Plagger::Plugin::Publish::iCal;
use strict;
use base qw( Plagger::Plugin );

use File::Spec;
use Data::ICal;
use Data::ICal::Entry::Event;
use DateTime::Duration;
use Plagger::Util;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.feed' => \&publish_feed,
        'plugin.init ' => \&plugin_init,
    );
}

sub plugin_init {
    my($self, $context) = @_;

    my $dir = $self->conf->{dir};
    unless (-e $dir && -d _) {
        mkdir $dir, 0755 or $context->error("Failed to mkdir $dir: $!");
    }
}

sub publish_feed {
    my($self, $context, $args) = @_;

    my $feed = $args->{feed};
    my $ical = Data::ICal->new;
    $ical->add_properties(
        'X-WR-CALNAME'  => $feed->title,
    );

    for my $entry ($feed->entries) {
        my $date  = $entry->date;
        my $event = Data::ICal::Entry::Event->new;

        my $tz = $date->time_zone;
        my %param;
        if (!$tz->is_floating && $tz->name ne 'UTC' && !$tz->isa('DateTime::TimeZone::OffsetOnly')) {
            # don't set TZID if tz name is like '+0900'
            $param{TZID} = $tz->name;
        }

        my($dtstart, $dtend);
        if ($date->hms eq '00:00:00') {
            $dtstart = [ $date->strftime('%Y%m%d'), { %param, VALUE => 'DATE' } ];
            $dtend   = [ $date->strftime('%Y%m%d'), { %param, VALUE => 'DATE' } ];
        } else {
            $dtstart = [ iso8691_full($date), \%param ];
            $dtend   = [ iso8691_full($date), \%param ];
        }

        $event->add_properties(
            summary     => $entry->title,
            description => $entry->summary || $entry->body || '', # xxx plaintext
            dtstart     => $dtstart,
            dtend       => $dtend,
        );
        $ical->add_entry($event);
    }

    my $file = Plagger::Util::filename_for($feed, $self->conf->{filename} || '%i.ics');
    my $path = File::Spec->catfile($self->conf->{dir}, $file);

    my $data = $ical->as_string;
    utf8::decode($data) unless utf8::is_utf8($data);

    open my $output, ">:utf8", $path or $context->error("$path: $!");
    print $output $data;
    close $output;

    $context->log(info => "Wrote iCalendar file to $path");
}

sub iso8691_full {
    my $date = shift;
    my $iso  = $date->strftime('%Y%m%dT%H%M%S');
    $iso .= $date->time_zone->name eq 'UTC' ? 'Z' : '';
    $iso;
}

1;
__END__

=head1 NAME

Plagger::Plugin::Publish::iCal - Produces iCal file out of the feed

=head1 SYNOPSIS

  - module: Publish::iCal
    config:
      dir: /path/to/dir

=head1 DESCRIPTION

Publish::iCal creates iCal (.ics) files using feed items. Every feed
is a calendar and each entry is a schedule item. Entry's posted
date/time is used as a schedule date/time and so on.

=head1 CONFIG

=over 4

=item dir

Directory to save ics files in.

=item filename

filename to save ics files as. Defaults to I<%i.ics>.

=back

=head1 AUTHOR

Kentaro Kuribayashi

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<Data::ICal>

=cut
