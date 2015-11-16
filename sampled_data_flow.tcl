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

# include NFSampler procedure 
source sampler.tcl

### The first argument is a sampling rate (1s by default)
set srate [lindex $argv 0]
if { [ string is integer $srate ] } {
    if { $srate <= 0 } {
	# Default 1s
	set srate 1
    }
} else {
    # Default 1s
    set srate 1
}

puts "###1### srate=$srate"

### The second argument is a maximum records count (1000 by default; negative is infinity)
set maxreccount [lindex $argv 1]
if { ! [ string is integer $maxreccount ] || $maxreccount == "" } {
    set maxreccount 10000
}

puts "###2### maxreccount=$maxreccount"


set reccount 0
set maxstep 0
set maxsteps {}
set sflowprev {}
set starttime {}

# Reset buffer
NFSampler {} 0 0 600


# For all input lines
while {[gets stdin line] >= 0} {
    # Split each line into fields by spaces
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
	set reslist [NFSampler $sflow $durat $flowbytes]
	#puts "A $sflow $eflow $flowbytes"
    } else {
	set flowbps [expr $flowbytes / $durat]
	if {$flowbps >= 1} {
	    # Add
	    set reslist [NFSampler $sflow $durat $flowbytes]
	    #puts "B $sflow $eflow $flowbps"
	}
    }

    foreach o $reslist {
	if { $starttime == {} } {
	    set starttime [lindex $o 0]
	    puts "# start date&time: $datetime"
	    puts "# start unix time: $starttime"
	    puts "# sampling rate: $srate"
	    puts "# requested records: $maxreccount"
	}
	puts "[expr [lindex $o 0] - $starttime] [lindex $o 1]"
    }

    #puts "reccount=$reccount"
    incr reccount
    if { $reccount >= $maxreccount && $maxreccount >= 0 } {
	break
    }
}

puts "# records number: $reccount"

# End of file
