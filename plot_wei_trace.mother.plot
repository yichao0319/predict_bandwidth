reset
set terminal postscript eps 28
set size ratio 0.5
set pointsize 2
set xlabel "Time (seconds)";
# set nokey;
set key Left above reverse horizontal nobox spacing 1

filename = XXX
srcfile = "/v/filer4b/v27q002/ut-wireless/wdong/traffic_prediction/PARSEDDATA/".filename


set output "./figures2/".filename.".ps"


set style line 1 lc rgb "#FF0000" lt 1 lw 4
set style line 2 lc rgb "#0000FF" lt 2 lw 3
set style line 3 lc rgb "orange" lt 3 lw 3
set style line 4 lc rgb "green" lt 4 lw 3
set style line 5 lc rgb "yellow" lt 1 lw 3
set style line 6 lc rgb "black" lt 2 lw 3




plot srcfile using 1:2 with lines ls 1
