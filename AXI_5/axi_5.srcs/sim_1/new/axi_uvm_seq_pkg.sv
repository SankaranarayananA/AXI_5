`timescale 1ns / 1ps

// AXI sequence item, sequencer, and read/write sequence.
package axi_uvm_seq_pkg;
  import uvm_pkg::*;

  class axi_seq_item extends uvm_sequence_item;
    rand bit        write;
    rand bit [31:0] addr;
    rand bit [31:0] data;

    function new(string name = "axi_seq_item");
      super.new(name);
    endfunction
  endclass

  class axi_sequencer extends uvm_sequencer #(axi_seq_item);
    function new(string name = "axi_sequencer", uvm_component parent = null);
      super.new(name, parent);
    endfunction
  endclass

  class axi_read_write_sequence extends uvm_sequence #(axi_seq_item);
    rand bit [31:0] addr;
    rand bit [31:0] data;

    function new(string name = "axi_read_write_sequence");
      super.new(name);
    endfunction

    virtual task body();
      axi_seq_item wr_req;
      axi_seq_item rd_req;

      wr_req = new("wr_req");
      wr_req.write = 1'b1;
      wr_req.addr = addr;
      wr_req.data = data;
      send_item(wr_req);

      rd_req = new("rd_req");
      rd_req.write = 1'b0;
      rd_req.addr = addr;
      rd_req.data = '0;
      send_item(rd_req);
    endtask
  endclass

endpackage
