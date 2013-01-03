#####################################
## Yi-Chao Chen, Wei Dong
## perl predict_traffic_win.pl tcpdump.campus.walking.tcp.dat.throughput.1.txt THROUGHPUT 1 10 EWMA 0.1
##
## input:
##   input_filename: take the output file from parse.tcpdump.pl as input
##      <time interval> <received data in bytes> <throughput mean> <throughput variance>
##   target: the target to predict
##      [THROUGHPUT | VARIANCE]
##   interval
##   win_size
##   prediction method:
##      [EWMA | HW | LPEWMA | GAEWMA | ALL]
##   parameters: parameters for prediction method
##
## output:
##   input_filename.muti-win.TARGET.METHOD.interval.winsize.out
##     <time interval> <actual value> <prediction: now> <prediction: next 1 interval> <prediction: next 2 interval> ... 
##



#!/bin/perl

use strict;
require "./utils.pl";
require "./ewma.pl";


my $DEBUG0 = 0;
my $DEBUG1 = 0;
my $DEBUG2 = 1;

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
# my $file_path = "/v/filer4b/v27q002/ut-wireless/wdong/mobile_trace";
my $file_path = "/v/filer4b/v27q002/ut-wireless/wdong/traffic_prediction/PARSEDDATA";
# my $file_path = "./PARSEDDATA";
my $file;
my $output_dir = "./PARSEDDATA2";
my $output_file;
my $method; ## prediction method: EWMA, HW, ..
my $target; ## prediction target: mean throughput, variance throughput, ...
my $interval;
my $win_size;
my $target_sum = 0; ## used to calculate average target value in the end
my $target_ind = 0;


## raw
my @raw;
my @time;

## EWMA
my %ewma;
my @ewma_dev;   ## Lili's formula: smooth_dev = (1-beta) smooth_dev + beta * |smooth_load - curr_load |;
my $ewma_alpha;

## Holt-Winters
my @hw;
my ($hw_alpha, $hw_beta, $hw_gamma);



#####
## input
if($#ARGV < 5) {
    die "wrong number of input ".($#ARGV)."\n";
}
$file = $ARGV[0];
print $file."\n" if($DEBUG0);

$target = $ARGV[1];
$interval = $ARGV[2];
$win_size = $ARGV[3];

$method = $ARGV[4];
if($method eq $METHOD_EWMA) {
    print "use EWMA\n" if($DEBUG0);
    $ewma_alpha = $ARGV[5];    
}
elsif($method eq $METHOD_HW) {
    print "use Holt-Winters\n" if($DEBUG0);
    $hw_alpha = $ARGV[5];
    $hw_beta = $ARGV[6];
    $hw_gamma = $ARGV[7];
}
elsif($method eq $METHOD_ALL) {
    print "use all methods\n" if($DEBUG0);
    $ewma_alpha = $ARGV[5]; 
    $hw_alpha = $ARGV[6];
    $hw_beta = $ARGV[7];
    $hw_gamma = $ARGV[8];
}
else {
    die "wrong method\n";
}
$output_file = "$file.muti-win.$target.$method.$interval.$win_size.out";


#####
## main
my $sim_time = 999999;
my $err_sum = 0;
my $err_cnt = 0;

open OUTPUT_FH, "> $output_dir/$output_file" or die $!;
for(my $t = $interval; $t < $sim_time; $t += $interval) {
    my $complete_trace;
    print "> $t: " if($DEBUG1);
    push(@time, $t);
    print OUTPUT_FH "$t\t";
        
    for(my $win = 1; $win <= $win_size; $win ++) {
        my $this_interval = $win * $interval;
        
        ## get timeseries so far
        my $timeseries_ref;
        ($complete_trace, $timeseries_ref) = get_timeseries("$file_path/$file", $target, $t, $this_interval);

        ## use ewma for prediction
        my ($pred_ewma_ts, $pred_ewma_dev_ts) = ewma($timeseries_ref, $ewma_alpha);
        my $pred_value = pop(@$pred_ewma_ts);
        my $pred_value_dev = pop(@$pred_ewma_dev_ts);
        if($win == 1) {
            my $actual_value = $timeseries_ref->[-1];
            push(@raw, $actual_value);
            print "cur value=".$actual_value."\n" if($DEBUG1);
            print OUTPUT_FH "".$actual_value."\t";

            my $cur_pred_value = pop(@$pred_ewma_ts);
            my $cur_pred_value_dev = pop(@$pred_ewma_dev_ts);
            print "  0: " if($DEBUG1);
            for(my $i = 0; $i < scalar(@$timeseries_ref)-1; $i ++) {
                print $timeseries_ref->[$i]."," if($DEBUG1);
            }
            print "\n" if($DEBUG1);
            # print join(",", $timeseries_ref->[0 .. scalar(@$timeseries_ref)-2])."\n" if($DEBUG1);
            print "     predicted: $cur_pred_value\n" if($DEBUG1);
            print OUTPUT_FH "$cur_pred_value\t$cur_pred_value_dev\t";

            ## error
            $err_cnt ++;
            $err_sum += abs($actual_value - $cur_pred_value);
        }


        print "  $this_interval: " if($DEBUG1);
        print join(",", @$timeseries_ref)."\n" if($DEBUG1);
        print "     predicted: $pred_value\n" if($DEBUG1);
        print OUTPUT_FH "$pred_value\t$pred_value_dev\t";
        
    }

    print "\n" if($DEBUG1);
    print OUTPUT_FH "\n";

    last if($complete_trace);
}
close OUTPUT_FH;


# error
print ($err_sum / $err_cnt)."\n";


#####
## functions
sub get_timeseries {
    my ($filename, $target, $time_so_far, $interval) = @_;
    my @interval_values = ();
    my @timeseries = ();
    my $complete_trace = 1;

    open FH, "< $filename" or die $!." \n$filename\n";
    while(<FH>) {
        my ($time, $rev_data, $throughput_mean, $throughput_variance) = split(/[ \n]/, $_);
        

        #####
        ## if the time exceed the current
        ## generate the last measurement to timeseries and stop
        if($time > $time_so_far) {
            if(scalar(@interval_values) != 0) {
                my $interval_value = mean(\@interval_values);
                push(@timeseries, $interval_value);
                @interval_values = ();
            }
            $complete_trace = 0;
            last;
        }


        #####
        ## determine the prediction target
        my $target_value;
        if($target eq $PREDICT_THROUGHPUT) {
            $target_value = $throughput_mean;
        }
        elsif($target eq $PREDICT_THROUGHPUT_VARIANCE) {
            $target_value = $throughput_variance;
        }
        else {
            die "wrong target name\n";
        }


        #####
        ## get target value for desired interval
        push(@interval_values, $target_value);
        if(scalar(@interval_values) == $interval) {
            my $interval_value = mean(\@interval_values);
            push(@timeseries, $interval_value);
            @interval_values = ();
        }

    }
    close FH;
    return ($complete_trace, \@timeseries);
}




