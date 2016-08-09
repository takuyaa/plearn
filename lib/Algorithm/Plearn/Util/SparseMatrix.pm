package Algorithm::Plearn::Util::SparseMatrix;

use strict;
use warnings;

use PDL;
use PDL::NiceSlice;
use PDL::CCS::Nd;
use Mouse;

has 'initial_size' => (is => 'rw', default => 1024);
has 'size' => (is => 'rw', default => 0);
has '_vals' => (is => 'rw');
has '_indices' => (is => 'rw');

sub BUILD {
    my ($self) = @_;
    $self->_vals(zeroes($self->initial_size));
    $self->_indices(zeroes(2, $self->initial_size));
}

sub add_element {
    my ($self, $col, $row, $val) = @_;
    my ($dim) = $self->_vals->dims;
    my $index = $self->size;

    # Re-allocate extra memory
    $self->_extends if $self->size == $dim;

    $self->_vals->($index) .= $val;
    $self->_indices->(0, $index) .= $col;
    $self->_indices->(1, $index) .= $row;
    $self->size($self->size + 1);
    # my $v .= $self->_vals;
    # warn "$v\n";
    return $self->size;
}

sub get_element {
    my ($self, $index) = @_;
    my $col = $self->_indices->at(0, $index);
    my $row = $self->_indices->at(1, $index);
    my $val = $self->_vals->at($index);
    return ($col, $row, $val);
}

sub _extends {
    my ($self) = @_;
    my ($dim) = $self->_vals->dims;
    $self->_vals->reshape(2 * $dim);
    $self->_indices->reshape(2, 2 * $dim);
}

# Creates and returns a sparse matrix of PDL::CCS::Nd
sub create_matrix {
    my ($self) = @_;

    # Cut off redundancy area
    $self->_vals->reshape($self->size);
    $self->_indices->reshape(2, $self->size);

    # return PDL::CCS::Nd->newFromWhich($self->_indices, $self->_vals, (sorted => 1));
    return PDL::CCS::Nd->newFromWhich($self->_indices, $self->_vals);
}

__PACKAGE__->meta->make_immutable();

1;
