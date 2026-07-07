task automatic run_test_sequence_rw();
  axi_read_write_sequence seq_traffic;
  axi_seq_item seq_req;
  logic [AXI_DATA_WIDTH-1:0] rd_data;
  logic [AXI_DATA_WIDTH-1:0] seq_wr_data;

  seq_traffic = new("seq_traffic");
  env_init_h.apply_defaults_to_sequence(seq_traffic);
  seq_traffic.start(env_init_h.seqr);

  seq_req = env_init_h.seqr.get();
  while (seq_req != null) begin
    if (seq_req.write) begin
      seq_wr_data = '0;
      seq_wr_data[31:0] = seq_req.data;
      axi_write(seq_req.addr, seq_wr_data);
      env_init_h.sb.record_write(seq_req.addr, seq_wr_data);
    end else begin
      axi_read(seq_req.addr, rd_data);
      seq_req.data = rd_data[31:0];
      env_init_h.sb.check_read(seq_req.addr, rd_data);
    end
    seq_req = env_init_h.seqr.get();
  end

  $display("[sequence_rw] Completed sequencer-driven AXI transactions");
endtask
