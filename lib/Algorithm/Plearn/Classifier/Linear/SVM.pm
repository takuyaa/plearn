package Algorithm::Plearn::Classifier::Linear::SVM;

use strict;
use warnings;
use utf8;

use Mouse;
use Algorithm::Plearn::Classifier::Linear;

extends 'Algorithm::Plearn::Classifier::Linear';

# Hinge loss function
sub gradient_loss {
    my ($self, $x, $label) = @_;
    my $t = $self->target_label eq $label ? 1 : -1;
    my $y = $self->_predict($x);

    return 0 if $t * $y >= 1; # hinge

    my $grad_w = [ map { $t * $_ if defined($_) } @$x ];
    my $grad_b = $t;

    return ($grad_w, $grad_b);
}

__PACKAGE__->meta->make_immutable();

1;
