#####################################
## Yi-Chao Chen
##
## input:
##   time_series
##   alpha
##
## output:
##   predicted_time_series


#!/bin/perl

use strict;
require "./utils.pl";


sub ewma {

    my $MINUS_INFINITY = -99999;


    #####
    ## input
    if(@_ != 2) {
        die "wrong number of input: ".$#_."\n";
    }
    my ($timeseries_ref, $ewma_alpha) = @_;


    #####
    ## variables
    my @ewma;
    my @ewma_dev;   ## Lili's formula: smooth_dev = (1-beta) smooth_dev + beta * |smooth_load - curr_load |;
    my @ewma_dev2;  ## s_ewma^2 = (alpha/(2-alpha)) * s^2
    my $ewma_pred = $MINUS_INFINITY;
    my $ewma_dev_pred;



    foreach my $target_value (@$timeseries_ref) {
        #####
        ## ewma: 
        ##    S_1 = Y_1
        ##    S_t = alpha * Y_t + (1 - alpha) * S_t-1
        if($ewma_pred == $MINUS_INFINITY) {
            push(@ewma, 0);                 ## predict the first one as 0
            push(@ewma_dev, 0);
            push(@ewma_dev2, 0);
            $ewma_pred = $target_value;     ## the second prediction is just the first measurement
            $ewma_dev_pred = $target_value / 2;
        }
        else {
            $ewma_dev_pred = $ewma_alpha * abs($target_value - $ewma_pred) + (1 - $ewma_alpha) * $ewma_dev_pred;
            $ewma_pred = $ewma_alpha * $target_value + (1 - $ewma_alpha) * $ewma_pred;
        }
        push(@ewma, $ewma_pred);
        push(@ewma_dev, $ewma_dev_pred);
        ## variance: s_ewma^2 = (alpha/(2-alpha)) * s^2
        push(@ewma_dev2, sqrt($ewma_alpha/(2-$ewma_alpha) * variance($timeseries_ref) ) );
    }

    if(@ewma == 0) {
        push(@ewma, 0);
        push(@ewma, 0);
        push(@ewma_dev, 0);
        push(@ewma_dev, 0);
    }
    
    return (\@ewma, \@ewma_dev);
}

1;