// Test: multi_slave - address decode/routing across both slave windows.
task automatic run_test_multi_slave();
  logic [AXI_ADDR_WIDTH-1:0] a0;
  logic [AXI_ADDR_WIDTH-1:0] a1;
  logic [AXI_DATA_WIDTH-1:0] d0;
  logic [AXI_DATA_WIDTH-1:0] d1;
  logic [AXI_DATA_WIDTH-1:0] rd;

  a0 = 32'h0000_0100; // slave 0 range (0x0000..0x1FFF)
  a1 = 32'h0000_2100; // slave 1 range (0x2000..0x3FFF)
  d0 = 64'hDEAD_BEEF_0000_0001;
  d1 = 64'hCAFE_F00D_0000_0002;

  axi_write(a0, d0);
  env_init_h.sb.record_write(a0, d0);
  axi_write(a1, d1);
  env_init_h.sb.record_write(a1, d1);

  axi_read(a0, rd);
  env_init_h.sb.check_read(a0, rd);
  if (rd !== d0) $error("[multi_slave] slave0 mismatch got=0x%016h exp=0x%016h", rd, d0);

  axi_read(a1, rd);
  env_init_h.sb.check_read(a1, rd);
  if (rd !== d1) $error("[multi_slave] slave1 mismatch got=0x%016h exp=0x%016h", rd, d1);

  $display("[multi_slave] address decode/routing PASS");
endtask
