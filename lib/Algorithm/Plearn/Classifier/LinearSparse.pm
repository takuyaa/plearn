package Algorithm::Plearn::Classifier::LinearSparse;

use strict;
use warnings;

use PDL;
use PDL::NiceSlice;
use Mouse;
use DDP;

has 'params' => (
    is => 'rw',
    default => sub {
        +{
            epoch  => 0,
            target_label => 0,
            weight => zeroes(1, 3),
        }
    }
);

has 'target_label' => ( is => 'rw' );

sub BUILD {
    my ($self) = @_;
    $self->params->{target_label} //= $self->target_label;
}

# $data: arrayref
sub predict {
    my ($self, $data) = @_;
    die 'Model is not trained yet' unless defined($self->params->{weight});
    return unless defined($data);        # No data

    my ($data_dim, $rows) = $data->dims;
    return unless $rows;                 # $data has no rows

    my $w = $self->params->{weight};
    my $weight_dim = [$w->dims]->[1];
    $w->reshape(1, $data_dim)      if $weight_dim < $data_dim; # extend weight

    # Compute y
    my $m = [$data->dims]->[1]; # Number of data
    my $y;
    eval {
        # $weight が零行列のとき PDL::CCS::Nd がエラー
        $y = $data x $w(0, 0:($data_dim-1));
        $y = transpose($y->todense);
    };
    $y = zeroes($m, 1) if $@;

    where($y, $y <= 0) .= -1;
    where($y, $y >  0) .= 1;
    return $y;
    #my $p = ($y) <= 0; # 1 at the data where prediction is false
    #return $p;
}

# $data: CCS::Nd (with bias at index 0)
# $labels: PDL piddle
sub train {
    my ($self, $data, $labels) = @_;
    return unless defined($data);        # No data
    return unless defined($labels);      # No label

    my ($data_dim, $rows) = $data->dims;
    return unless $rows;                 # $data has no rows

    my ($label_dim) = $labels->dims;
    return unless $label_dim;            # Empty piddle
    return unless $rows == $label_dim;   # Dimension mismatch

    # Init weight vector with 0
    $self->params->{weight} //= zeroes(1, $data_dim);

    my $w = $self->params->{weight};

    my $w_dim = [$w->dims]->[1];
    $w->reshape(1, $data_dim)   if $w_dim < $data_dim; # Extend weight

    # in-place で更新
    $self->update_weight($data, $labels, $w(0, 0:($data_dim-1)));

    # print $w(0, 0:100);
}

sub update_weight {
    my ($self, $data, $labels, $weight) = @_;

    $self->params->{epoch} //= 0;
    $self->params->{epoch}++;


    # Compute y
    my $m = [$data->dims]->[1]; # Number of data
    my $y;
    eval {
        # $weight が零行列のとき PDL::CCS::Nd がエラー
        $y = $data x $weight;
        $y = transpose($y->todense);
    };
    $y = zeroes($m, 1) if $@;


    # Learning rate
    my $eta = 1;
    # my $eta = 1 / $self->params->{epoch};
    # my $eta = 1 / sqrt($self->params->{epoch});

    # Prepare t
    my $t = $labels->copy;
    where($t, $labels != $self->target_label) .= -1;
    where($t, $labels == $self->target_label) .= 1;

    print $y;
    print $t;

    my $f = ($t * $y) <= 0; # 1 at the data where prediction is false
    my $fault = sumover $f;
    warn "fault: $fault";
    # return $weight_ccs unless $fault;
    return unless $fault;

    my $g = ($f * $t) * $eta / $m;
    print $g;
    my $g_ccs = $g->toccs;
    return if $g_ccs->_nzvals->isempty;

    my $grad_w = $g_ccs x $data;
    # my $grad_w = $g x $data; # error: Dense x Sparse
    my $gd = $grad_w->todense;
    print $gd(0:100, 0);

    # 最初から $t, $y(labels) を列ベクトルにしておけば不要？
    $grad_w = transpose($grad_w); # TODO xchg にする(高速？)

    # CCS どうしの足し算はおかしくなる (0 要素のある次元は無視される)
    # (1, 2, 3) + (0, 0, 1) => (0, 0, 4)
    # $weight_ccs = $weight_ccs + $grad_w;

    # Add non-zero values in-place
    # piddle + CCS::Nd
    # dense_plus_sparse($weight, $grad_w);
    $weight += $grad_w->todense;
}

# 密ベクトルのほうに疎ベクトルの非零要素を足しこむ (in-place)
# $dense と $ccs はどちらも、1行のベクトル
# TODO パフォーマンス改善
# TODO 次元が異なる場合の処理
sub dense_plus_sparse {
    my ($dense, $ccs) = @_;

    my $whichnd = $ccs->whichND();
    my $vals    = $ccs->whichVals();

    my $non_zero_vals = [$vals->dims]->[0];
    for (my $i = 0; $i < $non_zero_vals; $i++) {
        my $col = $whichnd(0, $i)->sclr;
        my $row = $whichnd(1, $i)->sclr;
        my $val = $vals($i);
        # print "( $col , $row ) = $val\n";

        $dense($col, $row) += $val;
    }
}

__PACKAGE__->meta->make_immutable();

1;
