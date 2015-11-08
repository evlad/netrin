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
set targetnetc [regexp -inline {^\d+\.\d+\.\d+\.$} [lindex $argv 0] ]
set targetip [regexp -inline {^\d+\.\d+\.\d+\.\d+$} [lindex $argv 0] ]
if { $targetip == "" && $targetnetc == "" } {
    error "Need to define target IP or target network mask (class C)"
    exit 1
}

if { $targetip != ""} {
    puts "###1### targetip=$targetip"
} elseif {$targetnetc != ""} {
    puts "###1### targetnetc=$targetnetc"
}

### The second argument is a maximum records count to investigate
### (1000 by default; negative is infinity)
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

array set sports {}
array set dports {}

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
    set bytespassed [lindex $fields 8]
    set multiplier [lindex $fields 9]
    if { $multiplier == "M" } {
	set bytespassed [expr int($bytespassed * 1024 * 1024)]
    }
    #if { ! [string is integer $bytespassed] } {
    #	puts "Wrong bytes; record $line"
    #	continue
    #}

    if { $targetip != "" } {
	if { $sip == $targetip } {
	    if { $sport < 1024 } {
		incr targetports($sport) $bytespassed
	    }
	}
	if { $dip == $targetip } {
	    if { $dport < 1024 } {
		incr targetports($dport) $bytespassed
	    }
	}
    } elseif { $targetnetc != "" } {
	if { [string match $targetnetc* $sip ] } {
	    if { $sport < 1024 } {
		incr sports($sport) $bytespassed
	    }
	}
	if { [string match $targetnetc* $dip ] } {
	    if { $dport < 1024 } {
		incr dports($dport) $bytespassed
	    }
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

# By port number
proc PortCompare {a b} {
    set aport [lindex $a 0]
    set bport [lindex $b 0]
    if { $aport == "" || $bport == "" } {
	return 0
    }
    return [expr $aport - $bport]
}

# By popularity
proc BytePassedCompare {a b} {
    set abytes [lindex $a 1]
    set bbytes [lindex $b 1]
    if { $abytes == "" || $bbytes == "" } {
	return 0
    }
    return [expr $abytes - $bbytes]
}

# Transform arrays into lists
set srecords {}
foreach {p b} [array get sports] {
    lappend srecords "$p $b"
}
set drecords {}
foreach {p b} [array get dports] {
    lappend drecords "$p $b"
}

# Display results and sort them by popularity
puts "###3### SrcPort BytePassed"
#foreach r [lsort -increasing -integer -index 0 $srecords] {
foreach r [lsort -decreasing -integer -index 1 $srecords] {
    set p [lindex $r 0]
    set b [lindex $r 1]
    puts [format "%4d %10d" $p $b]
}
puts "###4### DstPort BytePassed"
#foreach r [lsort -increasing -integer -index 0 $drecords] {
foreach r [lsort -decreasing -integer -index 1 $drecords] {
    set p [lindex $r 0]
    set b [lindex $r 1]
    puts [format "%4d %10d" $p $b]
}

# End of file
