package uvm_pkg;
  class uvm_component;
    string name;

    function new(string name = "uvm_component");
      this.name = name;
    endfunction

    virtual task run_phase();
    endtask
  endclass

  class uvm_phase;
    task raise_objection(uvm_component comp);
      // No-op placeholder for a simple Vivado smoke test.
    endtask

    task drop_objection(uvm_component comp);
      // No-op placeholder for a simple Vivado smoke test.
    endtask
  endclass

  class uvm_test extends uvm_component;
    function new(string name = "uvm_test", uvm_component parent = null);
      super.new(name);
    endfunction

    virtual task run_phase();
    endtask
  endclass

  function automatic void uvm_info(string id, string msg, int verbosity = 0);
    $display("[UVM][%s] %s", id, msg);
  endfunction

  function automatic void run_test(string test_name = "");
    $display("[UVM] Running test %s", test_name);
  endfunction
endpackage
