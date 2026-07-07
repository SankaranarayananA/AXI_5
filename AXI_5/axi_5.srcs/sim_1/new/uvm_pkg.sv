package uvm_pkg;
  class uvm_object;
    string name;

    function new(string name = "uvm_object");
      this.name = name;
    endfunction
  endclass

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

  class uvm_sequence_item extends uvm_object;
    function new(string name = "uvm_sequence_item");
      super.new(name);
    endfunction
  endclass

  class uvm_sequencer #(type REQ = uvm_sequence_item) extends uvm_component;
    REQ req_q[$];

    function new(string name = "uvm_sequencer", uvm_component parent = null);
      super.new(name);
    endfunction

    virtual function void put(REQ req);
      req_q.push_back(req);
    endfunction

    virtual function REQ get();
      if (req_q.size() == 0) begin
        return null;
      end
      return req_q.pop_front();
    endfunction
  endclass

  class uvm_sequence #(type REQ = uvm_sequence_item) extends uvm_object;
    uvm_sequencer #(REQ) m_sequencer;

    function new(string name = "uvm_sequence");
      super.new(name);
    endfunction

    virtual task body();
    endtask

    virtual task start(uvm_sequencer #(REQ) seqr);
      m_sequencer = seqr;
      body();
    endtask

    protected task send_item(REQ req);
      if (m_sequencer != null) begin
        m_sequencer.put(req);
      end
    endtask
  endclass

  class uvm_reg extends uvm_object;
    int unsigned n_bits;
    logic [63:0] mirrored_value;

    function new(string name = "uvm_reg", int unsigned n_bits = 32);
      super.new(name);
      this.n_bits = n_bits;
      this.mirrored_value = '0;
    endfunction

    virtual function void configure();
    endfunction

    virtual function void write(logic [63:0] value);
      mirrored_value = value;
    endfunction

    virtual function logic [63:0] read();
      return mirrored_value;
    endfunction
  endclass

  class uvm_reg_block extends uvm_object;
    function new(string name = "uvm_reg_block");
      super.new(name);
    endfunction

    virtual function void build();
    endfunction
  endclass

  function automatic void uvm_info(string id, string msg, int verbosity = 0);
    $display("[UVM][%s] %s", id, msg);
  endfunction

  function automatic void run_test(string test_name = "");
    $display("[UVM] Running test %s", test_name);
  endfunction
endpackage
