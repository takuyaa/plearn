package Algorithm::Plearn::Util::SparseMatrix::Test;

use strict;
use warnings;

use base qw(Test::Class);
use Test::More;
use Test::Deep;
use Algorithm::Plearn::Util::SparseMatrix;

my $target;

sub setup : Test(setup) {
    $target = Algorithm::Plearn::Util::SparseMatrix->new;
}

sub test_add_and_get_element : Tests {
    is $target->size, 0, 'size is 0';

    my $dat0 = [0, 0, 1];
    is $target->add_element(@$dat0), 1, 'size to 1';
    cmp_deeply [$target->get_element(0)], $dat0, 'got given col:0, row:0, val:1';

    my $dat1 = [0, 1, 3];
    is $target->add_element(@$dat1), 2, 'size to 2';
    cmp_deeply [$target->get_element(1)], $dat1, 'got given col:1, row:0, val:2';

    my $dat2 = [1, 0, 2];
    is $target->add_element(@$dat2), 3, 'size to 3';
    cmp_deeply [$target->get_element(2)], $dat2, 'got given col:0, row:1, val:3';

    my $dat3 = [1, 1, 4];
    is $target->add_element(@$dat3), 4, 'size to 4';
    cmp_deeply [$target->get_element(3)], $dat3, 'got given col:1, row:1, val:4';
}

sub test_create_matrix : Tests {
    is $target->size, 0;

    $target->add_element(0, 0, 1);
    $target->add_element(0, 1, 3);
    $target->add_element(1, 0, 2);
    $target->add_element(1, 1, 4);

    my $ccs = $target->create_matrix;
    is $ccs->at(0, 0), 1, 'val:1 at (0, 0)';
    is $ccs->at(0, 1), 3, 'val:3 at (0, 1)';
    is $ccs->at(1, 0), 2, 'val:2 at (1, 0)';
    is $ccs->at(1, 1), 4, 'val:4 at (1, 1)';
}

__PACKAGE__->runtests;

1;
