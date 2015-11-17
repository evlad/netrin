
# Procedure with side effect: static buffer to accumulate and
# distribute inputs at almost sequential (but not always) data
# samples.
# Arguments:
#  tj      - time of the sample (seconds) ({} means reset buffer and flush
#            its content)
#  tm      - duration of the sample (seconds)
#  value   - value of the sample
#  nbuflen - length of the buffer (may grow on request)
# Returns:
#  { { t[i] v[i]} { t[i+1] v[i+1] } ... }
proc NFSampler {tj tm value {nbuflen 10}} {
    global tbegin vlist

    if { ![info exists vlist] } {
	# Initialize time of the first index
	set tbegin $tj

	# Initialize list of values
	for { set i 0 } { $i < $nbuflen } { incr i } {
	    lappend vlist 0
	}
    } else {
	for { set i [llength $vlist] } { $i < $nbuflen } { incr i } {
	    lappend vlist 0
	}
    }

    set olist {}

    # Special signal to end of work
    if { $tj == {} } {
	#
	# Special case to flush buffer
	#
	for {set i 0} { $i < $nbuflen } {incr i} {
	    lappend olist "[expr $tbegin + $i] [lindex $vlist $i]"
	}
	unset vlist
    } else {
	set nlist [llength $vlist]

	#
	# Normal case to add values and sometimes flush head of the buffer
	#
	if { $tm != 0 } {
	    set valuepercell [expr $value / $tm]
	} else {
	    set valuepercell $value
	}

	if { $tbegin <= $tj && $tj <= [expr $tbegin + $nlist - 1] \
		 && [expr $tj + $tm - 1] <= [expr $tbegin + $nlist - 1] } {
	    # tbegin              tbegin+nlist-1
	    #      |______________|
	    #             ^-----^
	    #             tj    tj+tm-1

	    #puts "1: tbegin=$tbegin nlist=$nlist  tj=$tj tm=$tm"

	    # Add value per cell
	    for {set i 0} {$i < $tm} {incr i} {
		set k [expr $tj - $tbegin + $i]
		lset vlist $k [expr [lindex $vlist $k] + $valuepercell]
		#puts "vlist($k)=[lindex $vlist $k]"
	    }

	} elseif { $tbegin <= $tj && $tj <= [expr $tbegin + $nlist - 1] \
		       && [expr $tj + $tm - 1] > [expr $tbegin + $nlist - 1] } {
	    # tbegin           tbegin+nlist-1
	    #      |___________|
	    #             ^-----------^
	    #             tj          tj+tm-1

	    #puts "2: tbegin=$tbegin nlist=$nlist  tj=$tj tm=$tm"

	    # Output & append new
	    for {set i 0} {$i < [expr $tj - $tbegin]} {incr i} {
		lappend olist "[expr $tbegin + $i] [lindex $vlist $i]"
		lappend vlist 0
	    }

	    # Trim head
	    set vlist [lrange $vlist [expr $tj - $tbegin] end]

	    # Add value per cell
	    for {set i 0} {$i < $tm && $i < $nlist} {incr i} {
		lset vlist $i [expr [lindex $vlist $i] + $valuepercell]
		#puts "vlist($i)=[lindex $vlist $i]"
	    }

	    # Set new start time
	    set tbegin $tj

	} elseif { $tj < $tbegin && $tbegin <= [expr $tj + $tm - 1] \
		       && [expr $tj + $tm - 1] <= [expr $tbegin + $nlist - 1]} {
	    #       tbegin           tbegin+nlist-1
	    #            |___________|
	    #       ^-----------^
	    #       tj          tj+tm-1

	    #puts "3: tbegin=$tbegin nlist=$nlist  tj=$tj tm=$tm"

	    # Add value per cell
	    for {set i 0} {$i < [expr $tm - $tbegin + $tj] && $i < $nlist} {incr i} {
		lset vlist $i [expr [lindex $vlist $i] + $valuepercell]
		#puts "vlist($i)=[lindex $vlist $i]"
	    }
	} elseif { $tj > [expr $tbegin + $nlist - 1]} {
	    #       tbegin           tbegin+nlist-1
	    #            |___________|
	    #                            ^-------^
	    #                            tj      tj+tm-1

	    #puts "4: tbegin=$tbegin nlist=$nlist  tj=$tj tm=$tm"

	    # Output stored values
	    for {set i 0} {$i < $nlist} {incr i} {
		lappend olist "[expr $tbegin + $i] [lindex $vlist $i]"
	    }

	    # Output zeros
	    for {set i 1} {$i < [expr $tj - $tbegin - $nlist + 1]} {incr i} {
		lappend olist "[expr $tbegin + $nlist - 1 + $i] 0"
	    }

	    # Replace the whole list of stored values
	    set vlist {}

	    # Initialize by value per cell
	    for {set i 0} {$i < $tm && $i < $nlist} {incr i} {
		lappend vlist $valuepercell
		#puts "vlist($i)=[lindex $vlist $i]"
	    }

	    # Fill by zeros the tail
	    for {} {$i < $nlist} {incr i} {
		lappend vlist 0
	    }

	    # Set new start time
	    set tbegin $tj
	}
    }

    return $olist
}

proc NFSampler_Test {} {
    puts "# Reset"
    set ores [NFSampler {} 0 0]
    foreach o $ores {
	puts $o
    }

    set reslist {}
    puts "# Test1"
    foreach i {
	{0 1 10}
	{0 2 10}
	{1 1 2}
	{9 2 4}
	{8 3 3} } {

	puts " # Input: $i: [lindex $i 0] [lindex $i 1] [lindex $i 2]"
	set ores [NFSampler [lindex $i 0] [lindex $i 1] [lindex $i 2]]
	#set ores {}
	foreach o $ores {
	    puts $o
	    lappend reslist $o
	}
    }

    puts "# Flush"
    set ores [NFSampler {} 0 0]
    foreach o $ores {
	puts $o
	lappend reslist $o
    }

    set testlist {
	{0 15}
	{1 7}
	{2 0}
	{3 0}
	{4 0}
	{5 0}
	{6 0}
	{7 0}
	{8 0}
	{9 3}
	{10 3}
	{11 0}
	{12 0}
	{13 0}
	{14 0}
	{15 0}
	{16 0}
	{17 0}
	{18 0}
    }

    # from tcllib
    package require struct::list

    if {[::struct::list equal $reslist $testlist]} {
	puts "Test passed"
    } else {
	puts "Test FAILED"

	puts "## Actual"
	foreach o $reslist {
	    puts $o
	}
	puts "## Expected"
	foreach o $testlist {
	    puts $o
	}
    }
}

#NFSampler_Test
