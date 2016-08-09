package Algorithm::Plearn::Datasets::20NewsGroupsBinary;

use strict;
use warnings;

use Scalar::Util qw/looks_like_number/;
use PDL;
use PDL::NiceSlice;
use PDL::CCS::Nd;
use Mouse;
use Algorithm::Plearn::Util::SparseMatrix;
use Algorithm::Plearn::Util::DenseVector;

has 'offset'    => (is => 'rw', default => 0);
has 'chunksize' => (is => 'rw', default => 0);
has 'params' => (
    is => 'rw',
    default => sub {
        +{
            bias         => 1,
            target_map   => +{},
            target_names => [],
        }
    }
);

sub read {
    my ($self, $offset) = @_;

    if (defined $offset) {
        $self->offset($offset);
    } else {
        $offset = $self->offset;
    }
    my $chunksize = $self->chunksize;

    my $sparse = Algorithm::Plearn::Util::SparseMatrix->new;
    my $vec = Algorithm::Plearn::Util::DenseVector->new;

    # TODO Specify the relative path
    # TODO Fetch .bz2 file and cache

    my $row_index = 0;
    open FILE, 'news20.binary.100' or die "Can't open file"; # Cache file
    while (<FILE>) {
        next if $. <= $offset;
        last if $chunksize && ($offset + $chunksize + 1) <= $.;
        chomp;

        my @row = split(/ /, $_) or next;
        my $label = shift @row; # first column is a label (target) name
        my $label_index = $self->_get_or_create_label_index($label);

        $sparse->add_element(0, $row_index, $self->params->{bias}); # Append bias at index 0
        foreach my $text (@row) {
            my ($col_index, $value) = split(/:/, $text) or next;
            unless (defined($col_index) || defined($value) ||
                    looks_like_number $col_index || looks_like_number $value) {
                warn "Invalid format found:$_ at line $.\n";
                next;
            }
            $sparse->add_element($col_index, $row_index, $value);
        };
        $vec->add_element($label_index);

        $row_index++;
    }
    close FILE;
    $self->offset($self->offset + $row_index);

    return undef if $row_index == 0;
    return +{
        data   => $sparse->create_matrix,
        target => $vec->create_vector,
    };
}




# TODO target_names と target_map も piddle にする？
# data          => [ [ ... ], [ ... ] ... [ ... ] ] (piddle)
# target        => [ 0, 0, ... 1, ... 1 ]           (piddle)
# target_names  => [ '-1', '+1' ]
# target_map    => { '-1' => 0, '+1' => 1 }

has 'dataset' => (
    is => 'rw',
    default => sub {
        +{ data => [], target => [], target_names => [], target_map => +{} }
    }
);

sub load {
    my ($self, $start, $end) = @_;
    $start //= 0;

    # TODO Specify the relative path
    open FILE, 'news20.binary.1000' or die "Can't open file"; # Cache file
    # TODO Fetch .bz2 file and cache
    while (<FILE>) {
        next if $. < ($start + 1);
        last if defined($end) && ($end + 1) <= $.;
        chomp;
        my @row = split(/ /, $_) or next;

        my $data = [];
        my $label = shift @row; # first column is a label (target) name
        my $label_index = $self->_get_or_create_label_index($label);

        my @vec = map {
            my ($index, $value) = split(/:/, $_) or next;
            p $_ unless defined($index) || defined($value);
            unless (looks_like_number $index || looks_like_number $value) {
                warn "Invalid format found:$_ at line $.\n";
                next;
            }
            $data->[$index - 1] = $value;
        } @row;

        push @{$self->dataset->{target}}, $label_index;
        push @{$self->dataset->{data}}, $data;
    }
    close FILE;
    return $self->dataset;
}
use DDP;

# with bias dimension (index:0)
sub load_as_ccs {
    my ($self, $start, $end) = @_;
    $start //= 0;

    my $sparse = Algorithm::Plearn::Util::SparseMatrix->new;
    my $vec = Algorithm::Plearn::Util::DenseVector->new;

    my $row_index = 0;
    # TODO 行で適当に分割しながら CCS::Nd を作成する
    # TODO Specify the relative path
    open FILE, 'news20.binary.1000' or die "Can't open file"; # Cache file
    # TODO Fetch .bz2 file and cache
    while (<FILE>) {
        next if $. < ($start + 1);
        last if defined($end) && ($end + 1) <= $.;
        chomp;
        my @row = split(/ /, $_) or next;

        # my $data = [];
        my $label = shift @row; # first column is a label (target) name
        my $label_index = $self->_get_or_create_label_index($label);

        # Append bias value at index 0
        $sparse->add_element(0, $row_index, $self->params->{bias});

        map {
            my ($col_index, $value) = split(/:/, $_) or next;
            p $_ unless defined($col_index) || defined($value);
            unless (looks_like_number $col_index || looks_like_number $value) {
                warn "Invalid format found:$_ at line $.\n";
                next;
            }
            $sparse->add_element($col_index, $row_index, $value);
            # $data->[$col_index - 1] = $value; # TODO remove
        } @row;

        $vec->add_element($label_index);

        # push @{$self->dataset->{target}}, $label_index;
        # push @{$self->dataset->{data}}, $data;

        $row_index++;
    }
    close FILE;
    # my @dim = $ccs->dims;
    # p @dim;
    $self->dataset->{target} = $vec->create_vector;
    $self->dataset->{data} = $sparse->create_matrix;
    return $self->dataset;
}

sub _get_or_create_label_index {
    my ($self, $label) = @_;
    my $label_index = $self->params->{target_map}->{$label};
    unless (defined $label_index) {
        push @{$self->params->{target_names}}, $label;
        $label_index = scalar(@{$self->params->{target_names}}) - 1;
        $self->params->{target_map}->{$label} = $label_index;
    }
    return $label_index;
}

__PACKAGE__->meta->make_immutable();

1;
