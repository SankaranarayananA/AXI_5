`timescale 1ns / 1ps

package axi_uvm_env_pkg;
  import uvm_pkg::*;
  import axi_uvm_seq_pkg::*;

  class axi_scoreboard extends uvm_component;
    longint unsigned expected_mem[bit [31:0]];
    int unsigned pass_count;
    int unsigned error_count;

    function new(string name = "axi_scoreboard", uvm_component parent = null);
      super.new(name);
      pass_count = 0;
      error_count = 0;
    endfunction

    function void record_write(bit [31:0] addr, longint unsigned data);
      expected_mem[addr] = data;
      uvm_info("SB", $sformatf("WRITE addr=0x%08h data=0x%016h", addr, data), 0);
    endfunction

    function void check_read(bit [31:0] addr, longint unsigned data);
      if (!expected_mem.exists(addr)) begin
        error_count++;
        $error("[SB] READ on unknown address: addr=0x%08h data=0x%016h", addr, data);
        return;
      end

      if (expected_mem[addr] === data) begin
        pass_count++;
        uvm_info("SB", $sformatf("READ PASS addr=0x%08h data=0x%016h", addr, data), 0);
      end else begin
        error_count++;
        $error("[SB] READ MISMATCH addr=0x%08h exp=0x%016h got=0x%016h", addr, expected_mem[addr], data);
      end
    endfunction

    function void report();
      uvm_info("SB", $sformatf("Scoreboard summary: pass=%0d error=%0d", pass_count, error_count), 0);
      if (error_count > 0) begin
        $error("[SB] Scoreboard detected %0d error(s)", error_count);
      end
    endfunction
  endclass

  class axi_env_cfg extends uvm_object;
    bit [31:0] default_addr;
    bit [31:0] default_data;

    function new(string name = "axi_env_cfg");
      super.new(name);
      default_addr = 32'h0000_0010;
      default_data = 32'hA5A5_5A5A;
    endfunction
  endclass

  class axi_env extends uvm_component;
    axi_env_cfg cfg;
    axi_sequencer seqr;
    axi_scoreboard sb;

    function new(string name = "axi_env", uvm_component parent = null);
      super.new(name);
    endfunction

    function void build();
      cfg = new("cfg");
      seqr = new("seqr", this);
      sb = new("sb", this);
    endfunction

    function void apply_defaults_to_sequence(ref axi_read_write_sequence seq);
      seq.addr = cfg.default_addr;
      seq.data = cfg.default_data;
    endfunction
  endclass

endpackage
