#!/bin/bash

year=2015
mon=09
day=01
ipports="5.80 5.443 3.22 8.80"

indir=gw1/$year/$mon/$day
outdir=o
for ipport in $ipports ; do
  ip=${ipport%.*}
  ipaddr=91.244.183.$ip
  port=${ipport#*.}
  echo "Processing IP=$ipaddr Port=$port"
  nfdump -R $indir "proto tcp and src ip $ipaddr and src port $port" | ./sampled_data_flow.tcl 1 -1 >$outdir/$mon$day-$ip.$port.out.txt
  nfdump -R $indir "proto tcp and dst ip $ipaddr and dst port $port" | ./sampled_data_flow.tcl 1 -1 >$outdir/$mon$day-$ip.$port.in.txt
  ./paste_data_flows.tcl $outdir/$mon$day-$ip.$port.in.txt $outdir/$mon$day-$ip.$port.out.txt >$outdir/$mon$day-$ip.$port.inout.txt 
done

# End of file
