#!/bin/perl

use strict;

my @intervals = (3);

foreach my $interval (@intervals) {
    system("perl parse.tcpdump.pl tcpdump.campus.walking.tcp.dat $interval 128.83.144.185 22");
    system("perl parse.tcpdump.pl tcpdump.home.shuttle.tcp.dat $interval 128.83.144.185 22");
    system("perl parse.tcpdump.pl tcpdump.home.static.tcp.dat $interval 128.83.120.56 22");
    system("perl parse.tcpdump.pl tcpdump.home.walking.tcp.dat $interval 128.83.144.185 22");
    system("perl parse.tcpdump.pl tcpdump.home.walking2.tcp.dat $interval 128.83.144.185 22");
    system("perl parse.tcpdump.pl tcpdump.office.static.midnight.tcp.dat $interval 128.83.144.185 22");
    system("perl parse.tcpdump.pl tcpdump.office.static.tcp.dat $interval 128.83.144.185 22");
    system("perl parse.tcpdump.pl tcpdump.driving.highway.midnight.tcp.dat $interval 128.83.144.185 22");
    system("perl parse.tcpdump.pl tcpdump.driving.midnight1.tcp.dat $interval 128.83.144.185 22");
    system("perl parse.tcpdump.pl tcpdump.driving.midnight2.tcp.dat $interval 128.83.144.185 22");
    system("perl parse.tcpdump.pl tcpdump.driving.midnight3.tcp.dat $interval 128.83.144.185 22");
}

