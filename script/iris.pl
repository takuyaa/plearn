use strict;
use warnings;
use utf8;

use Algorithm::Plearn::Datasets::Iris;
use Algorithm::Plearn::Optimization::GD;
use Algorithm::Plearn::Optimization::SGD;
use Algorithm::Plearn::Classifier::Linear::Perceptron;
use Algorithm::Plearn::Classifier::Linear::SVM;
use Algorithm::Plearn::Metrics qw(count precision recall f1 accuracy);
use Algorithm::Plearn::Preprocessing::MinMaxScaler;
use List::Util qw(shuffle);
use DDP;

my $ITERATION = 10;
my $target_label = 2;
my $is_scale = 1;

# Load dataset
my $train_dataset = {};
my $test_dataset  = {};
my $iris    = Algorithm::Plearn::Datasets::Iris->new;
my $dataset = $iris->load();
my ($shuffled_data, $shuffled_target) = _shuffle_dataset($dataset->{data}, $dataset->{target});
$train_dataset->{data} = [ @$shuffled_data[0..99] ];
$train_dataset->{target} = [ @$shuffled_target[0..99] ];
$test_dataset->{data} = [ @$shuffled_data[100..149] ];
$test_dataset->{target} = [ @$shuffled_target[100..149] ];


# Preprocessing
my $data;
my $target;
my $test_data;
my $test_target;
if ($is_scale) {
    my $scaler = Algorithm::Plearn::Preprocessing::MinMaxScaler->new;
    $scaler->fit($dataset->{data});

    $data = $scaler->transform($train_dataset->{data}); # Scale
    $target = $train_dataset->{target};
    $test_data = $scaler->transform($test_dataset->{data}); # Scale
    $test_target = $test_dataset->{target};
} else {
    $data = $train_dataset->{data};
    $target = $train_dataset->{target};
    $test_data = $test_dataset->{data};
    $test_target = $test_dataset->{target};
}


# Setup optimizer
# バッチ学習とオンライン学習でわけるべきかも
# Algorithm::Plearn::Optimization::Batch::GD とか
my $gd = Algorithm::Plearn::Optimization::GD->new(params => { initial_eta => 1 });
my $sgd = Algorithm::Plearn::Optimization::SGD->new(params => { initial_eta => 1 });


# Setup classifier
# Classifier::Linear::HingeLoss としてまとめる？
# 損失関数が違うだけ (ロジスティック回帰も)
# TODO params オブジェクトの構造 (GD とかをどうやって認識させるか？クラス名または 'GD' のような文字列？)
# TODO decay の式も外から渡せるように（またはパラメータで渡す）
# GD
my $classifier = Algorithm::Plearn::Classifier::Linear::Perceptron->new({ target_label => $target_label, optimization => $gd });
# my $classifier = Algorithm::Plearn::Classifier::Linear::SVM->new({ target_label => $target_label, optimization => $gd });
# SGD
# my $classifier = Algorithm::Plearn::Classifier::Linear::Perceptron->new({ target_label => $target_label, optimization => $sgd });
# my $classifier = Algorithm::Plearn::Classifier::Linear::SVM->new({ target_label => $target_label, optimization => $sgd });


# Train model
my $st = (times)[0];

for (my $i = 0; $i < $ITERATION; $i++) {
    # print "iteration: $i\n";
    $classifier->train($data, $target);
    # TODO 収束判定
}
my $learn_time = (times)[0] - $st;
print "LearnTime: $learn_time\n";


# Evaluate model

my $target_predict = $classifier->predict($test_data);
my $correct = [ map { $_ == $target_label ? 1 : -1 } @{$test_target} ];
my ($true_positive, $true_negative, $false_positive, $false_negative) = count($correct, $target_predict);

my $tp = $true_positive;
my $tn = $true_negative;
my $fp = $false_positive;
my $fn = $false_negative;

_print_result($tp, $tn, $fp, $fn);

sub _print_result {
    my ($true_positive, $true_negative, $false_positive, $false_negative) = @_;

    my $p = precision($true_positive, $true_negative, $false_positive, $false_negative);
    my $r = recall($true_positive, $true_negative, $false_positive, $false_negative);
    my $f = f1($true_positive, $true_negative, $false_positive, $false_negative);
    my $a = accuracy($true_positive, $true_negative, $false_positive, $false_negative);

    print "\n";
    print "True Posi: $true_positive\n";
    print "True Nega: $true_negative\n";
    print "False Pos: $false_positive\n";
    print "False Neg: $false_negative\n";
    print "\n";
    print "Precision: $p\n";
    print "Recall   : $r\n";
    print "F value  : $f\n";
    print "Accuracy : $a\n";
}

# TODO Move to Datasets::Util package
sub _shuffle_dataset {
    my ($data, $target) = @_;

    my $data_shuffle   = [];
    my $target_shuffle = [];

    my $max = @{$data} - 1;
    my $index = [ shuffle 0..$max ];
    for (my $i = 0; $i < scalar(@{$index}); $i++) {
        $data_shuffle->[$i]   = $data->[$index->[$i]];
        $target_shuffle->[$i] = $target->[$index->[$i]];
    }
    return ($data_shuffle, $target_shuffle);
}
