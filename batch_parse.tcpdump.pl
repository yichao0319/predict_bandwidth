#!/bin/perl

use strict;

my @intervals = (1);

foreach my $interval (@intervals) {
    # system("perl parse.tcpdump.pl tcpdump.campus.walking.tcp.dat $interval 128.83.144.185 22");
    # system("perl parse.tcpdump.pl tcpdump.home.shuttle.tcp.dat $interval 128.83.144.185 22");
    # system("perl parse.tcpdump.pl tcpdump.home.static.tcp.dat $interval 128.83.120.56 22");
    # system("perl parse.tcpdump.pl tcpdump.home.walking.tcp.dat $interval 128.83.144.185 22");
    # system("perl parse.tcpdump.pl tcpdump.home.walking2.tcp.dat $interval 128.83.144.185 22");
    # system("perl parse.tcpdump.pl tcpdump.office.static.midnight.tcp.dat $interval 128.83.144.185 22");
    # system("perl parse.tcpdump.pl tcpdump.office.static.tcp.dat $interval 128.83.144.185 22");
    # system("perl parse.tcpdump.pl tcpdump.driving.highway.midnight.tcp.dat $interval 128.83.144.185 22");
    # system("perl parse.tcpdump.pl tcpdump.driving.midnight1.tcp.dat $interval 128.83.144.185 22");
    # system("perl parse.tcpdump.pl tcpdump.driving.midnight2.tcp.dat $interval 128.83.144.185 22");
    # system("perl parse.tcpdump.pl tcpdump.driving.midnight3.tcp.dat $interval 128.83.144.185 22");
    # system("perl parse.tcpdump.pl 20050817-receiver-all.dump $interval 211.234.151.76 5001");
    # system("perl parse.tcpdump.pl 20050820-receiver-all.dump $interval 211.234.176.160 5001");
    system("perl parse.tcpdump.pl 20050907-downlink-receiver.dump $interval 211.234.155.253 5001");
}

