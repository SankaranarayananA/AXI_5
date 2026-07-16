# vivado_run_test.tcl
# Usage: vivado <project.xpr> -mode gui -source vivado_run_test.tcl -tclargs <TESTNAME>
#
# Opens the project, sets the TESTNAME plusarg, launches behavioral simulation,
# and runs to $finish. The Vivado GUI stays open so waveforms can be inspected.

set testname [lindex $argv 0]

if {$testname eq ""} {
    puts "ERROR: No TESTNAME supplied via -tclargs. Valid names:"
    puts "  direct_rw  multi_slave  back_to_back  sequence_rw"
    puts "  concurrent_masters  nsaid_remap  uvm_smoke  all"
    return
}

puts "INFO: \[vivado_run_test\] TESTNAME = $testname"

# Set the plusarg on the sim_1 fileset
set_property -name {xsim.simulate.xsim.more_options} \
             -value "-testplusarg TESTNAME=$testname" \
             -objects [get_filesets sim_1]

# Launch behavioral simulation (compiles + elaborates if stale, then opens GUI)
launch_simulation

# Run until $finish
run all

puts "INFO: \[vivado_run_test\] Simulation '$testname' complete. Window kept open."
