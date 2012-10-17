#!/bin/perl

use strict;

my $METHOD_EWMA = "EWMA";
my $METHOD_HW = "HW";
my $METHOD_ALL = "ALL";



my @files = (
    "sensor.driving.highway.midnight.dat", 
    "sensor.driving.midnight1.dat",
    "sensor.driving.midnight2.dat",
    "sensor.driving.midnight3.dat",
    );
my @intervals = (3);


foreach my $file (@files) {
    foreach my $interval (@intervals) {
        system("perl parse.sensor.pl $file $interval");
    }
}

