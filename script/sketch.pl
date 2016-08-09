use strict;
use warnings;
use DDP;
use PDL;
use PDL::NiceSlice;
use PDL::CCS::Nd;

# Sparse x Dense
# Sparse x Sparse



my $w = zeroes(1, 5);
$w(0, 0) .= 0;
$w(0, 1) .= 1;
$w(0, 2) .= 0;
$w->reshape(1, 10);
$w(0, 0:2);

# at と sclr の違いは？
#p $w->at(0, 0);
#p $w->sclr;


print "w";
print $w; # Slice してももとの piddle は変更されない
print "w(0, 0:2)";
print $w(0, 0:2);

my $ccs = pdl [[1, 2, 3],[4, 5, 6]];
$ccs = $ccs->toccs;
print "ccs";
print $ccs->todense;

my $dense = pdl [[1, 2]];
my @dd = $dense->dims; p @dd;
print $dense;
my @cd = $ccs->dims; p @cd;


# 行列積
my $ccs2 = $w(0, 0:2);
my $grad = $ccs x $ccs2->toccs; # 零行列だと失敗する
# slice: slice starts out of bounds in pos 0 (start is 0; source dim 0 runs 0 to -1) at /Users/takuya/Dropbox/workspace/plearn/local/lib/perl5/darwin-2level/PDL/CCS/Nd.pm line 1011.
print "grad";
print $grad->todense;

print "w";
print $w;
dense_plus_sparse($w(0, 0:2), $grad);

print "w + grad";
print $w;
print "\n";


# 密ベクトルのほうに疎ベクトルの非零要素を足しこむ (in-place)
# $dense と $ccs はどちらも、1行のベクトル
# TODO 次元が異なる場合の処理
sub dense_plus_sparse {
    my ($dense, $ccs) = @_;

    my $whichnd = $ccs->whichND();
    my $vals    = $ccs->whichVals();

    my $non_zero_vals = [$vals->dims]->[0];
    for (my $i = 0; $i < $non_zero_vals; $i++) {
        my $col = $whichnd(0, $i)->sclr;
        my $row = $whichnd(1, $i)->sclr;
        my $val = $vals($i)->sclr;
        print "( $col , $row ) = $val\n";

        $dense($col, $row) += $val;
    }
}




# [6, 7, 8] を [1, 2, 3, 4, 5] に上書き



# my $ccs = pdl [[1, 2, 3],[4, 5, 6]];
# $ccs = $ccs->toccs;
# # print $ccs->toccs; # toccs に副作用はない

# my $dense = pdl [1, 2, 3];
# $dense = transpose($dense);

# my $m = $ccs x $dense;
# print "sparse x dense -> sparse\n";
# print $m->todense;




##---------------------------------------------------------------------
## Example data

# my $dense = pdl [
#     [0, 0, 13],
#     [0, 22, 0]
# ];
# print "dense: $dense";

# my $whichND = $dense->whichND;                     ##-- which values are present?
# my $nzvals  = $dense->indexND($whichND);           ##-- ... and what are they?

# print "whichND: $whichND";
# print "indexND: $nzvals\n";


##---------------------------------------------------------------------
## Constructors etc.

# $ccs = PDL::CCS::Nd->newFromDense($dense,%args);           ##-- construct from dense matrix
# my $ccs = PDL::CCS::Nd->newFromWhich($whichND,$nzvals); ##-- construct from index+value pairs
# print "ccs : $ccs";
# $ccs = $ccs->float;
# my ($m, $n) = $ccs->dims;
# print "rows: $n\n";
# print "cols: $m\n";



##---------------------------------------------------------------------
## PDL API: Indexing

# my $e11 = $ccs->at(0, 0);
# print "n(1,1): $e11\n";
# my $e13 = $ccs->at(2, 0);
# print "n(1,3): $e13\n";

# $whichND = $ccs->whichND();
# print "ccs->whichND: $whichND";
# my $vals    = $ccs->whichVals();               ##-- like $ccs->indexND($ccs->whichND), but faster
# print "ccs->whichVals: $vals\n";
# my $which   = $ccs->which();
# print "ccs->which: $which\n";

# my $nzi   = $ccs->indexNDi($ndi);              ##-- guts for indexing methods
# my $ndi   = $ccs->n2oned($ndi);                ##-- returns 1d pseudo-index for $ccs

# my $ndi = 2;
# my $ivals = $ccs->indexND($ndi);

# my $xi = 1; my $yi = 3;
# my $ivals = $ccs->index2d($xi, $yi);
# $ivals = $ccs->index($flati);               ##-- buggy: no pseudo-threading!
# my $ccs2  = $ccs->dice_axis($vaxis,$vaxis_ix);


# $value = $ccs->at(@index);
# $ccs   = $ccs->set(@index,$value);


# 値の設定は .=

my $nzvals = zeroes(4);
$nzvals(0) .= 11;
$nzvals(1) .= 22;
$nzvals(2) .= 33;
$nzvals(3) .= 44;

my $whichND = zeroes(2, 4);
$whichND(0, 0) .= 0;
$whichND(1, 0) .= 1;
$whichND(0, 1) .= 1;
$whichND(1, 1) .= 0;
$whichND(0, 2) .= 2;
$whichND(1, 2) .= 0;
$whichND(0, 3) .= 2;
$whichND(1, 3) .= 2;

my $ccs2 = PDL::CCS::Nd->newFromWhich($whichND, $nzvals, (sorted => 1)); # 列->行の順でソートされている必要がある（でないと値が取れなくなる）


# 列の追加 (ただし PDL::CCS::Nd では対応していない)
#my $bias = pdl [ 1, 2, 3 ];
#my $b = transpose($bias);
#$ccs2->glue(0, $b);
#my $c = $b->append($ccs2->todense);
# print $c->todense;


# 0 以上の要素を 1 にした CCS
# my $ccs4 = $ccs2 > 0; # Same as $ccs2->gt(12);
# warn $ccs4->todense;


# my $p = pdl [ [1, 0, 1] ];
# my $data = pdl [ [3, 2, 1, 9, 7], [1, 2, 3, 4, 5], [9, 8, 7, 6, 5] ];
# my $pdim = [$p->dims]; p $pdim;
# my $ccs2dim = [$ccs2->dims]; p $ccs2dim;

# my $p_ccs = $p->toccs; # Same as PDL::CCS::Nd->newFromDense($p);
# my $r = $p_ccs x $ccs2; # Same as $p_ccs->matmult($ccs2);
# warn $r->todense;




# 値の取得は at()
# p $ccs2->at(0,0);
# p $ccs2->at(0,1);
# p $ccs2->at(1,0);
# p $ccs2->at(2,0);
# print "ccs->todense:";
# print $ccs2->todense;


# PDL -> ArrayRef
# https://metacpan.org/pod/PDL::Core#topdl
# my $aref = $ccs2->todense->unpdl;
# p $aref;


# Sparse x Dense
my $ccs3 = pdl [[0], [0], [1]];
# my $ccs3 = pdl [[0], [0], [0]];
my $mult = $ccs2 x $ccs3; # error if all 0
# print $mult->todense;
# print $mult;

# where($ccs3, $ccs3 != 1) .= -1;
# where($ccs3, $ccs3 == 1) .= 1;
# print $ccs3;


# ピドルは自動では拡張されない (領域外に要素を代入しようとするとエラー)
my $vec = pdl [1, 2, 3, 4];
# $vec(3) .= 1; # => slice: slice starts out of bounds in pos 0
# print $vec;

$vec->reshape(8); # reshape は副作用あり
$vec(3) .= 1;
# print $vec;


# CCS::Nd は reshape できる？ -> できたら weight は CCS で保存できる
