task automatic run_test_direct_rw();
  logic [AXI_DATA_WIDTH-1:0] rd_data;
  logic [AXI_ADDR_WIDTH-1:0] wr_addr;
  logic [AXI_DATA_WIDTH-1:0] wr_data;

  wr_addr = 32'h0000_0010;
  wr_data = 64'h0123_4567_89AB_CDEF;

  axi_write(wr_addr, wr_data);
  env_init_h.sb.record_write(wr_addr, wr_data);

  axi_read(wr_addr, rd_data);
  env_init_h.sb.check_read(wr_addr, rd_data);

  if (rd_data !== wr_data) begin
    $error("[direct_rw] AXI read data mismatch. addr=0x%08h exp=0x%016h got=0x%016h", wr_addr, wr_data, rd_data);
  end else begin
    $display("[direct_rw] PASS. addr=0x%08h data=0x%016h", wr_addr, rd_data);
  end
endtask
