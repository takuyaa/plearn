use strict;
use warnings;

use base qw(Test::Class);
use Test::More;
use Test::Deep;
use Algorithm::Plearn::Preprocessing::MinMaxScaler;

my $target;

sub setup : Test(setup) {
    $target = Algorithm::Plearn::Preprocessing::MinMaxScaler->new;
}

sub test_fit : Tests {
    my $X = [
        [1, 1, 1],
        [2, 2, 2],
        [3, 3, 3]
    ];
    $target->fit($X);
    my $expected = {
        min => [1, 1, 1],
        max => [3, 3, 3],
    };
    cmp_deeply $target->{params}, $expected, 'fit params';
}

sub test_fit_transform : Tests {
    my $X = [
        [1, 1, 1],
        [2, 2, 2],
        [3, 3, 3]
    ];
    $target->fit($X);
    my $scaled = $target->transform($X);
    my $expected = [
        [0, 0, 0],
        [0.5, 0.5, 0.5],
        [1, 1, 1],
    ];
    cmp_deeply $scaled, $expected, 'scale';
}

sub test_fit_die_same_values : Tests {
    my $X = [ [1], [1], [1] ];
    eval { $target->fit($X, 1); };
    ok $@;
}

sub test_transform_die_before_fit : Tests {
    my $X = [ [1, 1, 1], [2, 2, 2], [3, 3, 3] ];
    eval { $target->transform($X); };
    ok $@;
}

__PACKAGE__->runtests;

1;
