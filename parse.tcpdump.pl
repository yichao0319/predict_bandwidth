#####################################
## Yi-Chao Chen
## perl parse.tcpdump.pl tcpdump.home.static.tcp.dat 5 128.83.120.56 22
##
## input:
##   input_filename: raw tcpdump data
##   interval: in second
##   server ip
##   server port
##
## output:
##   input_filename.throughput.interval.txt
##     <time interval> <received data in bytes> <throughput mean> <throughput variance>


#!/bin/perl

use strict;


my $DEBUG0 = 0;
my $DEBUG = 1;

#####
## global variables
my $raw_dir = "./RAWDATA";
# my $raw_dir = "/var/local/yichao/mobile_streaming/RAWDATA";
my $output_dir = "./PARSEDDATA";
my $file;
my $output_file;
my $server = "128.83.120.56";
# my $server = "128.83.144.185";
my $server_port = 22;
my $interval;
my $interval_start = -1;
my $interval_sum = 0;
my $interval_ind = 0;
my $small_interval = 0.2;   ## to calculate mean and var throughput in $interval
my $small_interval_start = -1;
my $small_interval_sum = 0;
my @small_interval_throughput = ();


#####
## inputs
if($#ARGV != 3) {
    die "wrong number of inputs: ".$#ARGV."\n";
}
$file = $ARGV[0];
print $file."\n" if($DEBUG);
$interval = $ARGV[1] + 0;
$output_file = $file.".throughput.".$interval.".txt";
$server = $ARGV[2];
$server_port = $ARGV[3];
print $server."\n" if($DEBUG);


#####
## main 
my $cmd = "tcpdump -nnS -r $raw_dir/$file |";
print $cmd."\n" if($DEBUG);
open FH, "$cmd" or die $!;
open FH_OUT, ">$output_dir/$output_file" or die $!;
while(<FH>) {
    print $_ if($DEBUG0);


    #############
    ## parse a line
    my ($time, $hour, $min, $sec, $src_ip, $src_port, $dst_ip, $dst_port, $pkt_len); 
    if($_ =~ /(\d+):(\d+):(\d+\.\d+) IP (\d+\.\d+\.\d+\.\d+)\.(\d+) > (\d+\.\d+\.\d+\.\d+)\.(\d+).*length (\d+)/ ) {

        ($hour, $min, $sec, $src_ip, $src_port, $dst_ip, $dst_port, $pkt_len) = 
            ($1+0, $2+0, $3+0.0, $4, $5+0, $6, $7+0, $8+0);

        ## only use server -> client to calculate throughput
        next if($src_ip ne $server || $src_port ne $server_port);

        ## quick process
        $time = ($hour * 60 + $min) * 60 + $sec;


        print join(", ", ($hour, $min, $sec, $time, $src_ip, $src_port, $dst_ip, $dst_port, $pkt_len) )."\n" if ($DEBUG0);
    }
    else {
        die $_;
    }


    #####
    ## calculate throuphput per interval
    $interval_start = int($time) if($interval_start == -1);
    $small_interval_start = int($time) if($small_interval_start == -1);
    die "current time is prior to the interval start time: $time v.s. $interval_start\n" if($time < $interval_start);

    print $interval_start."~".($interval_start + $interval).":".$time."\n" if($DEBUG0);
    #####
    ## small interval:
    ## the packet belongs to current interval
    if($time < $small_interval_start + $small_interval) {
        $small_interval_sum += $pkt_len;
    }
    ## the packet belongs to next interval
    else {
        while($time >= $small_interval_start + $small_interval) {
            push(@small_interval_throughput, $small_interval_sum*8/$small_interval/1000);
            $small_interval_sum = 0;
            $small_interval_start += $small_interval;
        }

        $small_interval_sum += $pkt_len;
    }

    #####
    ## desired interval:
    ## the packet belongs to current interval
    if($time < $interval_start + $interval) {
        $interval_sum += $pkt_len;
    }

    ## the packet belongs to next interval
    else {
        while($time >= $interval_start + $interval) {
            ## small interval: get mean and variation
            my $throughput_mean  = mean (\@small_interval_throughput);
            my $throughput_variance = variance(\@small_interval_throughput);
            print @small_interval_throughput.":".join(", ", @small_interval_throughput)."\n" if($DEBUG0);
            @small_interval_throughput = ();

            $interval_ind ++;
            print "".($interval_ind * $interval)." ".$interval_sum." ".$throughput_mean." ".$throughput_variance."\n";
            print FH_OUT "".($interval_ind * $interval)." ".$interval_sum." ".$throughput_mean." ".$throughput_variance."\n";
            $interval_sum = 0;
            $interval_start += $interval;
        }

        $interval_sum += $pkt_len;
    }
}

## small interval: get mean and variation
my $throughput_mean  = mean (\@small_interval_throughput);
my $throughput_variance = variance(\@small_interval_throughput);
@small_interval_throughput = ();

$interval_ind ++;
print "".($interval_ind * $interval)." ".$interval_sum." ".$throughput_mean." ".$throughput_variance."\n";
print FH_OUT "".($interval_ind * $interval)." ".$interval_sum." ".$throughput_mean." ".$throughput_variance."\n";


close FH;
close FH_OUT;



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










