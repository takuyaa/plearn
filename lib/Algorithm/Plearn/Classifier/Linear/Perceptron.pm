package Algorithm::Plearn::Classifier::Linear::Perceptron;

use strict;
use warnings;
use utf8;

use Mouse;
use Algorithm::Plearn::Classifier::Linear;

extends 'Algorithm::Plearn::Classifier::Linear';

sub gradient_loss {
    my ($self, $x, $label) = @_;
    my $t = $self->target_label eq $label ? 1 : -1;
    my $y = $self->_predict($x);

    return 0 if $t * $y >= 0;

    my $grad_w = [ map { $t * $_ if defined($_) } @$x ];
    my $grad_b = $t;

    return ($grad_w, $grad_b);
}

__PACKAGE__->meta->make_immutable();

1;
