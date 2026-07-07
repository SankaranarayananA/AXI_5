task automatic run_test_uvm_smoke();
  run_test("basic_axi_test");
  $display("[uvm_smoke] Completed UVM smoke test");
endtask
