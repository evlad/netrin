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

### The first argument is a maximum records count to investigate
### (10000 by default; negative is infinity)
set maxreccount [lindex $argv 0]
if { ! [ string is integer $maxreccount ] || $maxreccount == "" } {
    # Default
    set maxreccount 10000
}

puts "###2### maxreccount=$maxreccount"
set reccount 0

set maxstep 0
set maxsteps {}
set sflowprev {}

set maxdurat 0

while {[gets stdin line] >= 0} {
    set fields [regexp -all -inline {\S+} $line]
    set sdate [lindex $fields 0]
    set stime [lindex $fields 1]
    if {[string first . $stime] != -1} {
	set n [expr [string first . $stime] - 1]
	set stime [string range $stime 0 $n]
    }
    #foreach s $fields { puts $s }

    set datetime "$sdate $stime"
    set durat [lindex $fields 2]
    if {[string first . $durat] != -1} {
	set n [expr [string first . $durat] - 1]
	set durat [string range $durat 0 $n]
    }

    if {$durat > $maxdurat && $durat < 10000} {
	set maxdurat $durat
    }

    if { [catch {set sflow [clock scan $datetime]}] } {
	# Error - not a date-time format, let's skip
	continue
    }

    set sflow [clock scan $datetime]
    set eflow [expr $sflow + $durat]
    set flowbytes [lindex $fields 8]

    if {$sflowprev != {}} {
	set sstep [expr $sflow - $sflowprev]
    } else {
	set sstep 0
	set startdatetime $datetime
    }
    set sflowprev $sflow
    if {$sstep > $maxstep} {
	set maxstep $sstep
    }
    if {[lsearch -exact $maxsteps $sstep] == -1} {
	lappend maxsteps $sstep
    }
    if {$durat == 0} {
	# This timestamp only
	set _puts "$sflow $eflow $flowbytes"
    } else {
	set flowbps [expr $flowbytes / $durat]
	if {$flowbps >= 1} {
	    # Add
	    set _puts "$sflow $eflow $flowbps"
	}
    }

    incr reccount
    if { $reccount >= $maxreccount && $maxreccount >= 0 } {
	puts "start:  $startdatetime"
	puts "finish: $datetime"
	puts "number of records = $maxreccount"
	puts "max step = $maxstep"
	puts "steps: [lsort -integer $maxsteps]"
	puts "max durat: $maxdurat"
	exit 0
    }
}

# End of file
