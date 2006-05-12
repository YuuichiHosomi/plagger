package Plagger::Plugin::Filter::FetchEnclosure;
use strict;
use base qw( Plagger::Plugin );

use File::Spec;
use File::Path;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&filter,
    );
}

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    defined $self->conf->{dir} or Plagger->context->error("config 'dir' is not set.");
    unless (-e $self->conf->{dir} && -d _) {
        Plagger->context->log(warn => $self->conf->{dir} . " does not exist. Creating");
        mkpath $self->conf->{dir};
    }
}

sub filter {
    my($self, $context, $args) = @_;

    my $ua = Plagger::UserAgent->new;
    for my $enclosure ($args->{entry}->enclosures) {
        my $path = File::Spec->catfile($self->conf->{dir}, $enclosure->filename);
        $context->log(info => "fetch " . $enclosure->url . " to " . $path);
        $ua->mirror($enclosure->url, $path);
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::FetchEnclosure - Fetch enclosure(s) in entry

=head1 SYNOPSIS

  - module: Filter::FetchEnclosure
    config:
      dir: /path/to/files

=head1 DESCRIPTION

This plugin downloads enclosure files set for each entry.

=head1 TODO

=over 4

=item Support asynchronous download using POE

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
