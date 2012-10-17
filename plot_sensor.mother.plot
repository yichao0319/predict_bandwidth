reset
set terminal postscript eps 28
set size ratio 0.5
set pointsize 2
set xlabel "Time (seconds)";
# set nokey;
set key Left above reverse horizontal nobox spacing 1

filename = XXX
srcfile = "PARSEDDATA/".filename

set output "figures/".filename.".mag.ps"


set ylabel "Mag (uT)";

set style line 1 lc rgb "#FF0000" lt 1 lw 4
set style line 2 lc rgb "#0000FF" lt 2 lw 3
set style line 3 lc rgb "orange" lt 3 lw 3
set style line 4 lc rgb "green" lt 4 lw 3
set style line 5 lc rgb "yellow" lt 1 lw 3
set style line 6 lc rgb "black" lt 2 lw 3




plot srcfile using 1:2 with lines t "" ls 1, \
srcfile using 1:2:3 with errorbars t "x" ls 1, \
srcfile using 1:4 with lines t "" ls 2, \
srcfile using 1:4:5 with errorbars t "y" ls 2, \
srcfile using 1:6 with lines t "" ls 3, \
srcfile using 1:6:7 with errorbars t "z" ls 3


##############################################################

set output "figures/".filename.".accel.ps"

set ylabel "Accel (g)";

plot srcfile using 1:8 with lines t "" ls 1, \
srcfile using 1:8:9 with errorbars t "x" ls 1, \
srcfile using 1:10 with lines t "" ls 2, \
srcfile using 1:10:11 with errorbars t "y" ls 2, \
srcfile using 1:12 with lines t "" ls 3, \
srcfile using 1:12:13 with errorbars t "z" ls 3


##############################################################

set output "figures/".filename.".gps.ps"

set ylabel "GPS";

plot srcfile using 1:14 with lines t "" ls 1, \
srcfile using 1:14:15 with errorbars t "lat" ls 1, \
srcfile using 1:16 with lines t "" ls 2, \
srcfile using 1:16:17 with errorbars t "lng" ls 2, \
srcfile using 1:18 with lines t "" ls 3, \
srcfile using 1:18:19 with errorbars t "alt" ls 3


##############################################################

set output "figures/".filename.".gyros_xyz.ps"

set ylabel "Gyros (deg/s)";

plot srcfile using 1:20 with lines t "" ls 1, \
srcfile using 1:20:21 with errorbars t "x" ls 1, \
srcfile using 1:22 with lines t "" ls 2, \
srcfile using 1:22:23 with errorbars t "y" ls 2, \
srcfile using 1:24 with lines t "" ls 3, \
srcfile using 1:24:25 with errorbars t "z" ls 3


##############################################################

set output "figures/".filename.".gyros.ps"

set ylabel "Gyros (deg)";

plot srcfile using 1:26 with lines t "" ls 1, \
srcfile using 1:26:27 with errorbars t "roll" ls 1, \
srcfile using 1:28 with lines t "" ls 2, \
srcfile using 1:28:29 with errorbars t "pitch" ls 2, \
srcfile using 1:30 with lines t "" ls 3, \
srcfile using 1:30:31 with errorbars t "yaw" ls 3



