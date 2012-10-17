#!/bin/perl

use strict;


my $DEBUG0 = 0;
my $DEBUG = 1;


#####
## global variables
# my $file_path = "/v/filer4b/v27q002/ut-wireless/wdong/mobile_trace/";
my $file_path = "./PARSEDDATA";
my $file;
my $output_dir = "./PARSEDDATA";
my $method;
my $interval = -1;


#####
## input
if($#ARGV != 1) {
    die "wrong number of input\n";
}
$file = $ARGV[0];
$method = $ARGV[1];



#####
## main
open FH_RAW, "< $file_path/$file" or die $!;
open FH_THU, "< $file_path/$file.THROUGHPUT.$method.txt" or die $!;
open FH_VAR, "< $file_path/$file.VARIANCE.$method.txt" or die $!;
open FH_OUT_ACTUAL, "> $output_dir/$file.actual.out" or die $!;
open FH_OUT_PRED, "> $output_dir/$file.predicted.$method.out" or die $!;
while(my $ln_raw = <FH_RAW>) {
    my $ln_thu = <FH_THU>;
    my $ln_var = <FH_VAR>;
    print $ln_raw if($DEBUG0);
    print $ln_thu if($DEBUG0);
    print $ln_var if($DEBUG0);

    my ($time_raw, $actual_bytes, $actual_mean, $actual_var) = split(/\s+/, $ln_raw);
    my ($time_thu, $pred_thu, $s_thu, $s_thu_ewma) = split(/\s+/, $ln_thu);
    my ($time_var, $pred_var, $s_var, $s_var_ewma) = split(/\s+/, $ln_var);

    ## check time
    if($time_var != $time_thu || $time_thu != $time_var) {
        die "wrong time sync\n";
    }

    $interval = $time_var if($interval == -1);

    print FH_OUT_ACTUAL "".(($time_raw-$interval) * 1000)."\tRATE\t".$actual_mean."\t".$actual_var."\n";
    # print FH_OUT_ACTUAL "".(($time_raw-$interval) * 1000)."\tRATE\t".$actual_mean."\n";
    print FH_OUT_PRED   "".(($time_raw-$interval) * 1000)."\t".$pred_thu."\t".$pred_var."\n";
}
close FH_RAW;
close FH_THU;
close FH_VAR;
close FH_OUT_PRED;
close FH_OUT_ACTUAL;


