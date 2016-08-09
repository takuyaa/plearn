package Algorithm::Plearn::Classifier::Linear;

use strict;
use warnings;

use Mouse;

has 'weight' => ( is => 'rw' );
has 'bias' => ( is => 'rw' );
has 'target_label' => ( is => 'rw' );
has 'optimization' => ( is => 'rw', required => 1 );

# $data: arrayref
sub predict {
    my ($self, $data) = @_;
    die 'Model is not trained yet' unless $self->weight;
    return [] unless $data;  # no data
    return [] unless @$data; # empty arrayref
    return [ map { $self->_predict($_) } @$data ];
}

sub _predict {
    my ($self, $x) = @_;
    my $y = $self->_y($x);
    return  1 if 0 < $y;
    return -1;
}

sub _y {
    my ($self, $x) = @_;
    # die 'Dimensions of data and weight vector did not match' unless scalar(@{$self->weight}) == scalar(@{$x});
    my $y = $self->bias;
    for (my $i = 0; $i < @$x; $i++) {
        $x->[$i] // next;
        $self->weight->[$i] // next;
        $y += $self->weight->[$i] * $x->[$i];
    }
    return $y;
}

# $data: arrayref
# $labels: arrayref
sub train {
    my ($self, $data, $labels) = @_;

    die 'Optimization method is not specified' unless $self->optimization;
    return unless $data;   # no data
    return unless @$data;  # empty arreyref
    return unless $labels;  # no label
    return unless @$labels; # empty arrayref

    $self->weight([ map { 0 } @{$data->[0]} ]) unless defined($self->weight);
    $self->bias(0) unless defined($self->bias);
    $self->optimization->update($self, $data, $labels);
}

# Same as Perceptron
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
