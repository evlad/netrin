#!/usr/bin/tclsh

#!/bin/sh
# \
#exec tclsh "$0" ${1+"$@"}

# Arguments are files made by sampled_data_flow.tcl with next special lines:
# # start date&time: 2015-09-01 00:00:19
# # start unix time: 1441054808

# At least one file must be mentioned in command line
if {[llength $argv] == 0} {
    error "At least one file name must be supplied."
}

# Try to open each file
foreach fname $argv {
    if {[catch {lappend fdlist [open $fname]} errmsg]} {
	puts "# failed: $fname: $errmsg"
    } else {
	puts "# source file: $fname"
    }
}

# Read each file to find start date
array set fddatetime {}
array set fdunixtime {}
for {set i 0} {$i < [llength $fdlist]} {incr i} {
    set datetime ""
    set unixtime ""
    while {[gets [lindex $fdlist $i] line]} {
	set fields [regexp -all -inline {\S+} $line]
	if {[lindex $fields 0] == "#" && [lindex $fields 1] == "start" && \
		[lindex $fields 2] == "date&time:"} {
	    set datetime "[lindex $fields 3] [lindex $fields 4]"
	}
	if {[lindex $fields 0] == "#" && [lindex $fields 1] == "start" && \
		[lindex $fields 2] == "unix" && [lindex $fields 3] == "time:"} {
	    set unixtime [lindex $fields 4]
	}
	if {$datetime != "" && $unixtime != ""} {
	    # Rewind file
	    seek [lindex $fdlist $i] 0 start
	    set fddatetime($i) $datetime
	    set fdunixtime($i) $unixtime
	    break
	}
    }
}

# Find the maximum unix time among fdunixtime
set maxunixtime {}
set maxi {}
foreach i [array names fdunixtime] {
    if {$maxi == {}} {
	set maxi $i
	set maxunixtime $fdunixtime($i)
    } elseif {$maxunixtime < $fdunixtime($i)} {
	set maxi $i
	set maxunixtime $fdunixtime($i)
    }
}

# Calculate number of records to skip
array set fdskiplines {}
foreach i [array names fdunixtime] {
    set fdskiplines($i) [expr $maxunixtime - $fdunixtime($i)]
}

# Let's compose leading comments:
puts "# start date&time: $fddatetime($maxi)"
puts "# start unix time: $fdunixtime($maxi)"

# Let's skip several leading lines
foreach i [array names fdunixtime] {
    # Every file should be processed
    for {set lineno 0} {$lineno < $fdskiplines($i)} { } {
	if {[gets [lindex $fdlist $i] linerec] >= 0} {
	    if {[string first "#" $linerec] == -1} {
		# dataline
		incr lineno
	    }
	}
    }
}

# Let's compose bulk output
for {set ti 0} { 1 } {incr ti} {
    # Generate time index automatically
    set oline "$ti"

    # Scan all files to take their value
    set ncol 0
    for {set i 0} {$i < [llength $fdlist]} {incr i} {
	while {[gets [lindex $fdlist $i] linerec] >= 0} {
	    # Split each line into fields by spaces
	    set fields [regexp -all -inline {\S+} $linerec]
	    if {![string match "#*" [lindex $fields 0]]} {
		# dataline
		append oline " [lindex $fields 1]"
		incr ncol
		break
	    }
	}
    }

    # Number of columns should be equal to number of files, otherwise
    # EOF of at least one file was reached
    if {$ncol != [llength $fdlist]} {
	# no new data
	break
    }

    # Place line to output
    puts $oline
}

puts "# records number: $ti"

# End of file
