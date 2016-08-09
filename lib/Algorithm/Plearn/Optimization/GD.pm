package Algorithm::Plearn::Optimization::GD;

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

    my $gradient_w = [];
    my $gradient_b = 0;
    for (my $i = 0; $i < @$data; $i++) {
        my $x = $data->[$i];
        my $label = $labels->[$i];
        my ($grad_w, $grad_b) = $classifier->gradient_loss($x, $label);
        next unless $grad_w;
        for (my $j = 0; $j < @$x; $j++) {
            $gradient_w->[$j] += $self->eta * $grad_w->[$j];
        }
        $gradient_b += $grad_b;
    }
    # update weights
    for (my $i = 0; $i < @$gradient_w; $i++) {
        $classifier->weight->[$i] += $self->eta * $gradient_w->[$i] / @$data;
    }
    $classifier->bias($classifier->bias + ($self->eta * $gradient_b / @$data));
    # count up t (update count)
    $self->params->{t}++;
}

sub eta {
    my ($self) = @_;
    # return $self->params->{initial_eta} / $self->params->{t}; # decay learning coefficient
    return $self->params->{initial_eta} / sqrt($self->params->{t}); # slow decay learning coefficient
}

__PACKAGE__->meta->make_immutable();

1;
