`timescale 1ns / 1ps

package axi_uvm_ral_pkg;
  import uvm_pkg::*;

  class axi_ctrl_reg extends uvm_reg;
    function new(string name = "axi_ctrl_reg");
      super.new(name, 32);
    endfunction
  endclass

  class axi_status_reg extends uvm_reg;
    function new(string name = "axi_status_reg");
      super.new(name, 32);
    endfunction
  endclass

  class axi_ral_block extends uvm_reg_block;
    axi_ctrl_reg   ctrl;
    axi_status_reg status;

    function new(string name = "axi_ral_block");
      super.new(name);
    endfunction

    virtual function void build();
      ctrl = new("ctrl");
      ctrl.configure();

      status = new("status");
      status.configure();
    endfunction

    function void reset_model();
      ctrl.write(64'h0);
      status.write(64'h0);
    endfunction
  endclass

endpackage
