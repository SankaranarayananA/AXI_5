`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 06.07.2026 13:12:07
// Design Name:
// Module Name: axi_top
// Project Name:
// Target Devices:
// Tool Versions:
// Description: First-pass multi-master AXI interconnect wrapper. The top-level
//              structure is in place and the implementation uses a lightweight
//              self-contained AXI interface plus a placeholder crossbar stub so
//              the file is parseable immediately.
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

package axi_pkg;
    typedef logic [7:0] len_t;
    typedef logic [2:0] size_t;
    typedef logic [1:0] burst_t;
    typedef logic [3:0] cache_t;
    typedef logic [2:0] prot_t;
    typedef logic [3:0] qos_t;
    typedef logic [3:0] region_t;
    typedef logic [5:0] atop_t;
    typedef logic [1:0] resp_t;

    localparam bit [9:0] CUT_ALL_AX = 10'b111_11_111_11;

    typedef struct packed {
        int unsigned NoSlvPorts;
        int unsigned NoMstPorts;
        int unsigned MaxMstTrans;
        int unsigned MaxSlvTrans;
        bit         FallThrough;
        bit [9:0]   LatencyMode;
        int unsigned PipelineStages;
        int unsigned AxiIdWidthSlvPorts;
        int unsigned AxiIdUsedSlvPorts;
        bit         UniqueIds;
        int unsigned AxiAddrWidth;
        int unsigned AxiDataWidth;
        int unsigned NoAddrRules;
    } xbar_cfg_t;

    typedef struct packed {
        int unsigned idx;
        logic [31:0] start_addr;
        logic [31:0] end_addr;
    } xbar_rule_32_t;
endpackage

interface AXI_BUS #(
    parameter int unsigned AXI_ADDR_WIDTH = 32,
    parameter int unsigned AXI_DATA_WIDTH = 64,
    parameter int unsigned AXI_ID_WIDTH   = 4,
    parameter int unsigned AXI_USER_WIDTH = 0
);
    localparam int unsigned AXI_STRB_WIDTH = AXI_DATA_WIDTH / 8;

    typedef logic [AXI_ID_WIDTH-1:0]   id_t;
    typedef logic [AXI_ADDR_WIDTH-1:0] addr_t;
    typedef logic [AXI_DATA_WIDTH-1:0] data_t;
    typedef logic [AXI_STRB_WIDTH-1:0] strb_t;
    typedef logic [AXI_USER_WIDTH-1:0] user_t;

    id_t              aw_id;
    addr_t            aw_addr;
    axi_pkg::len_t    aw_len;
    axi_pkg::size_t   aw_size;
    axi_pkg::burst_t  aw_burst;
    logic             aw_lock;
    axi_pkg::cache_t  aw_cache;
    axi_pkg::prot_t   aw_prot;
    axi_pkg::qos_t    aw_qos;
    axi_pkg::region_t aw_region;
    axi_pkg::atop_t   aw_atop;
    user_t            aw_user;
    logic             aw_valid;
    logic             aw_ready;

    data_t            w_data;
    strb_t            w_strb;
    logic             w_last;
    user_t            w_user;
    logic             w_valid;
    logic             w_ready;

    id_t              b_id;
    axi_pkg::resp_t   b_resp;
    user_t            b_user;
    logic             b_valid;
    logic             b_ready;

    id_t              ar_id;
    addr_t            ar_addr;
    axi_pkg::len_t    ar_len;
    axi_pkg::size_t   ar_size;
    axi_pkg::burst_t  ar_burst;
    logic             ar_lock;
    axi_pkg::cache_t  ar_cache;
    axi_pkg::prot_t   ar_prot;
    axi_pkg::qos_t    ar_qos;
    axi_pkg::region_t ar_region;
    user_t            ar_user;
    logic             ar_valid;
    logic             ar_ready;

    id_t              r_id;
    data_t            r_data;
    axi_pkg::resp_t   r_resp;
    logic             r_last;
    user_t            r_user;
    logic             r_valid;
    logic             r_ready;

    modport Master (
        output aw_id, aw_addr, aw_len, aw_size, aw_burst, aw_lock, aw_cache, aw_prot, aw_qos, aw_region, aw_atop, aw_user, aw_valid,
        input  aw_ready,
        output w_data, w_strb, w_last, w_user, w_valid,
        input  w_ready,
        input  b_id, b_resp, b_user, b_valid,
        output b_ready,
        output ar_id, ar_addr, ar_len, ar_size, ar_burst, ar_lock, ar_cache, ar_prot, ar_qos, ar_region, ar_user, ar_valid,
        input  ar_ready,
        input  r_id, r_data, r_resp, r_last, r_user, r_valid,
        output r_ready
    );

    modport Slave (
        input  aw_id, aw_addr, aw_len, aw_size, aw_burst, aw_lock, aw_cache, aw_prot, aw_qos, aw_region, aw_atop, aw_user, aw_valid,
        output aw_ready,
        input  w_data, w_strb, w_last, w_user, w_valid,
        output w_ready,
        output b_id, b_resp, b_user, b_valid,
        input  b_ready,
        input  ar_id, ar_addr, ar_len, ar_size, ar_burst, ar_lock, ar_cache, ar_prot, ar_qos, ar_region, ar_user, ar_valid,
        output ar_ready,
        output r_id, r_data, r_resp, r_last, r_user, r_valid,
        input  r_ready
    );
endinterface

module axi_xbar_intf #(
    parameter axi_pkg::xbar_cfg_t Cfg      = '0,
    parameter type rule_t                  = axi_pkg::xbar_rule_32_t
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_i,
    AXI_BUS.Slave slv_ports [Cfg.NoSlvPorts-1:0],
    AXI_BUS.Master mst_ports [Cfg.NoMstPorts-1:0],
    input rule_t [Cfg.NoAddrRules-1:0] addr_map_i,
    input logic [Cfg.NoSlvPorts-1:0] en_default_mst_port_i,
    input logic [Cfg.NoSlvPorts-1:0] default_mst_port_i
);

    localparam int unsigned ID_WIDTH = $clog2(Cfg.NoSlvPorts);

    // =========================================================================
    // Address Decoder - Determines target slave port from address
    // =========================================================================
    function automatic int unsigned decode_addr(logic [Cfg.AxiAddrWidth-1:0] addr);
        for (int unsigned i = 0; i < Cfg.NoAddrRules; i++) begin
            if ((addr >= addr_map_i[i].start_addr) && 
                (addr < addr_map_i[i].end_addr)) begin
                return addr_map_i[i].idx;
            end
        end
        return '0;
    endfunction

    // Helper task: Find first master with valid request for target slave
    task automatic find_src_master(
        input int unsigned tgt_slv,
        input logic [Cfg.NoSlvPorts-1:0] valid_mask,
        input logic check_addr_match,
        output logic found,
        output int unsigned src_idx
    );
        found = 1'b0;
        src_idx = 0;
        for (int unsigned m = 0; m < Cfg.NoSlvPorts; m++) begin
            if (valid_mask[m] && (!check_addr_match || (decode_addr(
                (valid_mask == (1 << Cfg.NoSlvPorts) - 1) ? slv_ports[m].aw_addr :
                (valid_mask == (1 << Cfg.NoSlvPorts) - 1) ? slv_ports[m].ar_addr : 
                slv_ports[m].aw_addr) == tgt_slv))) begin
                found = 1'b1;
                src_idx = m;
                break;
            end
        end
    endtask

    // =========================================================================
    // Write Transaction Tracking
    // =========================================================================
    logic [Cfg.NoMstPorts-1:0][ID_WIDTH-1:0] aw_master_id;

    for (genvar s = 0; s < Cfg.NoMstPorts; s++) begin : gen_aw_tracker
        always_ff @(posedge clk_i or negedge rst_ni) begin
            if (!rst_ni) begin
                aw_master_id[s] <= '0;
            end else if (mst_ports[s].aw_valid && mst_ports[s].aw_ready) begin
                for (int unsigned m = 0; m < Cfg.NoSlvPorts; m++) begin
                    if (slv_ports[m].aw_valid && (decode_addr(slv_ports[m].aw_addr) == s)) begin
                        aw_master_id[s] <= ID_WIDTH'(m);
                    end
                end
            end
        end
    end

    // =========================================================================
    // AW/AR Channel: Address-based Demultiplexing
    // =========================================================================
    for (genvar s = 0; s < Cfg.NoMstPorts; s++) begin : gen_aw_demux
        int unsigned src_mst;
        logic found;

        always_comb begin
            // Build valid mask for masters targeting this slave
            logic [Cfg.NoSlvPorts-1:0] aw_valid_mask = '0;
            for (int unsigned m = 0; m < Cfg.NoSlvPorts; m++) begin
                aw_valid_mask[m] = slv_ports[m].aw_valid && (decode_addr(slv_ports[m].aw_addr) == s);
            end

            // Find first valid master
            found = 1'b0;
            src_mst = 0;
            for (int unsigned m = 0; m < Cfg.NoSlvPorts; m++) begin
                if (aw_valid_mask[m]) begin
                    found = 1'b1;
                    src_mst = m;
                    break;
                end
            end

            // Multiplex signals
            if (found) begin
                mst_ports[s].aw_valid = 1'b1;
                mst_ports[s].aw_id = slv_ports[src_mst].aw_id;
                mst_ports[s].aw_addr = slv_ports[src_mst].aw_addr;
                mst_ports[s].aw_len = slv_ports[src_mst].aw_len;
                mst_ports[s].aw_size = slv_ports[src_mst].aw_size;
                mst_ports[s].aw_burst = slv_ports[src_mst].aw_burst;
                mst_ports[s].aw_lock = slv_ports[src_mst].aw_lock;
                mst_ports[s].aw_cache = slv_ports[src_mst].aw_cache;
                mst_ports[s].aw_prot = slv_ports[src_mst].aw_prot;
                mst_ports[s].aw_qos = slv_ports[src_mst].aw_qos;
                mst_ports[s].aw_region = slv_ports[src_mst].aw_region;
                mst_ports[s].aw_atop = slv_ports[src_mst].aw_atop;
                mst_ports[s].aw_user = slv_ports[src_mst].aw_user;
            end else begin
                mst_ports[s].aw_valid = 1'b0;
                {mst_ports[s].aw_id, mst_ports[s].aw_addr, mst_ports[s].aw_len, 
                 mst_ports[s].aw_size, mst_ports[s].aw_burst, mst_ports[s].aw_lock,
                 mst_ports[s].aw_cache, mst_ports[s].aw_prot, mst_ports[s].aw_qos,
                 mst_ports[s].aw_region, mst_ports[s].aw_atop, mst_ports[s].aw_user} = '0;
            end
        end
    end

    // AW ready backward path
    for (genvar m = 0; m < Cfg.NoSlvPorts; m++) begin : gen_aw_ready
        always_comb begin
            slv_ports[m].aw_ready = 1'b0;
            if (slv_ports[m].aw_valid) begin
                slv_ports[m].aw_ready = mst_ports[decode_addr(slv_ports[m].aw_addr)].aw_ready;
            end
        end
    end

    // =========================================================================
    // W Channel: Data path (no address routing needed)
    // =========================================================================
    for (genvar s = 0; s < Cfg.NoMstPorts; s++) begin : gen_w_demux
        logic found;
        int unsigned src_mst;

        always_comb begin
            found = 1'b0;
            src_mst = 0;
            
            for (int unsigned m = 0; m < Cfg.NoSlvPorts; m++) begin
                if (slv_ports[m].w_valid) begin
                    found = 1'b1;
                    src_mst = m;
                    break;
                end
            end

            if (found) begin
                mst_ports[s].w_valid = 1'b1;
                mst_ports[s].w_data = slv_ports[src_mst].w_data;
                mst_ports[s].w_strb = slv_ports[src_mst].w_strb;
                mst_ports[s].w_last = slv_ports[src_mst].w_last;
                mst_ports[s].w_user = slv_ports[src_mst].w_user;
            end else begin
                mst_ports[s].w_valid = 1'b0;
                {mst_ports[s].w_data, mst_ports[s].w_strb, 
                 mst_ports[s].w_last, mst_ports[s].w_user} = '0;
            end
        end
    end

    // W ready broadcast
    for (genvar m = 0; m < Cfg.NoSlvPorts; m++) begin : gen_w_ready
        always_comb begin
            slv_ports[m].w_ready = 1'b0;
            for (int unsigned s = 0; s < Cfg.NoMstPorts; s++) begin
                slv_ports[m].w_ready |= mst_ports[s].w_ready;
            end
        end
    end

    // =========================================================================
    // B Channel: Write Response (routed via tracked master ID)
    // =========================================================================
    for (genvar m = 0; m < Cfg.NoSlvPorts; m++) begin : gen_b_mux
        logic found;
        int unsigned src_slv;

        always_comb begin
            found = 1'b0;
            src_slv = 0;

            for (int unsigned s = 0; s < Cfg.NoMstPorts; s++) begin
                if (mst_ports[s].b_valid && (aw_master_id[s] == m)) begin
                    found = 1'b1;
                    src_slv = s;
                    break;
                end
            end

            if (found) begin
                slv_ports[m].b_valid = 1'b1;
                slv_ports[m].b_id = mst_ports[src_slv].b_id;
                slv_ports[m].b_resp = mst_ports[src_slv].b_resp;
                slv_ports[m].b_user = mst_ports[src_slv].b_user;
            end else begin
                slv_ports[m].b_valid = 1'b0;
                {slv_ports[m].b_id, slv_ports[m].b_resp, slv_ports[m].b_user} = '0;
            end
        end
    end

    // B ready path
    for (genvar s = 0; s < Cfg.NoMstPorts; s++) begin : gen_b_ready
        always_comb begin
            mst_ports[s].b_ready = slv_ports[aw_master_id[s]].b_ready && mst_ports[s].b_valid;
        end
    end

    // =========================================================================
    // AR Channel: Address-based Demultiplexing (similar to AW)
    // =========================================================================
    for (genvar s = 0; s < Cfg.NoMstPorts; s++) begin : gen_ar_demux
        int unsigned src_mst;
        logic found;

        always_comb begin
            logic [Cfg.NoSlvPorts-1:0] ar_valid_mask = '0;
            for (int unsigned m = 0; m < Cfg.NoSlvPorts; m++) begin
                ar_valid_mask[m] = slv_ports[m].ar_valid && (decode_addr(slv_ports[m].ar_addr) == s);
            end

            found = 1'b0;
            src_mst = 0;
            for (int unsigned m = 0; m < Cfg.NoSlvPorts; m++) begin
                if (ar_valid_mask[m]) begin
                    found = 1'b1;
                    src_mst = m;
                    break;
                end
            end

            if (found) begin
                mst_ports[s].ar_valid = 1'b1;
                mst_ports[s].ar_id = slv_ports[src_mst].ar_id;
                mst_ports[s].ar_addr = slv_ports[src_mst].ar_addr;
                mst_ports[s].ar_len = slv_ports[src_mst].ar_len;
                mst_ports[s].ar_size = slv_ports[src_mst].ar_size;
                mst_ports[s].ar_burst = slv_ports[src_mst].ar_burst;
                mst_ports[s].ar_lock = slv_ports[src_mst].ar_lock;
                mst_ports[s].ar_cache = slv_ports[src_mst].ar_cache;
                mst_ports[s].ar_prot = slv_ports[src_mst].ar_prot;
                mst_ports[s].ar_qos = slv_ports[src_mst].ar_qos;
                mst_ports[s].ar_region = slv_ports[src_mst].ar_region;
                mst_ports[s].ar_user = slv_ports[src_mst].ar_user;
            end else begin
                mst_ports[s].ar_valid = 1'b0;
                {mst_ports[s].ar_id, mst_ports[s].ar_addr, mst_ports[s].ar_len,
                 mst_ports[s].ar_size, mst_ports[s].ar_burst, mst_ports[s].ar_lock,
                 mst_ports[s].ar_cache, mst_ports[s].ar_prot, mst_ports[s].ar_qos,
                 mst_ports[s].ar_region, mst_ports[s].ar_user} = '0;
            end
        end
    end

    // AR ready backward path
    for (genvar m = 0; m < Cfg.NoSlvPorts; m++) begin : gen_ar_ready
        always_comb begin
            slv_ports[m].ar_ready = 1'b0;
            if (slv_ports[m].ar_valid) begin
                slv_ports[m].ar_ready = mst_ports[decode_addr(slv_ports[m].ar_addr)].ar_ready;
            end
        end
    end

    // =========================================================================
    // R Channel: Read Response (simple forward)
    // =========================================================================
    for (genvar m = 0; m < Cfg.NoSlvPorts; m++) begin : gen_r_mux
        logic found;
        int unsigned src_slv;

        always_comb begin
            found = 1'b0;
            src_slv = 0;

            for (int unsigned s = 0; s < Cfg.NoMstPorts; s++) begin
                if (mst_ports[s].r_valid) begin
                    found = 1'b1;
                    src_slv = s;
                    break;
                end
            end

            if (found) begin
                slv_ports[m].r_valid = 1'b1;
                slv_ports[m].r_id = mst_ports[src_slv].r_id;
                slv_ports[m].r_data = mst_ports[src_slv].r_data;
                slv_ports[m].r_resp = mst_ports[src_slv].r_resp;
                slv_ports[m].r_last = mst_ports[src_slv].r_last;
                slv_ports[m].r_user = mst_ports[src_slv].r_user;
            end else begin
                slv_ports[m].r_valid = 1'b0;
                {slv_ports[m].r_id, slv_ports[m].r_data, slv_ports[m].r_resp,
                 slv_ports[m].r_last, slv_ports[m].r_user} = '0;
            end
        end
    end

    // R ready path
    for (genvar s = 0; s < Cfg.NoMstPorts; s++) begin : gen_r_ready
        always_comb begin
            mst_ports[s].r_ready = 1'b0;
            for (int unsigned m = 0; m < Cfg.NoSlvPorts; m++) begin
                if (slv_ports[m].ar_valid && (decode_addr(slv_ports[m].ar_addr) == s)) begin
                    mst_ports[s].r_ready |= slv_ports[m].r_ready;
                end
            end
        end
    end

endmodule

module axi_top #(
    parameter int unsigned NUM_MASTERS    = 2,
    parameter int unsigned NUM_SLAVES     = 2,
    parameter int unsigned AXI_ADDR_WIDTH = 32,
    parameter int unsigned AXI_DATA_WIDTH = 64,
    parameter int unsigned AXI_ID_WIDTH   = 4
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_i,

    AXI_BUS.Slave  master_ports [NUM_MASTERS-1:0],
    AXI_BUS.Master slave_ports  [NUM_SLAVES-1:0]
);

    localparam axi_pkg::xbar_cfg_t XBAR_CFG = '{
        NoSlvPorts:         NUM_MASTERS,
        NoMstPorts:         NUM_SLAVES,
        MaxMstTrans:        8,
        MaxSlvTrans:        8,
        FallThrough:        1'b0,
        LatencyMode:        axi_pkg::CUT_ALL_AX,
        PipelineStages:     1,
        AxiIdWidthSlvPorts: AXI_ID_WIDTH,
        AxiIdUsedSlvPorts:  AXI_ID_WIDTH,
        UniqueIds:          1'b0,
        AxiAddrWidth:       AXI_ADDR_WIDTH,
        AxiDataWidth:       AXI_DATA_WIDTH,
        NoAddrRules:        NUM_SLAVES
    };

    typedef axi_pkg::xbar_rule_32_t rule_t;

    function automatic rule_t [NUM_SLAVES-1:0] init_addr_map();
        for (int unsigned i = 0; i < NUM_SLAVES; i++) begin
            init_addr_map[i] = rule_t'{
                idx:        unsigned'(i),
                start_addr: 32'h0000_0000 + i * 32'h0000_2000,
                end_addr:   32'h0000_0000 + (i + 1) * 32'h0000_2000
            };
        end
    endfunction

    localparam rule_t [NUM_SLAVES-1:0] ADDR_MAP = init_addr_map();

    axi_xbar_intf #(
        .Cfg            (XBAR_CFG),
        .rule_t         (rule_t)
    ) u_xbar (
        .clk_i               (clk_i),
        .rst_ni              (rst_ni),
        .test_i              (test_i),
        .slv_ports           (master_ports),
        .mst_ports           (slave_ports),
        .addr_map_i          (ADDR_MAP),
        .en_default_mst_port_i ('0),
        .default_mst_port_i    ('0)
    );

endmodule
