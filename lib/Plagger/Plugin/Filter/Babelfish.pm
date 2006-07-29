package Plagger::Plugin::Filter::Babelfish;
use strict;
use base qw( Plagger::Plugin );

use Plagger::UserAgent;
use WWW::Babelfish;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&update,
    );
}

sub update {
    my($self, $context, $args) = @_;

    my $service = $self->conf->{service} || 'Babelfish';
    my $source  = $self->conf->{source}  || 'English';
    my $destination = $self->conf->{destination} || 'Japanese';

    my $ua = Plagger::UserAgent->new;
    my $translator = new WWW::Babelfish(
        service => $service,
        agent => $ua->agent
    );
    unless (defined $translator) {
        $context->log(error => "Babelfish is not available");
        return;
    }

    my $title = $args->{entry}->title;
    my $title_tr = $translator->translate(
        source => $source,
        destination => $destination,
        text => $title,
        delimiter => "\n\n",
    );
    unless (defined $title_tr) {
        $context->log(error => "Translation failed: " . $translator->error);
        return;
    }
    $title_tr = $title . "\n\n" . $title_tr if $self->conf->{prepend_org};

    $args->{entry}->title($title_tr);

    sleep 1;

    my $body = $args->{entry}->body;
    my $body_tr = $translator->translate(
        source => $source,
        destination => $destination,
        text => $body,
        delimiter => "\n\n",
    );
    unless (defined $body_tr) {
        $context->log(error => "Translation failed: " . $translator->error);
        return;
    }
    $body_tr = $body . "\n\n" . $body_tr if $self->conf->{prepend_org};

    $args->{entry}->body($body_tr);
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::Babelfish - translate via WWW::Babelfish

=head1 SYNOPSIS

  - module: Filter::Babelfish
    config:
      source: English
      destination: Japanese
      service: Google
      prepend_org: 1

=head1 DESCRIPTION

This plugin translates each entry body via Bebelfish.
See L<WWW::Babelfish> for details.

=head1 CONFIG

=over 4

=item service

Which translator to use ('Babelfish' or 'Google').
Defaults to 'Babelfish'.

=item source

Which language the original entry is.
Defaults to 'English'.

=item destination

Which language the translated entry should be.
Defaults to 'Japanese'.

=item prepend_org

When set to 1, prepends original entry body. Defaults to 0.

=back

=head1 AUTHOR

Kenichi Ishigaki

=head1 SEE ALSO

L<Plagger>, L<WWW::Babelfish>

=cut
