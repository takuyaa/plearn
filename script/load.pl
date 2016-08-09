use strict;
use warnings;
use utf8;

use Algorithm::Plearn::Datasets::Iris;
use Algorithm::Plearn::Datasets::20NewsGroupsBinary;
use Algorithm::Plearn::Optimization::GD;
use Algorithm::Plearn::Optimization::SGD;
use Algorithm::Plearn::Classifier::Linear::Perceptron;
use Algorithm::Plearn::Classifier::Linear::SVM;
use Algorithm::Plearn::Classifier::LinearSparse;
use Algorithm::Plearn::Metrics qw(count precision recall f1 accuracy);
use Algorithm::Plearn::Preprocessing::MinMaxScaler;
use List::Util qw(shuffle);

use PDL;
use PDL::CCS::Nd;
use DDP;
my $ITERATION = 1;


# Load dataset
# my $iris    = Algorithm::Plearn::Datasets::Iris->new;
# my $dataset = $iris->load();
my $news20 = Algorithm::Plearn::Datasets::20NewsGroupsBinary->new(chunksize => 10);
# print "loading ...\n";
# my $dataset = $news20->load_as_ccs;
# my $dataset = $news20->load;
# print "done\n";



# Preprocessing
# my $scaler = Algorithm::Plearn::Preprocessing::MinMaxScaler->new;
# $scaler->fit($dataset->{data});
# my $scaled_data = $scaler->transform($dataset->{data}); # Scale
# my ($data, $target) = ($scaled_data, $dataset->{target});
# my ($data, $target) = _shuffle_dataset($scaled_data, $dataset->{target}); # Shuffle dataset if SGD
# my ($data, $target) = ($dataset->{data}, $dataset->{target});




my $target_label = 0;
# Setup classifier
# バッチ学習とオンライン学習でわけるべきかも
# Algorithm::Plearn::Optimization::Batch::GD とか
my $gd = Algorithm::Plearn::Optimization::GD->new(params => { initial_eta => 1 });
my $sgd = Algorithm::Plearn::Optimization::SGD->new(params => { initial_eta => 1 });
# my $classifier = Algorithm::Plearn::Classifier::Linear->new({ target_label => $target_label, optimization => $sgd });
# my $classifier = Algorithm::Plearn::Classifier::Linear::SVM->new({ target_label => $target_label, optimization => $sgd });
my $classifier = Algorithm::Plearn::Classifier::LinearSparse->new({ target_label => $target_label });

# Classifier::Linear::HingeLoss としてまとめる？
# 損失関数が違うだけ (ロジスティック回帰も)
# TODO params オブジェクトの構造 (GD とかをどうやって認識させるか？クラス名または 'GD' のような文字列？)
# TODO decay の式も外から渡せるように（またはパラメータで渡す）
# GD
#my $classifier = Algorithm::Plearn::Classifier::Linear::Perceptron->new({ target_label => 2, optimization => $gd });
#my $classifier = Algorithm::Plearn::Classifier::Linear::SVM->new({ target_label => 2, optimization => $gd });
# SGD
# my $classifier = Algorithm::Plearn::Classifier::Linear::Perceptron->new({ target_label => 2, optimization => $sgd });
#my $classifier = Algorithm::Plearn::Classifier::Linear::SVM->new({ target_label => 2, optimization => $sgd });





# Train model
my $dataset;

my $datasets = [];

print "loading ...\n";
while (my $dataset = $news20->read) {
    push @$datasets, $dataset;
}
print "read done\n";

print "training ...\n";
my $st = (times)[0];
for (my $i = 0; $i < $ITERATION; $i++) {
    print "iteration: $i\n";
    foreach my $dataset (@$datasets) {
        my $data = $dataset->{data};
        my $target = $dataset->{target};
        $classifier->train($data, $target);
        # TODO 収束判定
    }
}
my $learn_time = (times)[0] - $st;
print "train done\n";
print "LearnTime: $learn_time\n";


# Evaluate model
# my $test = $scaler->transform($dataset->{data}); # Scale


my $tp = 0;
my $tn = 0;
my $fp = 0;
my $fn = 0;

foreach my $dataset (@$datasets) {
    my $data = $dataset->{data};
    my $target = $dataset->{target};

    my $target_predict = $classifier->predict($data)->unpdl->[0]; # un-piddle
    my $correct = [ map { $_ == $target_label ? 1 : -1 } @{$target->unpdl} ];
    my ($true_positive, $true_negative, $false_positive, $false_negative) = count($correct, $target_predict);
    $tp += $true_positive;
    $tn += $true_negative;
    $fp += $false_positive;
    $fn += $false_negative;
}

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
