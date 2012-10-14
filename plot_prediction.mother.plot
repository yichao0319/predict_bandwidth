reset
set terminal postscript eps 28
set size ratio 0.5
set pointsize 2
set xlabel "Time (seconds)";
# set nokey;
set key Left above reverse horizontal nobox spacing 1

filename = XXX
target = XXX
srcfile = "./PARSEDDATA/".filename.".".target.".raw.txt"
ewmafile = "./PARSEDDATA/".filename.".".target.".ewma.txt"
hwfile = "./PARSEDDATA/".filename.".".target.".hw.txt"

set output "figures/".filename.".".target.".ps"


set ylabel target;

set style line 1 lc rgb "#FF0000" lt 1 lw 4
set style line 2 lc rgb "#0000FF" lt 2 lw 3
set style line 3 lc rgb "orange" lt 3 lw 3
set style line 4 lc rgb "green" lt 4 lw 3
set style line 5 lc rgb "yellow" lt 1 lw 3
set style line 6 lc rgb "black" lt 2 lw 3




plot srcfile using 1:2 with lines t target ls 1, \
ewmafile using 1:2 with lines t "EWMA" ls 2, \
hwfile using 1:2 with lines t "Holt-Winters" ls 3


#####################################################

set ylabel target;
ewmafile = "./PARSEDDATA/".filename.".".target.".ewma.err.txt"
hwfile = "./PARSEDDATA/".filename.".".target.".hw.err.txt"

set output "./figures/".filename.".".target.".err.ps"

# set yrange [0:3000000]
set xrange [50:]

plot srcfile using 1:2 with lines t target ls 1, \
ewmafile using 1:2 with lines t "EWMA - error" ls 2, \
hwfile using 1:2 with lines t "Holt-Winters - error" ls 3
