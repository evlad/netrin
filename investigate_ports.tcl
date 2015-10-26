#!/usr/bin/tclsh

#!/bin/sh
# \
#exec tclsh "$0" ${1+"$@"}

# Example of nfdump with default arguments:
# Date flow start          Duration Proto      Src IP Addr:Port          Dst IP Addr:Port   Packets    Bytes Flows
# 2015-08-31 23:59:54.014     0.000 UDP            8.8.8.8:53    ->   91.244.183.251:29728        1      191     1
#
# Fields:
# 0          1                2     3              4             5    6                           7      8       9

### The first argument is target IP
set targetip [regexp -inline {^\d+\.\d+\.\d+\.\d+$} [lindex $argv 0] ]
if { $targetip == "" } {
    error "Need to define target IP"
    exit 1
}

puts "###1### targetip=$targetip"

### The second argument is a maximum records count (1000 by default; negative is infinity)
set maxreccount [lindex $argv 1]
if { ! [ string is integer $maxreccount ] || $maxreccount == "" } {
    # Default 1000
    set maxreccount 1000
}

puts "###2### maxreccount=$maxreccount"

set reccount 0
set maxstep 0
set maxsteps {}
set sflowprev {}
set starttime {}

array set targetports {}

while {[gets stdin line] >= 0} {
    set fields [regexp -all -inline {\S+} $line]
    #foreach s $fields { puts $s }

    set sdate [lindex $fields 0]
    set stime [lindex $fields 1]
    set stime [lindex $fields 1]
    if {[string first . $stime] != -1} {
	# Strip subseconds
	set n [expr [string first . $stime] - 1]
	set stime [string range $stime 0 $n]
    }
    set datetime "$sdate $stime"
    if { [catch {set sflow [clock scan $datetime]}] } {
	# Error - not a date-time format, let's skip
	continue
    }

    set src [lindex $fields 4]
    set dst [lindex $fields 6]

    regexp {^(\d+\.\d+\.\d+\.\d+):(\d+)$} $src smatch sip sport
    regexp {^(\d+\.\d+\.\d+\.\d+):(\d+)$} $dst dmatch dip dport

    # Match source or destination port with target IP and count
    # transferred bytes
    if { $sip == $targetip } {
	if { $sport < 1024 } {
	    incr targetports($sport) [lindex $fields 8]
	}
    }
    if { $dip == $targetip } {
	if { $dport < 1024 } {
	    incr targetports($dport) [lindex $fields 8]
	}
    }

    #puts "reccount=$reccount"
    incr reccount
    if { $reccount >= $maxreccount && $maxreccount >= 0 } {
	#puts "start: $startdatetime"
	#puts "finish: $datetime"
	#puts "number of records = $maxreccount"
	#puts "max step = $maxstep"
	#puts "steps: [lsort -integer $maxsteps]"
	break
    }
}

foreach {p b} [array get targetports] {
    puts "$p:  $b"
}

# End of file
