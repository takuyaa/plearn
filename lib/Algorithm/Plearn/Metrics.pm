package Algorithm::Plearn::Metrics;

use strict;
use warnings;
use utf8;

use Exporter 'import';
our @EXPORT_OK = qw(count precision recall f1 accuracy);


sub accuracy {
    my ($tp, $tn, $fp, $fn) = @_;
    return ($tp + $tn) / ($tp + $tn + $fp + $fn);
}

sub auc {
    # http://sucrose.hatenablog.com/entry/2013/05/25/133021
    my ($recall, $precision) = @_;
    # my ($fpr, $tpr) = @_; # false positive rate, true positive rate
}

sub average_precision {
}

sub f1 {
    my ($tp, $tn, $fp, $fn) = @_;
    my $precision = precision($tp, $tn, $fp, $fn);
    my $recall = recall($tp, $tn, $fp, $fn);
    my $pr = $precision + $recall;
    return 1 if $pr == 0;
    return 2 * $precision * $recall / $pr;
}

sub precision {
    my ($tp, $tn, $fp, $fn) = @_;
    my $all_positive = $tp + $fp;
    return 1 if $all_positive == 0;
    return $tp / $all_positive;
}

sub recall {
    my ($tp, $tn, $fp, $fn) = @_;
    my $all_correct = $tp + $fn;
    return 1 if $all_correct == 0;
    return $tp / $all_correct;
}

sub roc_auc {
}

sub count {
    my ($label, $label_predict) = @_;

    my $true_positive  = 0;
    my $true_negative  = 0;
    my $false_positive = 0;
    my $false_negative = 0;

    for (my $i = 0; $i < @$label; $i++) {
        if (0 < $label_predict->[$i]) {
            if ($label->[$i] == $label_predict->[$i]) {
                $true_positive++;
            } else {
                $false_positive++;
            }
        } else {
            if ($label->[$i] == $label_predict->[$i]) {
                $true_negative++;
            } else {
                $false_negative++;
            }
        }
    }
    return ($true_positive, $true_negative, $false_positive, $false_negative);
}

1;
