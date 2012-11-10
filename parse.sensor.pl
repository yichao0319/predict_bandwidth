#####################################
## Yi-Chao Chen
## perl parse.sensor.pl sensor.driving.midnight1.dat 3
##
## input:
##   input_filename: sensor data
##   interval: in second
##
## output:
##   input_filename.sensor.interval.txt
##     <time> <xMag mean> <xMag var> <yMag mean> <yMag var> <zMag mean> <zMag var> <xAccel mean> <xAccel var> <yAccel mean> <yAccel var> <zAccel mean> <zAccel var> <lat mean> <lat var> <lng mean> <lng var> <alt mean> <alt var> <xRate mean> <xRate var> <yRate mean> <yRate var> <zRate mean> <zRate var> <roll mean> <roll var> <pitch mean> <pitch var> <yaw mean> <yaw var>


#!/bin/perl

use strict;

require "./utils.pl";


my $DEBUG0 = 0;
my $DEBUG = 1;

my $MINUS_INFINITY = -99999;


#####
## global variables
my $raw_dir = "./RAWDATA";
# my $raw_dir = "/var/local/yichao/mobile_streaming/RAWDATA";
# my $raw_dir = "./mobile_trace";
my $output_dir = "PARSEDDATA";
my $file;
my $output_file;
my $cnt = 0;

my $interval;
my $interval_start = -1;
my %interval_readings = ();
my $interval_ind = 0;

#####
## inputs
if($#ARGV != 1) {
    die "wrong number of inputs: ".$#ARGV."\n";
}
$file = $ARGV[0];
print $file."\n" if($DEBUG);
$interval = $ARGV[1] + 0;
$output_file = $file.".sensor.".$interval.".txt";


#####
## main 
open FH, "< $raw_dir/$file" or die $!;
open FH_OUT, ">$output_dir/$output_file" or die $!;
while(<FH>) {
    print $_ if($DEBUG0);

    $cnt ++;
    next if($cnt < 3);


    #############
    ## parse a line
    ## ElapsedTime(s) xMag(uT) yMag(uT) zMag(uT) xAccel(g) yAccel(g) zAccel(g) latitude(deg) longitude(deg) altitude(m) xRate(rad/sec) yRate(rad/sec) zRate(rad/sec) roll(rad) pitch(rad) yaw(rad)
    # my ($time, $xMag, $yMag, $zMag, $xAccel, $yAccel, $zAccel, $lat, $lng, $alt, $xRate, $yRate, $zRate, $roll, $pitch, $yaw);
    my ($time, @readings) = split(/ /, $_); 
    
    ## quick process
    for(my $i = 0; $i < @readings; $i ++) {
        if($readings[$i] =~ /null/) {
            $readings[$i] = $MINUS_INFINITY;
        }
        else {
            $readings[$i] += 0;
        }
    }
    print join(", ", (@readings))."\n" if($DEBUG0);


    #####
    ## calculate mean/variance per interval
    $interval_start = int($time) if($interval_start == -1);
    die "current time is prior to the interval start time: $time v.s. $interval_start\n" if($time < $interval_start);

    print $interval_start."~".($interval_start + $interval).":".$time."\n" if($DEBUG0);
    

    #####
    ## desired interval:
    ## the reading belongs to current interval
    if($time < $interval_start + $interval) {
        for(my $i = 0; $i < @readings; $i ++) {
            push(@{$interval_readings{$i}}, $readings[$i]);
        }
    }

    ## the packet belongs to next interval
    else {
        while($time >= $interval_start + $interval) {
            $interval_ind ++;
            print "".($interval_ind * $interval);
            print FH_OUT "".($interval_ind * $interval);

            foreach my $key (sort {$a <=> $b} (keys %interval_readings)) {
                my $mean = mean(\@{$interval_readings{$key}});
                my $var  = variance(\@{$interval_readings{$key}});
                print " ".$mean." ".$var;
                print FH_OUT " ".$mean." ".$var;

                @{$interval_readings{$key}} = ();
            }
            print "\n";
            print FH_OUT "\n";
            
            $interval_start += $interval;
        }

        for(my $i = 0; $i < @readings; $i ++) {
            push(@{$interval_readings{$i}}, $readings[$i]);
        }
        # exit;
    }
}

$interval_ind ++;
print "".($interval_ind * $interval);
print FH_OUT "".($interval_ind * $interval);
foreach my $key (sort {$a <=> $b} (keys %interval_readings)) {
    my $mean = mean(\@{$interval_readings{$key}});
    my $var  = variance(\@{$interval_readings{$key}});
    print " ".$mean." ".$var;
    print FH_OUT " ".$mean." ".$var;

    @{$interval_readings{$key}} = ();
}
print "\n";
print FH_OUT "\n";


close FH;
close FH_OUT;


#####
## plot figures
system("sed 's/filename = XXX/filename = \"$output_file\"/' plot_sensor.mother.plot > plot_sensor.plot");
system("gnuplot plot_sensor.plot");


