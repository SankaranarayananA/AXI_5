// Test: back_to_back - consecutive writes then reads exercise the B/R FIFOs.
task automatic run_test_back_to_back();
  logic [AXI_ADDR_WIDTH-1:0] a;
  logic [AXI_DATA_WIDTH-1:0] d;
  logic [AXI_DATA_WIDTH-1:0] rd;

  for (int unsigned i = 0; i < 4; i++) begin
    a = 32'h0000_0400 + (i << 3);
    d = 64'h0000_1000_0000_0000 + i;
    axi_write(a, d);
    env_init_h.sb.record_write(a, d);
  end

  for (int unsigned i = 0; i < 4; i++) begin
    a = 32'h0000_0400 + (i << 3);
    d = 64'h0000_1000_0000_0000 + i;
    axi_read(a, rd);
    env_init_h.sb.check_read(a, rd);
    if (rd !== d) $error("[back_to_back] mismatch @0x%08h got=0x%016h exp=0x%016h", a, rd, d);
  end

  $display("[back_to_back] sequential writes/reads PASS");
endtask
