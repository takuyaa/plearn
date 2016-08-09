package Algorithm::Plearn::Optimization::SGD;

use strict;
use warnings;
use utf8;
use Mouse;

has 'params' => (is => 'rw', default => sub { +{} });

sub BUILD {
    my ($self) = @_;
    $self->params->{t} //= 1;
    $self->params->{initial_eta} //= 1;
}

sub update {
    my ($self, $classifier, $data, $labels) = @_;
    for (my $i = 0; $i < @$data; $i++) {
        $self->_update($classifier, $data->[$i], $labels->[$i]);
    }
}

sub _update {
    my ($self, $classifier, $x, $label) = @_;
    my ($grad_w, $grad_b) = $classifier->gradient_loss($x, $label);
    $self->params->{t}++; # t をインクリメントするのはパラメータ更新するときだけ？
    return unless $grad_w;
    for (my $i = 0; $i < @$x; $i++) {
        $classifier->weight->[$i] += $self->eta * $grad_w->[$i];
    }
    $classifier->bias($classifier->bias + $self->eta * $grad_b);
    # $self->params->{t}++; # t をインクリメントするのはパラメータ更新するときだけ

    # heuristics of SGD:
    # leaning coefficient for bias is multiplied by 0.01
    # cf. L. Bottou. Stochastic Gradient Descent (v.2)
    #     http://leon.bottou.org/projects/sgd
    # $classifier->bias($classifier->bias + ($self->eta * $grad_b * 0.01));
}

sub eta {
    my ($self) = @_;
    #return $self->params->{initial_eta} / $self->params->{t}; # decay learning coefficient
    return $self->params->{initial_eta} / sqrt($self->params->{t}); # slow decay learning coefficient
}

__PACKAGE__->meta->make_immutable();

1;
