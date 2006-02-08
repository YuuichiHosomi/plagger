package Plagger::Rules;
use strict;

use List::Util qw(reduce);

our %Ops = (
    AND  => [ sub { $_[0] && $_[1] } ],
    OR   => [ sub { $_[0] || $_[1] } ],
    XOR  => [ sub { $_[0] xor $_[1] } ],
    NAND => [ sub { $_[0] && $_[1] }, 1 ],
    NOR  => [ sub { $_[0] || $_[1] }, 1 ],
);

sub new {
    my($class, $op, @rules) = @_;
    my $ops_sub = $Ops{uc($op)}
        or Plagger->context->error("operator $op not supported");

    bless {
        ops_sub => $ops_sub->[0],
        ops_not => $ops_sub->[1],
        rules => [ map Plagger::Rule->new($_), @rules ],
    }, $class;
}

sub dispatch {
    my($self, $hook, $args) = @_;

    my @bool;
    for my $rule (@{ $self->{rules} }) {
        next unless $rule->can_run($hook);
        push @bool, ($rule->dispatch($args) ? 1 : 0);
    }

    # can't find rules for this phase: execute it
    return 1 unless @bool;

    my $bool = reduce { $self->{ops_sub}->($a, $b) } @bool;
    $bool = !$bool if $self->{ops_not};
    $bool;
}

1;
