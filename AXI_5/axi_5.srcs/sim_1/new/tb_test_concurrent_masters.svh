// Test: concurrent_masters - parallel masters with origin-tracked B/R routing.
task automatic run_test_concurrent_masters();
  logic [AXI_ADDR_WIDTH-1:0] a0;
  logic [AXI_ADDR_WIDTH-1:0] a1;
  logic [AXI_DATA_WIDTH-1:0] d0;
  logic [AXI_DATA_WIDTH-1:0] d1;
  logic [AXI_DATA_WIDTH-1:0] rd0;
  logic [AXI_DATA_WIDTH-1:0] rd1;

  a0 = 32'h0000_0500; // slave 0
  a1 = 32'h0000_2500; // slave 1
  d0 = 64'h1111_2222_3333_4444;
  d1 = 64'h5555_6666_7777_8888;

  // Both masters write concurrently to different slaves.
  fork
    axi_write(a0, d0);
    master1_write(a1, d1);
  join
  env_init_h.sb.record_write(a0, d0);
  env_init_h.sb.record_write(a1, d1);

  // Both masters read back concurrently; responses must route to their origin.
  fork
    axi_read(a0, rd0);
    master1_read(a1, rd1);
  join
  env_init_h.sb.check_read(a0, rd0);
  env_init_h.sb.check_read(a1, rd1);

  if (rd0 !== d0) $error("[concurrent] master0/slave0 mismatch got=0x%016h exp=0x%016h", rd0, d0);
  if (rd1 !== d1) $error("[concurrent] master1/slave1 mismatch got=0x%016h exp=0x%016h", rd1, d1);

  $display("[concurrent_masters] parallel multi-master routing PASS");
endtask
