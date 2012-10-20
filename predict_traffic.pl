#####################################
## Yi-Chao Chen
## perl predict_traffic.pl tcpdump.campus.walking.tcp.dat.throughput.1.txt THROUGHPUT EWMA 0.1
##
## input:
##   input_filename: take the output file from parse.tcpdump.pl as input
##      <time interval> <received data in bytes> <throughput mean> <throughput variance>
##   target: the target to predict
##      [THROUGHPUT | VARIANCE]
##   prediction method:
##      [EWMA | HW | LPEWMA | GAEWMA | ALL]
##   parameters: parameters for prediction method
##
## output:
##   input_filename.TARGET.raw.txt
##     <time interval> <actual value>
##     if TARGET is VARIANCE, then <actual valude> is the variance of the interval
##   input_filename.TARGET.METHOD.txt
##     <time interval> <predicted value> <TCPVAR-like deviation> <s_ewma> 
##   input_filename.TARGET.METHOD.err.txt
##     <time interval> <prediction error> 
##



#!/bin/perl

use strict;


my $DEBUG0 = 0;
my $DEBUG = 1;

my $MINUS_INFINITY = -99999;

my $METHOD_EWMA = "EWMA";
my $METHOD_HW = "HW";
my $METHOD_LPEWMA = "LPEWMA";
my $METHOD_GAEWMA = "GAEWMA";
my $METHOD_ALL = "ALL";

my $PREDICT_THROUGHPUT = "THROUGHPUT";
my $PREDICT_THROUGHPUT_VARIANCE = "VARIANCE";


#####
## global variables
# my $file_path = "/v/filer4b/v27q002/ut-wireless/wdong/mobile_trace/";
my $file_path = "./PARSEDDATA";
my $file;
my $output_dir = "./PARSEDDATA";
my $method; ## prediction method: EWMA, HW, ..
my $target; ## prediction target: mean throughput, variance throughput, ...
my $interval = -1;
my $target_sum = 0; ## used to calculate average target value in the end
my $target_ind = 0;

## raw
my @time;
my @raw;    ## time series for raw data

## EWMA
my @ewma;
my @ewma_dev;   ## Lili's formula: smooth_dev = (1-beta) smooth_dev + beta * |smooth_load - curr_load |;
my @ewma_dev2;  ## s_ewma^2 = (alpha/(2-alpha)) * s^2
my $ewma_pred = $MINUS_INFINITY;
my $ewma_dev_pred;
my ($ewma_alpha);

## Holt-Winters
my @hw;
my @hw_dev;
my @hw_dev2;
my $hw_pred = $MINUS_INFINITY;
my $hw_dev_pred;
my ($a_t_1, $b_t_1) = (0, 0);
# my @c_t;
my ($hw_alpha, $hw_beta, $hw_gamma);

## LPEWMA
my @lpewma;
my @lpewma_dev;   ## Lili's formula: smooth_dev = (1-beta) smooth_dev + beta * |smooth_load - curr_load |;
my @lpewma_dev2;  ## s_ewma^2 = (alpha/(2-alpha)) * s^2
my $lpewma_pred = $MINUS_INFINITY;
my $lpewma_dev_pred;
my ($lpewma_alpha);
my $lpewma_alphamax = 0.2;
my $lpewma_m = 0;
my $lpewma_mnorm;
my $lpewma_last;
my $lpewma_mnum = 0;

## GAEWMA
my @gaewma;
my @gaewma_dev;   ## Lili's formula: smooth_dev = (1-beta) smooth_dev + beta * |smooth_load - curr_load |;
my @gaewma_dev2;  ## s_ewma^2 = (alpha/(2-alpha)) * s^2
my $gaewma_pred = $MINUS_INFINITY;
my $gaewma_dev_pred;
my ($gaewma_alpha);
my $gaewma_alphab = 0.2;
my $gaewma_m = 0;
my $gaewma_deltam = -1;
my $gaewma_deltamnorm;
my $gaewma_last;
my $gaewma_deltamnum = 0;
my $gaewma_lastm = -1;
my $gaewma_x;



#####
## input
if($#ARGV < 3) {
    die "wrong number of input ".($#ARGV)."\n";
}
$file = $ARGV[0];
print $file."\n" if($DEBUG0);

$target = $ARGV[1];

$method = $ARGV[2];
if($method eq $METHOD_EWMA) {
    print "use EWMA\n" if($DEBUG0);
    $ewma_alpha = $ARGV[3];    
}
elsif($method eq $METHOD_HW) {
    print "use Holt-Winters\n" if($DEBUG0);
    $hw_alpha = $ARGV[3];
    $hw_beta = $ARGV[4];
    $hw_gamma = $ARGV[5];
}
elsif($method eq $METHOD_LPEWMA) {
    print "use LPEWMA\n" if($DEBUG0);
    $lpewma_alphamax = $ARGV[3];
}
elsif($method eq $METHOD_GAEWMA) {
    print "use GAEWMA\n" if($DEBUG0);
    $gaewma_alphab = $ARGV[3];
}
elsif($method eq $METHOD_ALL) {
    print "use all methods\n" if($DEBUG0);
    $ewma_alpha = $ARGV[3]; 
    $hw_alpha = $ARGV[4];
    $hw_beta = $ARGV[5];
    $hw_gamma = $ARGV[6];
}
else {
    die "wrong method\n";
}



#####
## main
open FH, "< $file_path/$file" or die $!;
while(<FH>) {
    print $_ if($DEBUG0);


    #####
    ## process raw data
    ##   format: <time> <received bytes in this interval> <mean throughput of the interval> <variance throughput of the interval>
    my ($time, $rev_data, $throughput_mean, $throughput_variance) = split(/[ \n]/, $_);
    print join(", ", ($time, $rev_data, $throughput_mean, $throughput_variance))."\n" if($DEBUG0); 
    $interval = $time if($interval == -1);
    
    ## calculate throughput of the interval
    # my $cur_throughput = $rev_data * 8.0 / $interval / 1000;
    my $cur_throughput = cal_throughput($rev_data, $interval);
    
    
    #####
    ## determine the prediction target
    my $target_value;
    if($target eq $PREDICT_THROUGHPUT) {
        $target_value = $cur_throughput;
    }
    elsif($target eq $PREDICT_THROUGHPUT_VARIANCE) {
        $target_value = $throughput_variance;
    }
    else {
        die "wrong target name\n";
    }
    $target_sum += $target_value;
    $target_ind ++;
    push(@raw, $target_value);
    push(@time, $time);
    


    #####
    ## ewma: 
    ##    S_1 = Y_1
    ##    S_t = alpha * Y_t + (1 - alpha) * S_t-1
    if($method eq $METHOD_EWMA || $method eq $METHOD_ALL) {
        if($ewma_pred == $MINUS_INFINITY) {
            push(@ewma, 0);                 ## predict the first one as 0
            push(@ewma_dev, 0);
            push(@ewma_dev2, 0);
            $ewma_pred = $target_value;   ## the second prediction is just the first measurement
            $ewma_dev_pred = $target_value / 2;
        }
        else {
            $ewma_dev_pred = $ewma_alpha * abs($target_value - $ewma_pred) + (1 - $ewma_alpha) * $ewma_dev_pred;
            $ewma_pred = $ewma_alpha * $target_value + (1 - $ewma_alpha) * $ewma_pred;
        }
        push(@ewma, $ewma_pred);
        push(@ewma_dev, $ewma_dev_pred);
        ## variance: s_ewma^2 = (alpha/(2-alpha)) * s^2
        push(@ewma_dev2, sqrt($ewma_alpha/(2-$ewma_alpha) * variance(\@raw) ) );
    }
    
    #####
    ## Holt-Winters: no seasonal trend
    ##    a(i) = alpha*y(i) + (1-alpha)*(a(i-1)+b(i-1));
    ##    b(i) = beta*(a(i)-a(i-1)) + (1-beta)*b(i-1);
    ##    y(i+1) = a(i) + b(i);
    if($method eq $METHOD_HW || $method eq $METHOD_ALL) {
        if($hw_pred == $MINUS_INFINITY) {
            push(@hw, 0);                 ## predict the first one as 0
            push(@hw_dev, 0);
            push(@hw_dev2, 0);
        }
        my $a_t = $hw_alpha * $target_value + (1 - $hw_alpha) * ($a_t_1 + $b_t_1);
        my $b_t = $hw_beta * ($a_t - $a_t_1) + (1 - $hw_beta) * $b_t_1;
        my $tmp_pred = $a_t + $b_t;
        if($hw_pred == $MINUS_INFINITY) {
            ## first prediction: deviation is half of it
            $hw_dev_pred = $tmp_pred / 2;
        }
        else {
            $hw_dev_pred = $hw_alpha * abs($target_value - $hw_pred) + (1 - $hw_alpha) * $hw_dev_pred;
        }
        $hw_pred = $tmp_pred;
        push(@hw, $hw_pred);
        push(@hw_dev, $hw_dev_pred);
        ## variance: s_hw^2 = (alpha/(2-alpha)) * s^2
        push(@hw_dev2, sqrt($hw_alpha/(2-$hw_alpha) * variance(\@raw) ) );
        $a_t_1 = $a_t;
        $b_t_1 = $b_t;
    }

    
    #####
    ## lpewma:
    ##    S_1 = Y_1
    ##    S_t = alpha * Y_t + (1 - alpha) * S_t-1
    if($method eq $METHOD_LPEWMA || $method eq $METHOD_ALL) {
        if($lpewma_pred == $MINUS_INFINITY) {
            push(@lpewma, 0);                 ## predict the first one as 0
            push(@lpewma_dev, 0);
            push(@lpewma_dev2, 0);
        
            $lpewma_pred = $target_value;   ## the second prediction is just the first measurement
            $lpewma_last = $target_value;
            $lpewma_dev_pred = $target_value / 2;
        }
        else {
            $lpewma_m = $target_value - $lpewma_last;
            $lpewma_last = $target_value;
            $lpewma_mnorm = ($lpewma_mnorm*$lpewma_mnum + abs($lpewma_m))/($lpewma_mnum+1);
            $lpewma_mnum++;

            $lpewma_alpha = $lpewma_alphamax/(1+ abs($lpewma_m)/$lpewma_mnorm);
            # print "$lpewma_m, $lpewma_mnorm, $lpewma_alpha\n";
            $lpewma_dev_pred = $lpewma_alpha * abs($target_value - $lpewma_pred) + (1 - $lpewma_alpha) * $lpewma_dev_pred;
            $lpewma_pred = $lpewma_alpha * $target_value + (1 - $lpewma_alpha) * $lpewma_pred;
        }
        push(@lpewma, $lpewma_pred);
        push(@lpewma_dev, $lpewma_dev_pred);
        ## variance: s_ewma^2 = (alpha/(2-alpha)) * s^2
        push(@lpewma_dev2, sqrt($lpewma_alpha/(2-$lpewma_alpha) * variance(\@raw) ) );
    }    


    #####
    ## gaewma:
    ##    S_1 = Y_1
    ##    S_t = alpha * Y_t + (1 - alpha) * S_t-1
    if($method eq $METHOD_GAEWMA || $method eq $METHOD_ALL) {
        if($gaewma_pred == $MINUS_INFINITY) {
            push(@gaewma, 0);                 ## predict the first one as 0
            push(@gaewma_dev, 0);
            push(@gaewma_dev2, 0);

            $gaewma_pred = $target_value;   ## the second prediction is just the first measurement
            $gaewma_last = $target_value;
            $gaewma_dev_pred = $target_value / 2;
        }
        else {
            $gaewma_m = $target_value - $gaewma_last;

            $gaewma_deltam = $gaewma_m  - $gaewma_lastm if($gaewma_lastm!=-1); 
            $gaewma_lastm = $gaewma_m;

            $gaewma_last = $target_value;
            $gaewma_deltamnorm = ($gaewma_deltamnorm*$gaewma_deltamnum + abs($gaewma_deltam))/($gaewma_deltamnum+1) if($gaewma_deltam != -1);
            $gaewma_deltamnum++ if($gaewma_deltam != -1) ;
            if($gaewma_deltam == 0 || $gaewma_deltamnum == 0)
            {
                $gaewma_x = 1;
            }
            else
            {
                $gaewma_x = abs($gaewma_deltam)/$gaewma_deltamnorm;
            }
    
            $gaewma_alpha = $gaewma_alphab**$gaewma_x;
            # print "$gaewma_deltam, $gaewma_deltamnorm, $gaewma_alpha\n";        
            $gaewma_dev_pred = $gaewma_alpha * abs($target_value - $gaewma_pred) + (1 - $gaewma_alpha) * $gaewma_dev_pred;
            $gaewma_pred = $gaewma_alpha * $target_value + (1 - $gaewma_alpha) * $gaewma_pred;
        }
        push(@gaewma, $gaewma_pred);
        push(@gaewma_dev, $gaewma_dev_pred);
        ## variance: s_ewma^2 = (alpha/(2-alpha)) * s^2
        push(@gaewma_dev2, sqrt($gaewma_alpha/(2-$gaewma_alpha) * variance(\@raw) ) );
    }



}
close FH;


#####
## post process
##  i) output time series
## raw
open FH_RAW, "> $output_dir/$file.$target.raw.txt" or die $!;
for(my $i = 0; $i < scalar(@raw); $i ++) {
    print FH_RAW $time[$i]." ".$raw[$i]."\n";
}
close FH_RAW;

## EWMA
if($method eq $METHOD_EWMA || $method eq $METHOD_ALL) {
    pop(@ewma); ## remove the last prediction
    die "wrong number of ewma prediction" if($#ewma != $#raw);
    print "length of array: ".scalar(@raw)."\n" if($DEBUG0);

    open FH_EWMA, "> $output_dir/$file.$target.EWMA.txt" or die $!;
    for(my $i = 0; $i < scalar(@ewma); $i ++) {
        print FH_EWMA $time[$i]." ".$ewma[$i]." ".$ewma_dev[$i]." ".$ewma_dev2[$i]."\n";
    }
    close FH_EWMA;
}

## Holt-Winters: no seasonal trend
if($method eq $METHOD_HW || $method eq $METHOD_ALL) {
    pop(@hw); ## remove the last prediction
    die "wrong number of Holt-Winters prediction" if($#hw != $#raw);
    print "length of array: ".scalar(@raw)."\n" if($DEBUG0);
    
    open FH_HW, "> $output_dir/$file.$target.HW.txt" or die $!;
    for(my $i = 0; $i < scalar(@hw); $i ++) {
        print FH_HW $time[$i]." ".$hw[$i]." ".$hw_dev[$i]." ".$hw_dev2[$i]."\n";
    }
    close FH_HW;
}

## LPEWMA
if($method eq $METHOD_LPEWMA || $method eq $METHOD_ALL) {
    pop(@lpewma); ## remove the last prediction
    die "wrong number of ewma prediction" if($#lpewma != $#raw);
    print "length of array: ".scalar(@raw)."\n" if($DEBUG0);

    open FH_LPEWMA, "> $output_dir/$file.$target.LPEWMA.txt" or die $!;
    for(my $i = 0; $i < scalar(@lpewma); $i ++) {
        print FH_LPEWMA $time[$i]." ".$lpewma[$i]." ".$lpewma_dev[$i]." ".$lpewma_dev2[$i]."\n";
    }
    close FH_LPEWMA;
}

## GAEWMA
if($method eq $METHOD_GAEWMA || $method eq $METHOD_ALL) {
    pop(@gaewma); ## remove the last prediction
    die "wrong number of ewma prediction" if($#gaewma != $#raw);
    print "length of array: ".scalar(@raw)."\n" if($DEBUG0);

    open FH_GAEWMA, "> $output_dir/$file.$target.GAEWMA.txt" or die $!;
    for(my $i = 0; $i < scalar(@gaewma); $i ++) {
        print FH_GAEWMA $time[$i]." ".$gaewma[$i]." ".$gaewma_dev[$i]." ".$gaewma_dev2[$i]."\n";
    }
    close FH_GAEWMA;
}



##  ii) print prediction error
## EWMA
if($method eq $METHOD_EWMA || $method eq $METHOD_ALL) {
    open FH_EWMA, "> $output_dir/$file.$target.EWMA.err.txt" or die $!;
    print FH_EWMA $time[0]." 0\n";
    my $sum = 0.0;
    ## ignore the first prediction
    for(my $i = 1; $i < scalar(@raw); $i ++) {
        my $error = abs($raw[$i] - $ewma[$i]);
        $sum += $error;
        print FH_EWMA $time[$i]." $error\n";
    }
    my $ewma_avg_err = $sum / (scalar(@raw) - 1);   
    close FH_EWMA;
    
    print "EWMA avg err = " if($DEBUG0);
    # print "$ewma_avg_err\t$total_throughput\n";
    print "$ewma_avg_err\t".($target_sum/$target_ind)."\n";
}

## Holt-Winters: no seasonal trend
if($method eq $METHOD_HW || $method eq $METHOD_ALL) {
    open FH_HW, "> $output_dir/$file.$target.HW.err.txt" or die $!;
    print FH_HW $time[0]." 0\n";
    my $sum = 0.0;
    for(my $i = 1; $i < scalar(@raw); $i ++) {
        my $error = abs($raw[$i] - $hw[$i]);
        $sum += $error;
        print FH_HW $time[$i]." $error\n";
    }
    my $hw_avg_err = $sum / (scalar(@raw) - 1);
    close FH_HW;

    print "Holt-Winters avg err = " if($DEBUG0);
    # print "$hw_avg_err\t$total_throughput\n";
    print "$hw_avg_err\t".($target_sum/$target_ind)."\n";
}

## LPEWMA
if($method eq $METHOD_LPEWMA || $method eq $METHOD_ALL) {
    open FH_LPEWMA, "> $output_dir/$file.$target.lpewma.err.txt" or die $!;
    print FH_LPEWMA $time[0]." 0\n";
    my $sum = 0.0;
    ## ignore the first prediction
    for(my $i = 1; $i < scalar(@raw); $i ++) {
        my $error = abs($raw[$i] - $lpewma[$i]);
        $sum += $error;
        print FH_LPEWMA $time[$i]." $error\n";
    }
    my $lpewma_avg_err = $sum / (scalar(@raw) - 1);
    close FH_LPEWMA;

    print "LPEWMA avg err = " if($DEBUG0);
    # print "$ewma_avg_err\t$total_throughput\n";
    print "$lpewma_avg_err\t".($target_sum/$target_ind)."\n";
}


## GAEWMA
if($method eq $METHOD_GAEWMA || $method eq $METHOD_ALL) {
    open FH_GAEWMA, "> $output_dir/$file.$target.gaewma.err.txt" or die $!;
    print FH_GAEWMA $time[0]." 0\n";
    my $sum = 0.0;
    ## ignore the first prediction
    for(my $i = 1; $i < scalar(@raw); $i ++) {
        my $error = abs($raw[$i] - $gaewma[$i]);
        $sum += $error;
        print FH_GAEWMA $time[$i]." $error\n";
    }
    my $gaewma_avg_err = $sum / (scalar(@raw) - 1);
    close FH_GAEWMA;

    print "GAEWMA avg err = " if($DEBUG0);
    # print "$ewma_avg_err\t$total_throughput\n";
    print "$gaewma_avg_err\t".($target_sum/$target_ind)."\n";
}




#####
## functions 
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


