`timescale 1ns / 1ps

`include "uvm_pkg.sv"

import uvm_pkg::*;

class basic_axi_test extends uvm_test;
  function new(string name = "basic_axi_test");
    super.new(name);
  endfunction

  task run_phase();
    uvm_phase phase = new();
    phase.raise_objection(this);
    uvm_info("TB", "Starting basic AXI UVM smoke test", 0);
    #100;
    uvm_info("TB", "AXI UVM smoke test completed", 0);
    phase.drop_objection(this);
  endtask
endclass

module top_tb;
  localparam int unsigned NUM_MASTERS    = 2;
  localparam int unsigned NUM_SLAVES     = 2;
  localparam int unsigned AXI_ADDR_WIDTH = 32;
  localparam int unsigned AXI_DATA_WIDTH = 64;
  localparam int unsigned AXI_ID_WIDTH   = 4;

  logic clk_i;
  logic rst_ni;
  logic test_i;

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

  initial begin
    clk_i = 0;
    forever begin
      #5 clk_i = ~clk_i;
    end
  end

  initial begin
    rst_ni = 0;
    test_i = 0;
    repeat (3) @(posedge clk_i);
    rst_ni = 1;
    repeat (10) @(posedge clk_i);
    run_test("basic_axi_test");
  end
endmodule

