package Algorithm::Plearn::Util::DenseVector::Test;

use strict;
use warnings;

use base qw(Test::Class);
use Test::More;
use Test::Deep;
use Algorithm::Plearn::Util::DenseVector;

my $target;

sub setup : Test(setup) {
    $target = Algorithm::Plearn::Util::DenseVector->new;
}

sub test_add_element : Tests {
    is $target->size, 0, 'size is 0 at first';
    is $target->add_element(1), 1;
    is $target->add_element(7), 2;
    is $target->add_element(3), 3;
    is $target->add_element(2), 4;

    my $v = $target->create_vector;
    ok defined $v;
    is $v->at(0), 1;
    is $v->at(1), 7;
    is $v->at(2), 3;
    is $v->at(3), 2;
}

__PACKAGE__->runtests;

1;
