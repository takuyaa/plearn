package Algorithm::Plearn::Util::DenseVector;

use strict;
use warnings;

use PDL;
use PDL::NiceSlice;
use Mouse;

has 'initial_size' => (is => 'rw', default => 1024);
has 'size' => (is => 'rw', default => 0);
has '_vec' => (is => 'rw');

sub BUILD {
    my ($self) = @_;
    $self->_vec(zeroes($self->initial_size));
}

sub add_element {
    my ($self, $val) = @_;
    my ($dim) = $self->_vec->dims;
    my $index = $self->size;

    # Re-allocate extra memory
    $self->_extends if $self->size == $dim;

    $self->_vec->($index) .= $val;
    $self->size($self->size + 1);
    return $self->size;
}

sub get_element {
    my ($self, $index) = @_;
    return $self->_vec->at($index);
}

sub _extends {
    my ($self) = @_;
    my ($dim) = $self->_vec->dims;
    $self->_vec->reshape(2 * $dim);
}

# Creates and returns a PDL piddle
sub create_vector {
    my ($self) = @_;

    # Cut off redundancy area
    return $self->_vec->reshape($self->size);
}

__PACKAGE__->meta->make_immutable();

1;
