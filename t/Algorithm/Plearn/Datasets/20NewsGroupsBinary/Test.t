package Algorithm::Plearn::Datasets::20NewsGroupsBinary::Test;

use strict;
use warnings;

use base qw(Test::Class);
use Test::More;
use Test::Deep;
use Algorithm::Plearn::Datasets::20NewsGroupsBinary;

my $target;

sub setup : Test(setup) {
    $target = Algorithm::Plearn::Datasets::20NewsGroupsBinary->new;
}

sub test_read : Tests {
    my $dataset = $target->read;

    my ($col, $row) = $dataset->{data}->dims;
    is $row, 10;
    is $col, 1149964;

    is $dataset->{data}->at(0, 0), 1;
    is $dataset->{data}->at(40, 0), 0.087706;
    is $dataset->{data}->at(250397, 0), 0.087706;
    is $dataset->{data}->at(250398, 0), 0;

    cmp_deeply $dataset->{target}->unpdl, [0, 0, 0, 1, 1, 0, 1, 0, 0, 0];
    cmp_deeply $target->params->{target_names}, ['+1', '-1'];
    cmp_deeply $target->params->{target_map}, { '+1' => 0, '-1' => 1 };

    # もとの news20.binary を前提にしたテスト
    # TODO Add tests after implementing fetch function
    # is scalar(@{$dataset->{data}->[0]}), 3645;
    # cmp_deeply $dataset->{target}, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    # cmp_deeply $dataset->{target_names}, ['-1'];
    # cmp_deeply $dataset->{target_map}, { '-1' => 0 };
}

sub test_read_chunksize : Tests {
    $target = Algorithm::Plearn::Datasets::20NewsGroupsBinary->new(chunksize => 3);

    is $target->offset, 0;

    my $dataset = $target->read;
    is $target->offset, 3;
    is [$dataset->{data}->dims]->[1], 3;

    $dataset = $target->read;
    is $target->offset, 6;
    is [$dataset->{data}->dims]->[1], 3;
}

__PACKAGE__->runtests;

1;
