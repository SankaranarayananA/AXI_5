# vivado_test_runner.tcl
#
# SOURCE ONCE from the Vivado Tcl console:
#   source {C:/Users/sankaran/Documents/lclPrj/AXI_5/AXI_5/vivado_test_runner.tcl}
#
# Then:
#   run_test direct_rw          run a single test
#   run_all_tests               run every test in sequence
#
# For each test this runner:
#   1. launches a fresh simulation with +TESTNAME=<name>
#   2. REMOVES every signal Vivado auto-added (incl. localparams such as
#      NUM_MASTERS, NUM_SLAVES, AXI_ADDR_WIDTH, AXI_DATA_WIDTH,
#      AXI_ID_WIDTH, AXI_RESP_OKAY)
#   3. adds ONLY the signals relevant to that test, grouped by channel
#   4. runs to $finish, saves a PNG to waveform_snapshots/, and a valid
#      Vivado .wcfg to wcfg/
#   5. keeps the finished waveform open as a static tab
# ---------------------------------------------------------------------------

set _valid_tests {direct_rw multi_slave back_to_back sequence_rw concurrent_masters nsaid_remap uvm_smoke}

# Paths derived from the open project.
set _proj_dir [get_property DIRECTORY [current_project]]
set _xsim_dir [file join $_proj_dir axi_5.sim sim_1 behav xsim]
set _snap_dir [file join $_proj_dir waveform_snapshots]
set _wcfg_dir [file join $_proj_dir wcfg]

file mkdir $_snap_dir
file mkdir $_wcfg_dir
puts "Snapshots -> $_snap_dir"
puts "WCFG      -> $_wcfg_dir"

set _prev_test ""

# ===========================================================================
# Per-test signal specification.
# Each entry is a flat list of alternating { "Group name" {sig sig ...} }.
# Paths with array indices (slave_if[0]) are fine inside braces.
# ===========================================================================
array set _wave_spec {}

set _clkrst {/top_tb/clk_i /top_tb/rst_ni}

set _wave_spec(direct_rw) [list \
  "Clock / Reset" $_clkrst \
  "AXI5 Master - Write (AW/W/B)" {
     /top_tb/master5_if/aw_valid /top_tb/master5_if/aw_ready /top_tb/master5_if/aw_addr
     /top_tb/master5_if/w_valid  /top_tb/master5_if/w_ready  /top_tb/master5_if/w_data
     /top_tb/master5_if/w_strb   /top_tb/master5_if/b_valid  /top_tb/master5_if/b_ready
     /top_tb/master5_if/b_resp } \
  "AXI5 Master - Read (AR/R)" {
     /top_tb/master5_if/ar_valid /top_tb/master5_if/ar_ready /top_tb/master5_if/ar_addr
     /top_tb/master5_if/r_valid  /top_tb/master5_if/r_ready  /top_tb/master5_if/r_data
     /top_tb/master5_if/r_resp } \
  "Slave\[0\] - Write" {
     /top_tb/slave_if[0]/aw_valid /top_tb/slave_if[0]/aw_ready /top_tb/slave_if[0]/aw_addr
     /top_tb/slave_if[0]/w_valid  /top_tb/slave_if[0]/w_data   /top_tb/slave_if[0]/b_valid
     /top_tb/slave_if[0]/b_resp } \
  "Slave\[0\] - Read" {
     /top_tb/slave_if[0]/ar_valid /top_tb/slave_if[0]/ar_addr /top_tb/slave_if[0]/r_valid
     /top_tb/slave_if[0]/r_data   /top_tb/slave_if[0]/r_resp } \
]

set _wave_spec(multi_slave) [list \
  "Clock / Reset" $_clkrst \
  "AXI5 Master - Address" {
     /top_tb/master5_if/aw_valid /top_tb/master5_if/aw_addr
     /top_tb/master5_if/ar_valid /top_tb/master5_if/ar_addr } \
  "Slave\[0\] (0x0000-0x1FFF)" {
     /top_tb/slave_if[0]/aw_valid /top_tb/slave_if[0]/aw_addr /top_tb/slave_if[0]/w_data
     /top_tb/slave_if[0]/b_valid  /top_tb/slave_if[0]/ar_valid /top_tb/slave_if[0]/ar_addr
     /top_tb/slave_if[0]/r_data } \
  "Slave\[1\] (0x2000-0x3FFF)" {
     /top_tb/slave_if[1]/aw_valid /top_tb/slave_if[1]/aw_addr /top_tb/slave_if[1]/w_data
     /top_tb/slave_if[1]/b_valid  /top_tb/slave_if[1]/ar_valid /top_tb/slave_if[1]/ar_addr
     /top_tb/slave_if[1]/r_data } \
]

set _wave_spec(back_to_back) [list \
  "Clock / Reset" $_clkrst \
  "Write Burst - AW" {
     /top_tb/master5_if/aw_valid /top_tb/master5_if/aw_ready /top_tb/master5_if/aw_addr } \
  "Write Burst - W" {
     /top_tb/master5_if/w_valid /top_tb/master5_if/w_ready /top_tb/master5_if/w_data
     /top_tb/master5_if/w_strb } \
  "Write Burst - B (FIFO)" {
     /top_tb/master5_if/b_valid /top_tb/master5_if/b_ready /top_tb/master5_if/b_resp } \
  "Read Burst - AR" {
     /top_tb/master5_if/ar_valid /top_tb/master5_if/ar_ready /top_tb/master5_if/ar_addr } \
  "Read Burst - R (FIFO)" {
     /top_tb/master5_if/r_valid /top_tb/master5_if/r_ready /top_tb/master5_if/r_data
     /top_tb/master5_if/r_resp } \
]

set _wave_spec(sequence_rw) [list \
  "Clock / Reset" $_clkrst \
  "AXI5 Master - AW/W/B" {
     /top_tb/master5_if/aw_valid /top_tb/master5_if/aw_ready /top_tb/master5_if/aw_addr
     /top_tb/master5_if/w_valid  /top_tb/master5_if/w_data   /top_tb/master5_if/b_valid
     /top_tb/master5_if/b_resp } \
  "AXI5 Master - AR/R" {
     /top_tb/master5_if/ar_valid /top_tb/master5_if/ar_ready /top_tb/master5_if/ar_addr
     /top_tb/master5_if/r_valid  /top_tb/master5_if/r_data   /top_tb/master5_if/r_resp } \
  "Slave\[0\]" {
     /top_tb/slave_if[0]/aw_valid /top_tb/slave_if[0]/aw_addr /top_tb/slave_if[0]/w_data
     /top_tb/slave_if[0]/r_data } \
  "Slave\[1\]" {
     /top_tb/slave_if[1]/aw_valid /top_tb/slave_if[1]/aw_addr /top_tb/slave_if[1]/w_data
     /top_tb/slave_if[1]/r_data } \
]

set _wave_spec(concurrent_masters) [list \
  "Clock / Reset" $_clkrst \
  "Master0 - AW/W/B (via AXI5)" {
     /top_tb/master5_if/aw_valid /top_tb/master5_if/aw_addr /top_tb/master5_if/w_data
     /top_tb/master5_if/b_valid  /top_tb/master5_if/b_resp } \
  "Master0 - AR/R (via AXI5)" {
     /top_tb/master5_if/ar_valid /top_tb/master5_if/ar_addr /top_tb/master5_if/r_data
     /top_tb/master5_if/r_resp } \
  "Master1 - AW/W/B (direct AXI4)" {
     /top_tb/master_if[1]/aw_valid /top_tb/master_if[1]/aw_addr /top_tb/master_if[1]/w_data
     /top_tb/master_if[1]/b_valid  /top_tb/master_if[1]/b_resp } \
  "Master1 - AR/R (direct AXI4)" {
     /top_tb/master_if[1]/ar_valid /top_tb/master_if[1]/ar_addr /top_tb/master_if[1]/r_data
     /top_tb/master_if[1]/r_resp } \
  "Slave\[0\] / Slave\[1\] addr" {
     /top_tb/slave_if[0]/aw_valid /top_tb/slave_if[0]/aw_addr
     /top_tb/slave_if[1]/aw_valid /top_tb/slave_if[1]/aw_addr } \
]

set _wave_spec(nsaid_remap) [list \
  "Clock / Reset" $_clkrst \
  "AW NSAID - IN vs REMAP" {
     /top_tb/master5_if/aw_valid       /top_tb/master5_if/aw_nsaid
     /top_tb/master5_if/aw_addr        /top_tb/master5_remap_if/aw_nsaid
     /top_tb/master5_remap_if/aw_addr  /top_tb/master5_remap_if/aw_valid } \
  "AR NSAID - IN vs REMAP" {
     /top_tb/master5_if/ar_valid       /top_tb/master5_if/ar_nsaid
     /top_tb/master5_if/ar_addr        /top_tb/master5_remap_if/ar_nsaid
     /top_tb/master5_remap_if/ar_addr  /top_tb/master5_remap_if/ar_valid } \
]

set _wave_spec(uvm_smoke) [list \
  "Clock / Reset" $_clkrst \
  "AXI5 Master - Write" {
     /top_tb/master5_if/aw_valid /top_tb/master5_if/aw_addr /top_tb/master5_if/w_valid
     /top_tb/master5_if/w_data   /top_tb/master5_if/b_valid /top_tb/master5_if/b_resp } \
  "AXI5 Master - Read" {
     /top_tb/master5_if/ar_valid /top_tb/master5_if/ar_addr /top_tb/master5_if/r_valid
     /top_tb/master5_if/r_data   /top_tb/master5_if/r_resp } \
  "Slave\[0\]" {
     /top_tb/slave_if[0]/aw_valid /top_tb/slave_if[0]/aw_addr /top_tb/slave_if[0]/w_data
     /top_tb/slave_if[0]/r_data } \
]

# ===========================================================================
# _setup_waves <testname>
#   Removes ALL currently displayed waves (this is what strips the localparams
#   that top_tb.tcl's 'add_wave /' inserted), then adds only the relevant
#   signals for this test, grouped by channel. Because 'add_wave /' already
#   logged every signal from t=0, re-adding retains full waveform history.
# ===========================================================================
proc _setup_waves {testname} {
    global _wave_spec

    # 1. Clear every wave object currently shown.
    set existing {}
    catch { set existing [get_waves -quiet *] }
    if {[llength $existing] > 0} {
        catch { remove_wave $existing }
    }

    # 2. If no spec, leave empty (better than showing params).
    if {![info exists _wave_spec($testname)]} {
        puts "  (no wave spec for '$testname')"
        return
    }

    # 3. Add relevant signals grouped by channel.
    set added 0
    foreach {grp sigs} $_wave_spec($testname) {
        set gh ""
        catch { set gh [add_wave_group $grp] }
        foreach s $sigs {
            set s [string trim $s]
            if {$s eq ""} continue
            if {$gh ne ""} {
                if {![catch { add_wave -into $gh $s }]} { incr added }
            } else {
                if {![catch { add_wave $s }]} { incr added }
            }
        }
    }
    puts "  Added $added relevant signals (localparams excluded)."
}

# ===========================================================================
# _save_wave_image <testname>  — zoom to full run and export a PNG.
# ===========================================================================
proc _save_wave_image {testname} {
    global _snap_dir
    set img_file [file join $_snap_dir "${testname}_wave.png"]

    set wc [current_wave_config]
    if {$wc eq ""} {
        puts "  WARNING: no wave config — skipping PNG for $testname"
        return
    }

    # Make sure the destination is writable (this workspace sits under a
    # OneDrive-synced tree that intermittently sets the ReadOnly attribute).
    catch { file attributes $_snap_dir -readonly 0 }
    if {[file exists $img_file]} {
        catch { file attributes $img_file -readonly 0 }
        catch { file delete -force $img_file }
    }

    # Fit the entire run into the wave window before capturing.
    catch { zoom_fit }

    # write_wave_image infers the format from the .png extension.
    # Give it an explicit size so the export is full-resolution, not clipped
    # to whatever the scripted GUI window happens to be.
    set rc [catch { write_wave_image -width 1920 -height 1080 $img_file } err]
    if {$rc != 0} {
        # Fall back to the default-size form if -width/-height is unsupported.
        set rc [catch { write_wave_image $img_file } err]
    }

    if {$rc != 0} {
        puts "  ERROR write_wave_image: $err"
    } elseif {[file exists $img_file]} {
        puts "  PNG  : $img_file ([file size $img_file] bytes)"
    } else {
        puts "  WARNING: write_wave_image reported OK but file missing: $img_file"
    }
}

# ===========================================================================
# _save_wcfg <testname>  — write a VALID Vivado wave config for reuse.
# ===========================================================================
proc _save_wcfg {testname} {
    global _wcfg_dir
    set wcfg_file [file join $_wcfg_dir "top_tb_${testname}.wcfg"]
    if {[catch { save_wave_config $wcfg_file } err]} {
        puts "  (save_wave_config: $err)"
    } else {
        puts "  WCFG : $wcfg_file"
    }
}

# ===========================================================================
# _preserve_wdb <testname>  — finalise .wdb and reopen as a static tab.
# ===========================================================================
proc _preserve_wdb {testname} {
    global _xsim_dir
    set wdb_live [file join $_xsim_dir top_tb_behav.wdb]
    set wdb_save [file join $_xsim_dir "top_tb_${testname}.wdb"]
    catch { close_sim }
    if {[file exists $wdb_live]} {
        file copy -force $wdb_live $wdb_save
        catch { open_wave_database $wdb_save }
    }
}

# ===========================================================================
# run_test <name>
# ===========================================================================
proc run_test {testname} {
    global _valid_tests _prev_test

    if {$testname ni $_valid_tests} {
        puts "ERROR: Unknown test '$testname'. Valid: $_valid_tests"
        return
    }

    puts "\n=========================================="
    puts " run_test: $testname"
    puts "=========================================="

    # Preserve the previously finished test's waveform as a static tab.
    if {$_prev_test ne ""} {
        _preserve_wdb $_prev_test
    } else {
        catch { close_sim }
    }

    # Select the test via plusarg.
    set_property -name {xsim.simulate.xsim.more_options} \
                 -value "-testplusarg TESTNAME=$testname" \
                 -objects [get_filesets sim_1]

    # Launch (top_tb.tcl does add_wave / + run 1000ns; that logs all sigs @ t=0).
    puts "  launch_simulation..."
    launch_simulation

    # Replace the auto-added signal set with only the relevant ones.
    _setup_waves $testname

    # Restart so the waveform is re-logged from t=0 with ONLY the relevant
    # signals in view (guarantees clean full history, no leftover params).
    catch { restart }

    # Run to $finish.
    puts "  run all..."
    run all

    # Capture outputs while the simulation is still live.
    _save_wave_image $testname
    _save_wcfg       $testname

    set _prev_test $testname
    puts " '$testname' complete."
    puts "=========================================="
}

# ===========================================================================
# run_all_tests — run every test; each gets its own waveform tab + PNG + wcfg.
# ===========================================================================
proc run_all_tests {} {
    global _valid_tests _prev_test _snap_dir
    foreach t $_valid_tests {
        run_test $t
    }
    if {$_prev_test ne ""} {
        _preserve_wdb $_prev_test
        set _prev_test ""
    }
    puts "\n=========================================="
    puts " All tests complete. PNGs in: $_snap_dir"
    puts "=========================================="
}

puts "Test runner loaded."
puts "  run_test <name>   — single test (relevant signals only)"
puts "  run_all_tests     — all tests"
puts "  Valid names: $_valid_tests"
