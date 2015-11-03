
# Find all TCP ports (1..1024) in the first 1000 records at 4 september 2015
addr=91.244.183.5
numrec=1000
nfdump -R gw1/2015/09/04 "proto tcp and ip $addr" | ./investigate_ports.tcl $addr $numrec

# Output should be:
# ###1### targetip=91.244.183.5
# ###2### maxreccount=1000
# Port BytePassed
#   80:       602
#  443:       348
