package Algorithm::Plearn::Datasets::Iris::Test;

use strict;
use warnings;

use base qw(Test::Class);
use Algorithm::Plearn::Datasets::Iris;
use Test::More;

my $target;

sub setup : Test(setup) {
    $target = Algorithm::Plearn::Datasets::Iris->new;
}

sub test_load : Tests {
    my $dataset = $target->load();

    ok $dataset;

    ok $dataset->{data};
    is scalar(@{$dataset->{data}}), 150;

    ok $dataset->{feature_names};
    is scalar(@{$dataset->{feature_names}}), 4;
    is_deeply $dataset->{feature_names}, [ 'Sepal.Length', 'Sepal.Width', 'Petal.Length', 'Petal.Width' ];

    ok $dataset->{target};
    is scalar(@{$dataset->{target}}), 150;

    ok $dataset->{target_names};
    is scalar(@{$dataset->{target_names}}), 3;
    is_deeply $dataset->{target_names}, [ 'setosa', 'versicolor', 'virginica' ];
}

__PACKAGE__->runtests;

1;
