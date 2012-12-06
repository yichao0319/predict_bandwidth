#!/bin/perl

my @files = ("05mph-day4.server.ap.tcpbulk.20050325-231708.tcpdump.throughput.1.txt", 
"05mph-day4.server.ap.tcpbulk.20050325-232445.tcpdump.throughput.1.txt",
"15mph-day4.client.ap.tcpbulk.20050325-222242.tcpdump.throughput.1.txt",
"15mph-day4.client.ap.tcpbulk.20050325-222612.tcpdump.throughput.1.txt",
"15mph-day4.server.ap.tcpbulk.20050325-222256.tcpdump.throughput.1.txt",
"15mph-day4.server.ap.tcpbulk.20050325-222630.tcpdump.throughput.1.txt",
"20050817-receiver-all.dump.throughput.1.txt",
"20050820-receiver-all.dump.throughput.1.txt",
"20050907-downlink-receiver.dump.throughput.1.txt",
"25mph-day4.client.ap.tcpbulk.20050325-211758.tcpdump.throughput.1.txt",
"25mph-day4.server.ap.tcpbulk.20050325-211736.tcpdump.throughput.1.txt",
"25mph-day4.server.ap.tcpbulk.20050325-212043.tcpdump.throughput.1.txt",
"35mph-day4.client.ap.tcpbulk.20050325-214332.tcpdump.throughput.1.txt",
"35mph-day4.server.ap.tcpbulk.20050325-214355.tcpdump.throughput.1.txt",
"55mph-day4.client.ap.tcpbulk.20050325-224437.tcpdump.throughput.1.txt",
"55mph-day4.server.ap.tcpbulk.20050325-224207.tcpdump.throughput.1.txt",
"55mph-day4.server.ap.tcpbulk.20050325-224506.tcpdump.throughput.1.txt",
"75mph-day4.client.ap.tcpbulk.20050325-234915.tcpdump.throughput.1.txt",
"75mph-day4.server.ap.tcpbulk.20050325-234726.tcpdump.throughput.1.txt",
"kw_seoul_st_udp_cbr_5000~6000kbps_iperf_dn_11x300sec_cl_20071012.pcap.throughput.1.txt",
"kw_seoul_st_udp_cbr_5000~6000kbps_iperf_dn_11x300sec_sv_20071012.pcap.throughput.1.txt",
"kw_seoul_st_udp_cbr_5500kbps_iperf_dn_20x120sec_cl_20071005.pcap.throughput.1.txt",
"kw_seoul_st_udp_cbr_5500kbps_iperf_dn_20x120sec_sv_20071005.pcap.throughput.1.txt");

foreach my $file (@files) {
    print $file."\n";

    system("sed 's/XXX/\"$file\"/;' plot_wei_trace.mother.plot > plot_wei_trace.plot");
    system("gnuplot plot_wei_trace.plot");    
}

