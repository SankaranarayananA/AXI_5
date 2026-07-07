// AXI5 feature test: verifies the axi5_nsaid_remap component. The instance in
// top_tb is configured with MatchNsaid=0 -> RemapNsaid=3, so a matching NSAID
// must be rewritten while any other value passes through unchanged, on both the
// AW and AR channels. The remap is combinational, so no handshake is required.
task automatic run_test_nsaid_remap();
  // Matching NSAID (0) is remapped to 3 on AW.
  master5_if.aw_nsaid = 4'h0;
  #1;
  if (master5_remap_if.aw_nsaid !== 4'h3)
    $error("[nsaid] AW remap failed: exp=0x3 got=0x%0h", master5_remap_if.aw_nsaid);
  else
    $display("[nsaid] AW match->remap PASS (0 -> 3)");

  // Non-matching NSAID passes through unchanged on AW.
  master5_if.aw_nsaid = 4'h7;
  #1;
  if (master5_remap_if.aw_nsaid !== 4'h7)
    $error("[nsaid] AW passthrough failed: exp=0x7 got=0x%0h", master5_remap_if.aw_nsaid);
  else
    $display("[nsaid] AW passthrough PASS (7 -> 7)");

  // Matching NSAID (0) is remapped to 3 on AR.
  master5_if.ar_nsaid = 4'h0;
  #1;
  if (master5_remap_if.ar_nsaid !== 4'h3)
    $error("[nsaid] AR remap failed: exp=0x3 got=0x%0h", master5_remap_if.ar_nsaid);
  else
    $display("[nsaid] AR match->remap PASS (0 -> 3)");

  // Restore defaults.
  master5_if.aw_nsaid = 4'h0;
  master5_if.ar_nsaid = 4'h0;

  $display("[nsaid_remap] AXI5 NSAID remap checks complete");
endtask
