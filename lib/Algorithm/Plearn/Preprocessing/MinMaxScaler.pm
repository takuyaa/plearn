package Algorithm::Plearn::Preprocessing::MinMaxScaler;

use strict;
use warnings;
use utf8;
use Mouse;

has 'params' => (
    is => 'rw',
    default => sub {
        +{ min => [], max => [] }
    }
);

sub fit {
    my ($self, $X, $validation) = @_;
    for my $data (@$X) {
        for (my $i = 0; $i < @$data; $i++) {
            my $min = $self->{params}->{min}->[$i] // "+inf";
            my $max = $self->{params}->{max}->[$i] // "-inf";

            my $num = $data->[$i] or next;
            $min = $num if $num < $min;
            $max = $num if $max < $num;

            $self->{params}->{min}->[$i] = $min;
            $self->{params}->{max}->[$i] = $max;
        }
    }
    my $dim = @{$self->{params}->{min}};
    die unless $dim == @{$self->{params}->{max}};
    return unless $validation;
    for (my $i = 0; $i < $dim; $i++) {
        my $min = $self->{params}->{min}->[$i] or die 'dimension error';
        my $max = $self->{params}->{max}->[$i] or die 'dimension error';
        die 'all elements are same value' if $max - $min == 0;
    }
}

sub transform {
    my ($self, $X) = @_;
    die if @{$self->{params}->{min}} == 0 || @{$self->{params}->{max}} == 0;
    my $scaled = [];
    for (my $n = 0; $n < @$X; $n++) {
        $scaled->[$n] //= [];
        my $data = $X->[$n];
        for (my $i = 0; $i < @$data; $i++) {
            my $min = $self->{params}->{min}->[$i] // next;
            my $max = $self->{params}->{max}->[$i] // next;
            my $num = $data->[$i] // next;
            next if $max - $min == 0;
            $scaled->[$n]->[$i] = ($num - $min) / ($max - $min);
        }
    }
    return $scaled;
}

__PACKAGE__->meta->make_immutable();

1;
