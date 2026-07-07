`timescale 1ns / 1ps

`include "tb_defines.svh"
`include "uvm_pkg.sv"
`include "axi_uvm_ral_pkg.sv"
`include "axi_uvm_seq_pkg.sv"
`include "axi_uvm_env_pkg.sv"
`include "../../../axi5-master/src/axi5_intf.sv"
`include "../../../axi5-master/src/axi5_nsaid_remap.sv"
`include "../../../axi5-master/src/axi5_to_axi4.sv"

import uvm_pkg::*;
import axi_uvm_ral_pkg::*;
import axi_uvm_seq_pkg::*;
import axi_uvm_env_pkg::*;

class basic_axi_test extends uvm_test;
  axi_ral_block ral_model;
  axi_env env_h;
  axi_read_write_sequence rw_seq;

  function new(string name = "basic_axi_test");
    super.new(name);
  endfunction

  task run_phase();
    uvm_phase phase = new();
    axi_seq_item req;

    phase.raise_objection(this);
    uvm_info("TB", "Starting basic AXI UVM smoke test", 0);

    ral_model = new("ral_model");
    ral_model.build();
    ral_model.reset_model();

    env_h = new("env_h", this);
    env_h.build();

    rw_seq = new("rw_seq");
    env_h.apply_defaults_to_sequence(rw_seq);
    rw_seq.start(env_h.seqr);

    req = env_h.seqr.get();
    while (req != null) begin
      uvm_info("SEQ", $sformatf("item write=%0b addr=0x%08h data=0x%08h", req.write, req.addr, req.data), 0);
      req = env_h.seqr.get();
    end

    #100;
    uvm_info("TB", "AXI UVM smoke test completed", 0);
    phase.drop_objection(this);
  endtask
endclass

module top_tb;
  localparam int unsigned NUM_MASTERS    = `TB_NUM_MASTERS;
  localparam int unsigned NUM_SLAVES     = `TB_NUM_SLAVES;
  localparam int unsigned AXI_ADDR_WIDTH = `TB_AXI_ADDR_WIDTH;
  localparam int unsigned AXI_DATA_WIDTH = `TB_AXI_DATA_WIDTH;
  localparam int unsigned AXI_ID_WIDTH   = `TB_AXI_ID_WIDTH;
  localparam logic [1:0] AXI_RESP_OKAY   = 2'b00;

  logic clk_i;
  logic rst_ni;
  logic test_i;

  typedef bit [AXI_ADDR_WIDTH-1:0] tb_addr_t;
  typedef logic [AXI_DATA_WIDTH-1:0] tb_data_t;

  axi_env env_init_h;

  AXI_BUS #(
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
    .AXI_ID_WIDTH(AXI_ID_WIDTH),
    .AXI_USER_WIDTH(0)
  ) master_if [NUM_MASTERS-1:0] ();

  AXI_BUS #(
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
    .AXI_ID_WIDTH(AXI_ID_WIDTH),
    .AXI_USER_WIDTH(0)
  ) slave_if [NUM_SLAVES-1:0] ();

  AXI5_BUS #(
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
    .AXI_ID_WIDTH(AXI_ID_WIDTH),
    .AXI_USER_WIDTH(0)
  ) master5_if ();

  AXI5_BUS #(
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
    .AXI_ID_WIDTH(AXI_ID_WIDTH),
    .AXI_USER_WIDTH(0)
  ) master5_remap_if ();

  axi5_nsaid_remap_intf #(
    .MatchNsaid(4'h0),
    .RemapNsaid(4'h3)
  ) u_axi5_nsaid_remap (
    .slv(master5_if),
    .mst(master5_remap_if)
  );

  axi5_to_axi4_intf #(
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
    .AXI_ID_WIDTH(AXI_ID_WIDTH),
    .AXI_USER_WIDTH(0)
  ) u_axi5_to_axi4 (
    .slv(master5_remap_if),
    .mst(master_if[0])
  );

  axi_top #(
    .NUM_MASTERS    (NUM_MASTERS),
    .NUM_SLAVES     (NUM_SLAVES),
    .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
    .AXI_ID_WIDTH   (AXI_ID_WIDTH)
  ) dut (
    .clk_i       (clk_i),
    .rst_ni      (rst_ni),
    .test_i      (test_i),
    .master_ports(master_if),
    .slave_ports (slave_if)
  );

  task automatic axi_write(input logic [AXI_ADDR_WIDTH-1:0] addr,
                           input logic [AXI_DATA_WIDTH-1:0] data);
    master5_if.aw_id     <= '0;
    master5_if.aw_addr   <= addr;
    master5_if.aw_len    <= 8'd0;
    master5_if.aw_size   <= 3'd3;
    master5_if.aw_burst  <= 2'b01;
    master5_if.aw_lock   <= 1'b0;
    master5_if.aw_cache  <= 4'h0;
    master5_if.aw_prot   <= 3'h0;
    master5_if.aw_qos    <= 4'h0;
    master5_if.aw_region <= 4'h0;
    master5_if.aw_atop   <= 6'h0;
    master5_if.aw_nsaid  <= 4'h0;
    master5_if.aw_valid  <= 1'b1;

    master5_if.w_data    <= data;
    master5_if.w_strb    <= '1;
    master5_if.w_last    <= 1'b1;
    master5_if.w_valid   <= 1'b1;

    do @(posedge clk_i); while (!(master5_if.aw_valid && master5_if.aw_ready));
    master5_if.aw_valid  <= 1'b0;

    do @(posedge clk_i); while (!(master5_if.w_valid && master5_if.w_ready));
    master5_if.w_valid   <= 1'b0;

    master5_if.b_ready   <= 1'b1;
    do @(posedge clk_i); while (!master5_if.b_valid);
    if (master5_if.b_resp !== AXI_RESP_OKAY) begin
      $error("AXI write response error: resp=%0h", master5_if.b_resp);
    end
    master5_if.b_ready   <= 1'b0;
  endtask

  task automatic axi_read(input  logic [AXI_ADDR_WIDTH-1:0] addr,
                          output logic [AXI_DATA_WIDTH-1:0] data);
    master5_if.ar_id     <= '0;
    master5_if.ar_addr   <= addr;
    master5_if.ar_len    <= 8'd0;
    master5_if.ar_size   <= 3'd3;
    master5_if.ar_burst  <= 2'b01;
    master5_if.ar_lock   <= 1'b0;
    master5_if.ar_cache  <= 4'h0;
    master5_if.ar_prot   <= 3'h0;
    master5_if.ar_qos    <= 4'h0;
    master5_if.ar_region <= 4'h0;
    master5_if.ar_nsaid  <= 4'h0;
    master5_if.ar_valid  <= 1'b1;

    do @(posedge clk_i); while (!(master5_if.ar_valid && master5_if.ar_ready));
    master5_if.ar_valid  <= 1'b0;

    master5_if.r_ready   <= 1'b1;
    do @(posedge clk_i); while (!master5_if.r_valid);
    data = master5_if.r_data;
    if (master5_if.r_resp !== AXI_RESP_OKAY) begin
      $error("AXI read response error: resp=%0h", master5_if.r_resp);
    end
    master5_if.r_ready   <= 1'b0;
  endtask

  task automatic init_axi5_master_port();
    master5_if.aw_id     = '0;
    master5_if.aw_addr   = '0;
    master5_if.aw_len    = '0;
    master5_if.aw_size   = '0;
    master5_if.aw_burst  = '0;
    master5_if.aw_lock   = '0;
    master5_if.aw_cache  = '0;
    master5_if.aw_prot   = '0;
    master5_if.aw_qos    = '0;
    master5_if.aw_region = '0;
    master5_if.aw_atop   = '0;
    master5_if.aw_nsaid  = '0;
    master5_if.aw_user   = '0;
    master5_if.aw_valid  = 1'b0;

    master5_if.w_data    = '0;
    master5_if.w_strb    = '0;
    master5_if.w_last    = 1'b0;
    master5_if.w_user    = '0;
    master5_if.w_valid   = 1'b0;

    master5_if.b_ready   = 1'b0;

    master5_if.ar_id     = '0;
    master5_if.ar_addr   = '0;
    master5_if.ar_len    = '0;
    master5_if.ar_size   = '0;
    master5_if.ar_burst  = '0;
    master5_if.ar_lock   = '0;
    master5_if.ar_cache  = '0;
    master5_if.ar_prot   = '0;
    master5_if.ar_qos    = '0;
    master5_if.ar_region = '0;
    master5_if.ar_nsaid  = '0;
    master5_if.ar_user   = '0;
    master5_if.ar_valid  = 1'b0;

    master5_if.r_ready   = 1'b0;
  endtask

  task automatic init_unused_axi4_master1();
    master_if[1].aw_id    = '0;
    master_if[1].aw_addr  = '0;
    master_if[1].aw_len   = '0;
    master_if[1].aw_size  = '0;
    master_if[1].aw_burst = '0;
    master_if[1].aw_lock  = '0;
    master_if[1].aw_cache = '0;
    master_if[1].aw_prot  = '0;
    master_if[1].aw_qos   = '0;
    master_if[1].aw_region= '0;
    master_if[1].aw_atop  = '0;
    master_if[1].aw_user  = '0;
    master_if[1].aw_valid = 1'b0;

    master_if[1].w_data   = '0;
    master_if[1].w_strb   = '0;
    master_if[1].w_last   = 1'b0;
    master_if[1].w_user   = '0;
    master_if[1].w_valid  = 1'b0;

    master_if[1].b_ready  = 1'b0;

    master_if[1].ar_id    = '0;
    master_if[1].ar_addr  = '0;
    master_if[1].ar_len   = '0;
    master_if[1].ar_size  = '0;
    master_if[1].ar_burst = '0;
    master_if[1].ar_lock  = '0;
    master_if[1].ar_cache = '0;
    master_if[1].ar_prot  = '0;
    master_if[1].ar_qos   = '0;
    master_if[1].ar_region= '0;
    master_if[1].ar_user  = '0;
    master_if[1].ar_valid = 1'b0;

    master_if[1].r_ready  = 1'b0;
  endtask

  task automatic init_slave_ports_tb();
    slave_if[0].aw_ready = 1'b0;
    slave_if[0].w_ready  = 1'b0;
    slave_if[0].b_id     = '0;
    slave_if[0].b_resp   = AXI_RESP_OKAY;
    slave_if[0].b_user   = '0;
    slave_if[0].b_valid  = 1'b0;
    slave_if[0].ar_ready = 1'b0;
    slave_if[0].r_id     = '0;
    slave_if[0].r_data   = '0;
    slave_if[0].r_resp   = AXI_RESP_OKAY;
    slave_if[0].r_last   = 1'b1;
    slave_if[0].r_user   = '0;
    slave_if[0].r_valid  = 1'b0;

    slave_if[1].aw_ready = 1'b0;
    slave_if[1].w_ready  = 1'b0;
    slave_if[1].b_id     = '0;
    slave_if[1].b_resp   = AXI_RESP_OKAY;
    slave_if[1].b_user   = '0;
    slave_if[1].b_valid  = 1'b0;
    slave_if[1].ar_ready = 1'b0;
    slave_if[1].r_id     = '0;
    slave_if[1].r_data   = '0;
    slave_if[1].r_resp   = AXI_RESP_OKAY;
    slave_if[1].r_last   = 1'b1;
    slave_if[1].r_user   = '0;
    slave_if[1].r_valid  = 1'b0;
  endtask

  // Direct AXI4 write on master port 1 (used by the concurrent multi-master test).
  task automatic master1_write(input logic [AXI_ADDR_WIDTH-1:0] addr,
                               input logic [AXI_DATA_WIDTH-1:0] data);
    master_if[1].aw_id    <= '0;
    master_if[1].aw_addr  <= addr;
    master_if[1].aw_len   <= 8'd0;
    master_if[1].aw_size  <= 3'd3;
    master_if[1].aw_burst <= 2'b01;
    master_if[1].aw_lock  <= 1'b0;
    master_if[1].aw_cache <= 4'h0;
    master_if[1].aw_prot  <= 3'h0;
    master_if[1].aw_qos   <= 4'h0;
    master_if[1].aw_region<= 4'h0;
    master_if[1].aw_atop  <= 6'h0;
    master_if[1].aw_valid <= 1'b1;

    master_if[1].w_data   <= data;
    master_if[1].w_strb   <= '1;
    master_if[1].w_last   <= 1'b1;
    master_if[1].w_valid  <= 1'b1;

    do @(posedge clk_i); while (!(master_if[1].aw_valid && master_if[1].aw_ready));
    master_if[1].aw_valid <= 1'b0;

    do @(posedge clk_i); while (!(master_if[1].w_valid && master_if[1].w_ready));
    master_if[1].w_valid <= 1'b0;

    master_if[1].b_ready <= 1'b1;
    do @(posedge clk_i); while (!master_if[1].b_valid);
    if (master_if[1].b_resp !== AXI_RESP_OKAY) begin
      $error("M1 write response error: resp=%0h", master_if[1].b_resp);
    end
    master_if[1].b_ready <= 1'b0;
  endtask

  // Direct AXI4 read on master port 1 (used by the concurrent multi-master test).
  task automatic master1_read(input  logic [AXI_ADDR_WIDTH-1:0] addr,
                              output logic [AXI_DATA_WIDTH-1:0] data);
    master_if[1].ar_id    <= '0;
    master_if[1].ar_addr  <= addr;
    master_if[1].ar_len   <= 8'd0;
    master_if[1].ar_size  <= 3'd3;
    master_if[1].ar_burst <= 2'b01;
    master_if[1].ar_lock  <= 1'b0;
    master_if[1].ar_cache <= 4'h0;
    master_if[1].ar_prot  <= 3'h0;
    master_if[1].ar_qos   <= 4'h0;
    master_if[1].ar_region<= 4'h0;
    master_if[1].ar_valid <= 1'b1;

    do @(posedge clk_i); while (!(master_if[1].ar_valid && master_if[1].ar_ready));
    master_if[1].ar_valid <= 1'b0;

    master_if[1].r_ready <= 1'b1;
    do @(posedge clk_i); while (!master_if[1].r_valid);
    data = master_if[1].r_data;
    if (master_if[1].r_resp !== AXI_RESP_OKAY) begin
      $error("M1 read response error: resp=%0h", master_if[1].r_resp);
    end
    master_if[1].r_ready <= 1'b0;
  endtask

  initial begin
    clk_i = 0;
    forever begin
      #5 clk_i = ~clk_i;
    end
  end

  // Memory-mapped slave model instantiated for every downstream slave port.
  // Each slave owns an independent memory keyed by the full transaction address.
  genvar gs;
  generate
    for (gs = 0; gs < NUM_SLAVES; gs++) begin : gen_slave_mem
      tb_data_t                  s_mem [tb_addr_t];
      logic                      s_aw_seen;
      logic                      s_w_seen;
      logic [AXI_ADDR_WIDTH-1:0] s_paddr;
      logic [AXI_DATA_WIDTH-1:0] s_pdata;

      always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
          s_aw_seen <= 1'b0;
          s_w_seen  <= 1'b0;
          s_paddr   <= '0;
          s_pdata   <= '0;

          slave_if[gs].aw_ready <= 1'b1;
          slave_if[gs].w_ready  <= 1'b1;
          slave_if[gs].b_id     <= '0;
          slave_if[gs].b_resp   <= AXI_RESP_OKAY;
          slave_if[gs].b_user   <= '0;
          slave_if[gs].b_valid  <= 1'b0;

          slave_if[gs].ar_ready <= 1'b1;
          slave_if[gs].r_id     <= '0;
          slave_if[gs].r_data   <= '0;
          slave_if[gs].r_resp   <= AXI_RESP_OKAY;
          slave_if[gs].r_last   <= 1'b1;
          slave_if[gs].r_user   <= '0;
          slave_if[gs].r_valid  <= 1'b0;
        end else begin
          if (slave_if[gs].aw_valid && slave_if[gs].aw_ready) begin
            s_paddr   <= slave_if[gs].aw_addr;
            s_aw_seen <= 1'b1;
          end

          if (slave_if[gs].w_valid && slave_if[gs].w_ready) begin
            s_pdata  <= slave_if[gs].w_data;
            s_w_seen <= 1'b1;
          end

          if (s_aw_seen && s_w_seen && !slave_if[gs].b_valid) begin
            s_mem[tb_addr_t'(s_paddr)] = s_pdata;
            slave_if[gs].b_valid <= 1'b1;
            s_aw_seen <= 1'b0;
            s_w_seen  <= 1'b0;
          end

          if (slave_if[gs].b_valid && slave_if[gs].b_ready) begin
            slave_if[gs].b_valid <= 1'b0;
          end

          if (slave_if[gs].ar_valid && slave_if[gs].ar_ready && !slave_if[gs].r_valid) begin
            if (s_mem.exists(tb_addr_t'(slave_if[gs].ar_addr))) begin
              slave_if[gs].r_data <= s_mem[tb_addr_t'(slave_if[gs].ar_addr)];
            end else begin
              slave_if[gs].r_data <= '0;
            end
            slave_if[gs].r_valid <= 1'b1;
          end

          if (slave_if[gs].r_valid && slave_if[gs].r_ready) begin
            slave_if[gs].r_valid <= 1'b0;
          end
        end
      end
    end
  endgenerate

  // Test-case tasks (module-scoped: they reference master5_if, axi_write,
  // env_init_h, AXI_*_WIDTH, etc., so they must be included inside the module).
`include "tb_test_direct_rw.svh"
`include "tb_test_sequence_rw.svh"
`include "tb_test_uvm_smoke.svh"
`include "tb_test_multi_slave.svh"
`include "tb_test_back_to_back.svh"
`include "tb_test_concurrent_masters.svh"
`include "tb_test_nsaid_remap.svh"

  initial begin
    string testname;

    rst_ni = 0;
    test_i = 0;

    env_init_h = new("env_init_h", null);
    env_init_h.build();

    init_axi5_master_port();
    init_unused_axi4_master1();
    init_slave_ports_tb();

    repeat (3) @(posedge clk_i);
    rst_ni = 1;

    repeat (5) @(posedge clk_i);

    if (!$value$plusargs("TESTNAME=%s", testname)) begin
      testname = "all";
    end

    if (testname == "all") begin
      run_test_direct_rw();
      run_test_multi_slave();
      run_test_back_to_back();
      run_test_sequence_rw();
      run_test_concurrent_masters();
      run_test_nsaid_remap();
      run_test_uvm_smoke();
    end else if (testname == "direct_rw") begin
      run_test_direct_rw();
    end else if (testname == "multi_slave") begin
      run_test_multi_slave();
    end else if (testname == "back_to_back") begin
      run_test_back_to_back();
    end else if (testname == "sequence_rw") begin
      run_test_sequence_rw();
    end else if (testname == "concurrent_masters") begin
      run_test_concurrent_masters();
    end else if (testname == "nsaid_remap") begin
      run_test_nsaid_remap();
    end else if (testname == "uvm_smoke") begin
      run_test_uvm_smoke();
    end else begin
      $error("Unknown TESTNAME='%s'. Valid: all, direct_rw, multi_slave, back_to_back, sequence_rw, concurrent_masters, nsaid_remap, uvm_smoke", testname);
    end

    repeat (10) @(posedge clk_i);
    env_init_h.sb.report();
    repeat (20) @(posedge clk_i);
    $finish;
  end
endmodule

