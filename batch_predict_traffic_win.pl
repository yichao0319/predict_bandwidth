#!/bin/perl

use strict;

my $METHOD_EWMA = "EWMA";
my $METHOD_HW = "HW";
my $METHOD_LPEWMA = "LPEWMA";
my $METHOD_GAEWMA = "GAEWMA";
my $METHOD_ALL = "ALL";



my @files = (
    # "tcpdump.campus.walking.tcp.dat.throughput.", 
    # "tcpdump.home.shuttle.tcp.dat.throughput.",
    # "tcpdump.home.static.tcp.dat.throughput.",
    # "tcpdump.home.walking.tcp.dat.throughput.",
    # "tcpdump.home.walking2.tcp.dat.throughput.",
    # "tcpdump.office.static.tcp.dat.throughput.",
    # "tcpdump.office.static.midnight.tcp.dat.throughput.", 
    # "tcpdump.driving.highway.midnight.tcp.dat.throughput.",
    # "tcpdump.driving.midnight1.tcp.dat.throughput.",
    # "tcpdump.driving.midnight2.tcp.dat.throughput.",
    # "tcpdump.driving.midnight3.tcp.dat.throughput.",

    ## wei's trace
    "05mph-day4.server.ap.tcpbulk.20050325-231708.tcpdump.throughput.",
    "05mph-day4.server.ap.tcpbulk.20050325-232445.tcpdump.throughput.",
    "15mph-day4.client.ap.tcpbulk.20050325-222242.tcpdump.throughput.",
    "15mph-day4.client.ap.tcpbulk.20050325-222612.tcpdump.throughput.",
    "15mph-day4.server.ap.tcpbulk.20050325-222256.tcpdump.throughput.",
    "15mph-day4.server.ap.tcpbulk.20050325-222630.tcpdump.throughput.",
    "20050817-receiver-all.dump.throughput.",
    "20050820-receiver-all.dump.throughput.",
    "20050907-downlink-receiver.dump.throughput.",
    "25mph-day4.client.ap.tcpbulk.20050325-211758.tcpdump.throughput.",
    "25mph-day4.server.ap.tcpbulk.20050325-211736.tcpdump.throughput.",
    "25mph-day4.server.ap.tcpbulk.20050325-212043.tcpdump.throughput.",
    "35mph-day4.client.ap.tcpbulk.20050325-214332.tcpdump.throughput.",
    "35mph-day4.server.ap.tcpbulk.20050325-214355.tcpdump.throughput.",
    "55mph-day4.client.ap.tcpbulk.20050325-224437.tcpdump.throughput.",
    "55mph-day4.server.ap.tcpbulk.20050325-224207.tcpdump.throughput.",
    "55mph-day4.server.ap.tcpbulk.20050325-224506.tcpdump.throughput.",
    "75mph-day4.client.ap.tcpbulk.20050325-234915.tcpdump.throughput.",
    "75mph-day4.server.ap.tcpbulk.20050325-234726.tcpdump.throughput.",
    "kw_seoul_st_udp_cbr_5000~6000kbps_iperf_dn_11x300sec_cl_20071012.pcap.throughput.",
    "kw_seoul_st_udp_cbr_5000~6000kbps_iperf_dn_11x300sec_sv_20071012.pcap.throughput.",
    "kw_seoul_st_udp_cbr_5500kbps_iperf_dn_20x120sec_cl_20071005.pcap.throughput.",
    "kw_seoul_st_udp_cbr_5500kbps_iperf_dn_20x120sec_sv_20071005.pcap.throughput.",

    );
my @intervals = (1);
my $win_size = 10;

my @methods = ("EWMA"); #, "HW", "LPEWMA", "GAEWMA");
my @targets = ("THROUGHPUT"); #, "VARIANCE");
# my @ewma_alpha = (0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1);
my @ewma_alpha = (0, 0.1, 0.5, 0.9, 1);
my @hw_alpha = (0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1);
my @hw_beta = (0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1);
my @hw_gamma = (0.1);
my @lpewma_alpha = (0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1);
my @gaewma_alpha = (0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1);


open FH, "> batch_predict_traffic_win.output" or die $!;
foreach my $file (@files) {
    foreach my $interval (@intervals) {

        $file .= "1.txt";
        print "\n$file:\n";

        foreach my $target (@targets) {
            
            foreach my $method (@methods) {

            
                ## EWMA
                if($method eq $METHOD_EWMA) {
                    # print "EWMA:\n";

                    my $min_error;
                    my $best_alpha = -1;
                    foreach my $alpha (@ewma_alpha) {
                        
                        my $cmd = "perl predict_traffic_win.pl $file $target $interval $win_size $method $alpha";
                        my $error = `$cmd` + 0;
                        # print "$alpha $error\n";

                        if($error < $min_error || $best_alpha == -1) {
                            $min_error = $error;
                            $best_alpha = $alpha;
                        }
                    }
                    ## run again the best alpha
                    my $cmd = "perl predict_traffic_win.pl $file $target $interval $win_size $method $best_alpha";
                    my $output = `$cmd`;
                    my ($error) = split(/\t/, $output); 
                    $error += 0;
                    # print "----> best: $best_alpha $error\n";

                    ## remove the following line for Wei's trace
                    # my ($env, $tmp, $trace) = parse_name_for_parameters($file);
                    ## and replace it with the following line
                    my ($env, $tmp, $trace) = ("wei", 1, 1);
                    print "$interval seconds\t$env\t$method\t$target\t";
                    print "$error\t$best_alpha\n";
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
                                my $cmd = "perl predict_traffic_win.pl $file $target $interval $win_size $method $alpha $beta $gamma";
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
                    my $cmd = "perl predict_traffic_win.pl $file $target $interval $win_size $method $best_alpha $best_beta $best_gamma";
                    my $output = `$cmd`;
                    my ($error) = split(/\t/, $output); 
                    $error += 0;
                    # print "----> best\t$best_alpha $best_beta $best_gamma $error\n";
                    my ($env, $tmp, $trace) = parse_name_for_parameters($file);
                    print "$interval seconds\t$env\t$method\t$target\t$error\t$best_alpha,$best_beta\n";
                    print FH "$interval seconds\t$env\t$method\t$target\t$error\t$best_alpha,$best_beta\n";

                }


                ## LPEWMA
                if($method eq $METHOD_LPEWMA) {
                    # print "EWMA:\n";

                    my $min_error;
                    my $best_alpha = -1;
                    foreach my $alpha (@lpewma_alpha) {
                        
                        my $cmd = "perl predict_traffic_win.pl $file $target $interval $win_size $method $alpha";
                        my $error = `$cmd` + 0;
                        # print "$alpha $error\n";

                        if($error < $min_error || $best_alpha == -1) {
                            $min_error = $error;
                            $best_alpha = $alpha;
                        }
                    }
                    ## run again the best alpha
                    my $cmd = "perl predict_traffic_win.pl $file $target $interval $win_size $method $best_alpha";
                    my $output = `$cmd`;
                    my ($error) = split(/\t/, $output); 
                    $error += 0;
                    # print "----> best: $best_alpha $error\n";
                    my ($env, $tmp, $trace) = parse_name_for_parameters($file);
                    print "$interval seconds\t$env\t$method\t$target\t";
                    print "$error\t$best_alpha\n";
                }


                ## GAEWMA
                if($method eq $METHOD_GAEWMA) {
                    # print "EWMA:\n";

                    my $min_error;
                    my $best_alpha = -1;
                    foreach my $alpha (@gaewma_alpha) {
                        
                        my $cmd = "perl predict_traffic_win.pl $file $target $interval $win_size $method $alpha";
                        my $error = `$cmd` + 0;
                        # print "$alpha $error\n";

                        if($error < $min_error || $best_alpha == -1) {
                            $min_error = $error;
                            $best_alpha = $alpha;
                        }
                    }
                    ## run again the best alpha
                    my $cmd = "perl predict_traffic_win.pl $file $target $interval $win_size $method $best_alpha";
                    my $output = `$cmd`;
                    my ($error) = split(/\t/, $output); 
                    $error += 0;
                    # print "----> best: $best_alpha $error\n";
                    my ($env, $tmp, $trace) = parse_name_for_parameters($file);
                    print "$interval seconds\t$env\t$method\t$target\t";
                    print "$error\t$best_alpha\n";
                }
            }
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
