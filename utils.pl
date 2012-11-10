

sub mean {
    my($data) = @_;
    
    if (not @$data) {
        return 0;
    }
    my $total = 0;
    foreach (@$data) {
        $total += $_;
    }
    my $average = $total / @$data;
    return $average;
}

sub stdev{
    my($data) = @_;
    
    if(@$data <= 1){
        return 0;
    }
    
    my $average = &mean($data);
    my $sqtotal = 0;
    foreach(@$data) {
        $sqtotal += ($average-$_) ** 2;
    }
    my $std = ($sqtotal / (@$data - 1)) ** 0.5;
    return $std;
}

sub variance{
    my($data) = @_;
    
    if(@$data <= 1){
        return 0;
    }
    
    my $average = &mean($data);
    my $sqtotal = 0;
    foreach(@$data) {
        $sqtotal += (($average-$_) ** 2);
    }
    my $std = $sqtotal / (@$data - 1);
    return $std;
}

sub cal_throughput {
    my ($rcv, $len) = @_;

    # return $rcv * 8 / $len / 1000;
    return $rcv / $len;
}


1;