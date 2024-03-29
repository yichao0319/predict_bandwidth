#!/bin/perl

use strict;

my $METHOD_EWMA = "EWMA";
my $METHOD_HW = "HW";
my $METHOD_LPEWMA = "LPEWMA";
my $METHOD_GAEWMA = "GAEWMA";
my $METHOD_ALL = "ALL";



my @files = (
    "tcpdump.campus.walking.tcp.dat.throughput.", 
    "tcpdump.home.shuttle.tcp.dat.throughput.",
    "tcpdump.home.static.tcp.dat.throughput.",
    "tcpdump.home.walking.tcp.dat.throughput.",
    "tcpdump.home.walking2.tcp.dat.throughput.",
    "tcpdump.office.static.tcp.dat.throughput.",
    "tcpdump.office.static.midnight.tcp.dat.throughput.", 
    "tcpdump.driving.highway.midnight.tcp.dat.throughput.",
    "tcpdump.driving.midnight1.tcp.dat.throughput.",
    "tcpdump.driving.midnight2.tcp.dat.throughput.",
    "tcpdump.driving.midnight3.tcp.dat.throughput.",
    );
my @intervals = (3);

my @methods = ("EWMA", "HW", "LPEWMA", "GAEWMA");
my @targets = ("THROUGHPUT", "VARIANCE");
my @ewma_alpha = (0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1);
my @hw_alpha = (0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1);
my @hw_beta = (0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1);
my @hw_gamma = (0.1);
my @lpewma_alpha = (0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1);
my @gaewma_alpha = (0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1);


open FH, "> batch_predict_traffic.output" or die $!;
foreach my $file (@files) {
    foreach my $interval (@intervals) {

        $file .= $interval.".txt";
        print "\n$file:\n";

        foreach my $target (@targets) {
            
            foreach my $method (@methods) {

            
                ## EWMA
                if($method eq $METHOD_EWMA) {
                    # print "EWMA:\n";

                    my $min_error;
                    my $best_alpha = -1;
                    foreach my $alpha (@ewma_alpha) {
                        
                        my $cmd = "perl predict_traffic.pl $file $target $method $alpha";
                        my $error = `$cmd` + 0;
                        # print "$alpha $error\n";

                        if($error < $min_error || $best_alpha == -1) {
                            $min_error = $error;
                            $best_alpha = $alpha;
                        }
                    }
                    ## run again the best alpha
                    my $cmd = "perl predict_traffic.pl $file $target $method $best_alpha";
                    my $output = `$cmd`;
                    my ($error, $throughput) = split(/\t/, $output);
                    $error += 0; $throughput += 0;
                    # print "----> best: $best_alpha $error\n";
                    my ($env, $interval, $trace) = parse_name_for_parameters($file);
                    print "$interval seconds\t$env\t$method\t$target\t";
                    print "$error\t$throughput\t$best_alpha\n";
                }


                ## Holt-Winters
                if($method eq $METHOD_HW) {
                    # print "\nHW:\n";

                    my $min_error;
                    my $best_alpha = -1;
                    my $best_beta = -1;
                    my $best_gamma = -1;
                    foreach my $alpha (@hw_alpha) {
                        foreach my $beta (@hw_beta) {
                            foreach my $gamma (@hw_gamma) {
                                my $cmd = "perl predict_traffic.pl $file $target $method $alpha $beta $gamma";
                                my $error = `$cmd` + 0;
                                # print "$alpha $beta $gamma $error\n";

                                if($error < $min_error || $best_alpha == -1) {
                                    $min_error = $error;
                                    $best_alpha = $alpha;
                                    $best_beta = $beta;
                                    $best_gamma = $gamma;
                                }
                            }
                        }
                    }
                        
                        
                    ## run again the best alpha
                    my $cmd = "perl predict_traffic.pl $file $target $method $best_alpha $best_beta $best_gamma";
                    my $output = `$cmd`;
                    my ($error, $throughput) = split(/\t/, $output); 
                    $error += 0; $throughput += 0;
                    # print "----> best\t$best_alpha $best_beta $best_gamma $error\n";
                    my ($env, $interval, $trace) = parse_name_for_parameters($file);
                    print "$interval seconds\t$env\t$method\t$target\t$error\t$throughput\t$best_alpha,$best_beta\n";
                    print FH "$interval seconds\t$env\t$method\t$target\t$error\t$throughput\t$best_alpha,$best_beta\n";

                }


                ## LPEWMA
                if($method eq $METHOD_LPEWMA) {
                    # print "EWMA:\n";

                    my $min_error;
                    my $best_alpha = -1;
                    foreach my $alpha (@lpewma_alpha) {
                        
                        my $cmd = "perl predict_traffic.pl $file $target $method $alpha";
                        my $error = `$cmd` + 0;
                        # print "$alpha $error\n";

                        if($error < $min_error || $best_alpha == -1) {
                            $min_error = $error;
                            $best_alpha = $alpha;
                        }
                    }
                    ## run again the best alpha
                    my $cmd = "perl predict_traffic.pl $file $target $method $best_alpha";
                    my $output = `$cmd`;
                    my ($error, $throughput) = split(/\t/, $output);
                    $error += 0; $throughput += 0;
                    # print "----> best: $best_alpha $error\n";
                    my ($env, $interval, $trace) = parse_name_for_parameters($file);
                    print "$interval seconds\t$env\t$method\t$target\t";
                    print "$error\t$throughput\t$best_alpha\n";
                }


                ## GAEWMA
                if($method eq $METHOD_GAEWMA) {
                    # print "EWMA:\n";

                    my $min_error;
                    my $best_alpha = -1;
                    foreach my $alpha (@gaewma_alpha) {
                        
                        my $cmd = "perl predict_traffic.pl $file $target $method $alpha";
                        my $error = `$cmd` + 0;
                        # print "$alpha $error\n";

                        if($error < $min_error || $best_alpha == -1) {
                            $min_error = $error;
                            $best_alpha = $alpha;
                        }
                    }
                    ## run again the best alpha
                    my $cmd = "perl predict_traffic.pl $file $target $method $best_alpha";
                    my $output = `$cmd`;
                    my ($error, $throughput) = split(/\t/, $output);
                    $error += 0; $throughput += 0;
                    # print "----> best: $best_alpha $error\n";
                    my ($env, $interval, $trace) = parse_name_for_parameters($file);
                    print "$interval seconds\t$env\t$method\t$target\t";
                    print "$error\t$throughput\t$best_alpha\n";
                }
            }

            ## plot
            system("sed 's/filename = XXX/filename = \"$file\"/;s/target = XXX/target = \"$target\"/' plot_prediction.mother.plot > plot_prediction.plot");
            system("gnuplot plot_prediction.plot");
        }


        ## generate output for Yousuk
        foreach my $method (@methods) {
            my $cmd = "perl generate_output.pl $file $method";
            # print $cmd."\n";
            system($cmd);
        }
    }
}




sub parse_name_for_parameters {
    my ($file) = @_;
    my ($env, $interval, $trace);

    #####
    ## Wei's file name
    # if($file =~ /(.*)_throughput_5/) {
    #     # print "5second\t$1 tr1 EWMA\t";
    #     $env = $1;
    #     $interval = 5;
    #     $trace = 1;
    # }
    # elsif($file =~ /(.*)_throughput2_5/) {
    #     # print "5second\t$1 tr2 EWMA\t";
    #     $env = $1;
    #     $interval = 5;
    #     $trace = 2;
    # }
    # elsif($file =~ /(.*)_throughput2/) {
    #     # print "1second\t$1 tr2 EWMA\t";
    #     $env = $1;
    #     $interval = 1;
    #     $trace = 2;
    # }
    # elsif($file =~ /(.*)_throughput/) {
    #     # print "1second\t$1 tr1 EWMA\t";
    #     $env = $1;
    #     $interval = 1;
    #     $trace = 1;
    # }


    #####
    ## Yi-Chao's file name
    if($file =~ /tcpdump\.(.*)\.tcp.*\.(\d+)\./) {
        $env = $1;
        $interval = $2 + 0;
        $trace = 1; ## not used...
    }


    return ($env, $interval, $trace);
}
close FH;
