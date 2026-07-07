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
    typedef logic [3:0] nsaid_t;
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
    localparam int unsigned STRB_WIDTH = Cfg.AxiDataWidth / 8;

    // =========================================================================
    // Address Decoder
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

    // =========================================================================
    // Extract signals from interfaces into logic arrays (XSIM workaround)
    // =========================================================================
    
    // Slave (input) side - AW channel
    logic [Cfg.NoSlvPorts-1:0] slv_aw_valid;
    logic [Cfg.NoSlvPorts-1:0][Cfg.AxiAddrWidth-1:0] slv_aw_addr;
    logic [Cfg.NoSlvPorts-1:0][7:0] slv_aw_len;
    logic [Cfg.NoSlvPorts-1:0][2:0] slv_aw_size;
    logic [Cfg.NoSlvPorts-1:0][1:0] slv_aw_burst;
    logic [Cfg.NoSlvPorts-1:0] slv_aw_lock;
    logic [Cfg.NoSlvPorts-1:0][3:0] slv_aw_cache;
    logic [Cfg.NoSlvPorts-1:0][2:0] slv_aw_prot;
    logic [Cfg.NoSlvPorts-1:0][3:0] slv_aw_qos;
    logic [Cfg.NoSlvPorts-1:0][3:0] slv_aw_region;
    logic [Cfg.NoSlvPorts-1:0][5:0] slv_aw_atop;
    logic [Cfg.NoSlvPorts-1:0] slv_aw_ready;

    // Slave (input) side - W channel
    logic [Cfg.NoSlvPorts-1:0] slv_w_valid;
    logic [Cfg.NoSlvPorts-1:0][Cfg.AxiDataWidth-1:0] slv_w_data;
    logic [Cfg.NoSlvPorts-1:0][STRB_WIDTH-1:0] slv_w_strb;
    logic [Cfg.NoSlvPorts-1:0] slv_w_last;
    logic [Cfg.NoSlvPorts-1:0] slv_w_ready;

    // Slave (input) side - B channel
    logic [Cfg.NoSlvPorts-1:0] slv_b_valid;
    logic [Cfg.NoSlvPorts-1:0][1:0] slv_b_resp;
    logic [Cfg.NoSlvPorts-1:0] slv_b_ready;

    // Slave (input) side - AR channel
    logic [Cfg.NoSlvPorts-1:0] slv_ar_valid;
    logic [Cfg.NoSlvPorts-1:0][Cfg.AxiAddrWidth-1:0] slv_ar_addr;
    logic [Cfg.NoSlvPorts-1:0][7:0] slv_ar_len;
    logic [Cfg.NoSlvPorts-1:0][2:0] slv_ar_size;
    logic [Cfg.NoSlvPorts-1:0][1:0] slv_ar_burst;
    logic [Cfg.NoSlvPorts-1:0] slv_ar_lock;
    logic [Cfg.NoSlvPorts-1:0][3:0] slv_ar_cache;
    logic [Cfg.NoSlvPorts-1:0][2:0] slv_ar_prot;
    logic [Cfg.NoSlvPorts-1:0][3:0] slv_ar_qos;
    logic [Cfg.NoSlvPorts-1:0][3:0] slv_ar_region;
    logic [Cfg.NoSlvPorts-1:0] slv_ar_ready;

    // Slave (input) side - R channel
    logic [Cfg.NoSlvPorts-1:0] slv_r_valid;
    logic [Cfg.NoSlvPorts-1:0][Cfg.AxiDataWidth-1:0] slv_r_data;
    logic [Cfg.NoSlvPorts-1:0][1:0] slv_r_resp;
    logic [Cfg.NoSlvPorts-1:0] slv_r_last;
    logic [Cfg.NoSlvPorts-1:0] slv_r_ready;

    // Master (output) side - routed signals
    logic [Cfg.NoMstPorts-1:0] mst_aw_valid;
    logic [Cfg.NoMstPorts-1:0][Cfg.AxiAddrWidth-1:0] mst_aw_addr;
    logic [Cfg.NoMstPorts-1:0][7:0] mst_aw_len;
    logic [Cfg.NoMstPorts-1:0][2:0] mst_aw_size;
    logic [Cfg.NoMstPorts-1:0][1:0] mst_aw_burst;
    logic [Cfg.NoMstPorts-1:0] mst_aw_lock;
    logic [Cfg.NoMstPorts-1:0][3:0] mst_aw_cache;
    logic [Cfg.NoMstPorts-1:0][2:0] mst_aw_prot;
    logic [Cfg.NoMstPorts-1:0][3:0] mst_aw_qos;
    logic [Cfg.NoMstPorts-1:0][3:0] mst_aw_region;
    logic [Cfg.NoMstPorts-1:0][5:0] mst_aw_atop;
    logic [Cfg.NoMstPorts-1:0] mst_aw_ready;

    logic [Cfg.NoMstPorts-1:0] mst_w_valid;
    logic [Cfg.NoMstPorts-1:0][Cfg.AxiDataWidth-1:0] mst_w_data;
    logic [Cfg.NoMstPorts-1:0][STRB_WIDTH-1:0] mst_w_strb;
    logic [Cfg.NoMstPorts-1:0] mst_w_last;
    logic [Cfg.NoMstPorts-1:0] mst_w_ready;

    logic [Cfg.NoMstPorts-1:0] mst_b_valid;
    logic [Cfg.NoMstPorts-1:0][1:0] mst_b_resp;
    logic [Cfg.NoMstPorts-1:0] mst_b_ready;

    logic [Cfg.NoMstPorts-1:0] mst_ar_valid;
    logic [Cfg.NoMstPorts-1:0][Cfg.AxiAddrWidth-1:0] mst_ar_addr;
    logic [Cfg.NoMstPorts-1:0][7:0] mst_ar_len;
    logic [Cfg.NoMstPorts-1:0][2:0] mst_ar_size;
    logic [Cfg.NoMstPorts-1:0][1:0] mst_ar_burst;
    logic [Cfg.NoMstPorts-1:0] mst_ar_lock;
    logic [Cfg.NoMstPorts-1:0][3:0] mst_ar_cache;
    logic [Cfg.NoMstPorts-1:0][2:0] mst_ar_prot;
    logic [Cfg.NoMstPorts-1:0][3:0] mst_ar_qos;
    logic [Cfg.NoMstPorts-1:0][3:0] mst_ar_region;
    logic [Cfg.NoMstPorts-1:0] mst_ar_ready;

    logic [Cfg.NoMstPorts-1:0] mst_r_valid;
    logic [Cfg.NoMstPorts-1:0][Cfg.AxiDataWidth-1:0] mst_r_data;
    logic [Cfg.NoMstPorts-1:0][1:0] mst_r_resp;
    logic [Cfg.NoMstPorts-1:0] mst_r_last;
    logic [Cfg.NoMstPorts-1:0] mst_r_ready;

    // =========================================================================
    // Extract signals from interface arrays using elaboration-time indexing
    // =========================================================================
    for (genvar m = 0; m < Cfg.NoSlvPorts; m++) begin : gen_extract_slv
        assign slv_aw_valid[m] = slv_ports[m].aw_valid;
        assign slv_aw_addr[m] = slv_ports[m].aw_addr;
        assign slv_aw_len[m] = slv_ports[m].aw_len;
        assign slv_aw_size[m] = slv_ports[m].aw_size;
        assign slv_aw_burst[m] = slv_ports[m].aw_burst;
        assign slv_aw_lock[m] = slv_ports[m].aw_lock;
        assign slv_aw_cache[m] = slv_ports[m].aw_cache;
        assign slv_aw_prot[m] = slv_ports[m].aw_prot;
        assign slv_aw_qos[m] = slv_ports[m].aw_qos;
        assign slv_aw_region[m] = slv_ports[m].aw_region;
        assign slv_aw_atop[m] = slv_ports[m].aw_atop;
        assign slv_ports[m].aw_ready = slv_aw_ready[m];

        assign slv_w_valid[m] = slv_ports[m].w_valid;
        assign slv_w_data[m] = slv_ports[m].w_data;
        assign slv_w_strb[m] = slv_ports[m].w_strb;
        assign slv_w_last[m] = slv_ports[m].w_last;
        assign slv_ports[m].w_ready = slv_w_ready[m];

        assign slv_ports[m].b_valid = slv_b_valid[m];
        assign slv_ports[m].b_resp = slv_b_resp[m];
        assign slv_b_ready[m] = slv_ports[m].b_ready;

        assign slv_ar_valid[m] = slv_ports[m].ar_valid;
        assign slv_ar_addr[m] = slv_ports[m].ar_addr;
        assign slv_ar_len[m] = slv_ports[m].ar_len;
        assign slv_ar_size[m] = slv_ports[m].ar_size;
        assign slv_ar_burst[m] = slv_ports[m].ar_burst;
        assign slv_ar_lock[m] = slv_ports[m].ar_lock;
        assign slv_ar_cache[m] = slv_ports[m].ar_cache;
        assign slv_ar_prot[m] = slv_ports[m].ar_prot;
        assign slv_ar_qos[m] = slv_ports[m].ar_qos;
        assign slv_ar_region[m] = slv_ports[m].ar_region;
        assign slv_ports[m].ar_ready = slv_ar_ready[m];

        assign slv_ports[m].r_valid = slv_r_valid[m];
        assign slv_ports[m].r_data = slv_r_data[m];
        assign slv_ports[m].r_resp = slv_r_resp[m];
        assign slv_ports[m].r_last = slv_r_last[m];
        assign slv_r_ready[m] = slv_ports[m].r_ready;
    end

    // =========================================================================
    // Multi-master routing with per-slave origin tracking (in-order)
    // =========================================================================
    localparam int unsigned NM_MST   = Cfg.NoSlvPorts;   // upstream masters
    localparam int unsigned NM_SLV   = Cfg.NoMstPorts;   // downstream slaves
    localparam int unsigned MIDX_W   = (NM_MST > 1) ? $clog2(NM_MST) : 1;
    localparam int unsigned OUTSTAND = 16;               // max outstanding per slave
    localparam int unsigned OPTR_W   = $clog2(OUTSTAND);

    // Write-data path lock (per downstream slave)
    logic                w_busy_q  [NM_SLV];
    logic [MIDX_W-1:0]   w_src_q   [NM_SLV];

    // B-response origin FIFO (per downstream slave)
    logic [MIDX_W-1:0]   b_org_mem [NM_SLV][OUTSTAND];
    logic [OPTR_W-1:0]   b_org_wptr[NM_SLV];
    logic [OPTR_W-1:0]   b_org_rptr[NM_SLV];
    logic [OPTR_W:0]     b_org_cnt [NM_SLV];

    // R-response origin FIFO (per downstream slave)
    logic [MIDX_W-1:0]   r_org_mem [NM_SLV][OUTSTAND];
    logic [OPTR_W-1:0]   r_org_wptr[NM_SLV];
    logic [OPTR_W-1:0]   r_org_rptr[NM_SLV];
    logic [OPTR_W:0]     r_org_cnt [NM_SLV];

    // Combinational arbitration / handshake helpers (per downstream slave)
    logic [MIDX_W-1:0]   aw_gnt_src [NM_SLV];
    logic                aw_gnt_vld [NM_SLV];
    logic                aw_hsk     [NM_SLV];
    logic                w_hsk_last [NM_SLV];
    logic [MIDX_W-1:0]   b_org      [NM_SLV];
    logic                b_hsk      [NM_SLV];
    logic [MIDX_W-1:0]   ar_gnt_src [NM_SLV];
    logic                ar_gnt_vld [NM_SLV];
    logic                ar_hsk     [NM_SLV];
    logic [MIDX_W-1:0]   r_org      [NM_SLV];
    logic                r_hsk_last [NM_SLV];

    always_comb begin
        // Default: all outputs zero
        mst_aw_valid = '0;
        mst_aw_addr = '0;
        mst_aw_len = '0;
        mst_aw_size = '0;
        mst_aw_burst = '0;
        mst_aw_lock = '0;
        mst_aw_cache = '0;
        mst_aw_prot = '0;
        mst_aw_qos = '0;
        mst_aw_region = '0;
        mst_aw_atop = '0;
        slv_aw_ready = '0;

        mst_w_valid = '0;
        mst_w_data = '0;
        mst_w_strb = '0;
        mst_w_last = '0;
        slv_w_ready = '0;

        slv_b_valid = '0;
        slv_b_resp = '0;
        mst_b_ready = '0;

        mst_ar_valid = '0;
        mst_ar_addr = '0;
        mst_ar_len = '0;
        mst_ar_size = '0;
        mst_ar_burst = '0;
        mst_ar_lock = '0;
        mst_ar_cache = '0;
        mst_ar_prot = '0;
        mst_ar_qos = '0;
        mst_ar_region = '0;
        slv_ar_ready = '0;

        slv_r_valid = '0;
        slv_r_data = '0;
        slv_r_resp = '0;
        slv_r_last = '0;
        mst_r_ready = '0;

        for (int unsigned s = 0; s < NM_SLV; s++) begin
            aw_gnt_src[s] = '0;
            aw_gnt_vld[s] = 1'b0;
            aw_hsk[s]     = 1'b0;
            w_hsk_last[s] = 1'b0;
            b_org[s]      = b_org_mem[s][b_org_rptr[s]];
            b_hsk[s]      = 1'b0;
            ar_gnt_src[s] = '0;
            ar_gnt_vld[s] = 1'b0;
            ar_hsk[s]     = 1'b0;
            r_org[s]      = r_org_mem[s][r_org_rptr[s]];
            r_hsk_last[s] = 1'b0;
        end

        // Route AW: lowest-index master wins, only if W path free and B FIFO has room
        for (int unsigned s = 0; s < NM_SLV; s++) begin
            if (!w_busy_q[s] && (b_org_cnt[s] < OUTSTAND)) begin
                for (int unsigned m = 0; m < NM_MST; m++) begin
                    if (!aw_gnt_vld[s] && slv_aw_valid[m] &&
                        (decode_addr(slv_aw_addr[m]) == s)) begin
                        aw_gnt_vld[s]    = 1'b1;
                        aw_gnt_src[s]    = m[MIDX_W-1:0];
                        mst_aw_valid[s]  = 1'b1;
                        mst_aw_addr[s]   = slv_aw_addr[m];
                        mst_aw_len[s]    = slv_aw_len[m];
                        mst_aw_size[s]   = slv_aw_size[m];
                        mst_aw_burst[s]  = slv_aw_burst[m];
                        mst_aw_lock[s]   = slv_aw_lock[m];
                        mst_aw_cache[s]  = slv_aw_cache[m];
                        mst_aw_prot[s]   = slv_aw_prot[m];
                        mst_aw_qos[s]    = slv_aw_qos[m];
                        mst_aw_region[s] = slv_aw_region[m];
                        mst_aw_atop[s]   = slv_aw_atop[m];
                        slv_aw_ready[m]  = mst_aw_ready[s];
                    end
                end
                aw_hsk[s] = mst_aw_valid[s] && mst_aw_ready[s];
            end
        end

        // Route W: locked to the master that owns the in-flight write burst
        for (int unsigned s = 0; s < NM_SLV; s++) begin
            if (w_busy_q[s]) begin
                mst_w_valid[s]          = slv_w_valid[w_src_q[s]];
                mst_w_data[s]           = slv_w_data[w_src_q[s]];
                mst_w_strb[s]           = slv_w_strb[w_src_q[s]];
                mst_w_last[s]           = slv_w_last[w_src_q[s]];
                slv_w_ready[w_src_q[s]] = mst_w_ready[s];
                w_hsk_last[s] = mst_w_valid[s] && mst_w_ready[s] && mst_w_last[s];
            end
        end

        // Route B: only to the originating master, arbitrated per master port
        for (int unsigned m = 0; m < NM_MST; m++) begin
            for (int unsigned s = 0; s < NM_SLV; s++) begin
                if (!slv_b_valid[m] && mst_b_valid[s] &&
                    (b_org_cnt[s] != 0) && (b_org[s] == m[MIDX_W-1:0])) begin
                    slv_b_valid[m] = 1'b1;
                    slv_b_resp[m]  = mst_b_resp[s];
                    mst_b_ready[s] = slv_b_ready[m];
                    b_hsk[s]       = mst_b_valid[s] && mst_b_ready[s];
                end
            end
        end

        // Route AR: lowest-index master wins, only if R FIFO has room
        for (int unsigned s = 0; s < NM_SLV; s++) begin
            if (r_org_cnt[s] < OUTSTAND) begin
                for (int unsigned m = 0; m < NM_MST; m++) begin
                    if (!ar_gnt_vld[s] && slv_ar_valid[m] &&
                        (decode_addr(slv_ar_addr[m]) == s)) begin
                        ar_gnt_vld[s]    = 1'b1;
                        ar_gnt_src[s]    = m[MIDX_W-1:0];
                        mst_ar_valid[s]  = 1'b1;
                        mst_ar_addr[s]   = slv_ar_addr[m];
                        mst_ar_len[s]    = slv_ar_len[m];
                        mst_ar_size[s]   = slv_ar_size[m];
                        mst_ar_burst[s]  = slv_ar_burst[m];
                        mst_ar_lock[s]   = slv_ar_lock[m];
                        mst_ar_cache[s]  = slv_ar_cache[m];
                        mst_ar_prot[s]   = slv_ar_prot[m];
                        mst_ar_qos[s]    = slv_ar_qos[m];
                        mst_ar_region[s] = slv_ar_region[m];
                        slv_ar_ready[m]  = mst_ar_ready[s];
                    end
                end
                ar_hsk[s] = mst_ar_valid[s] && mst_ar_ready[s];
            end
        end

        // Route R: only to the originating master, arbitrated per master port
        for (int unsigned m = 0; m < NM_MST; m++) begin
            for (int unsigned s = 0; s < NM_SLV; s++) begin
                if (!slv_r_valid[m] && mst_r_valid[s] &&
                    (r_org_cnt[s] != 0) && (r_org[s] == m[MIDX_W-1:0])) begin
                    slv_r_valid[m] = 1'b1;
                    slv_r_data[m]  = mst_r_data[s];
                    slv_r_resp[m]  = mst_r_resp[s];
                    slv_r_last[m]  = mst_r_last[s];
                    mst_r_ready[s] = slv_r_ready[m];
                    r_hsk_last[s]  = mst_r_valid[s] && mst_r_ready[s] && mst_r_last[s];
                end
            end
        end
    end

    // =========================================================================
    // Origin-FIFO and write-lock state (sequential)
    // =========================================================================
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (int unsigned s = 0; s < NM_SLV; s++) begin
                w_busy_q[s]   <= 1'b0;
                w_src_q[s]    <= '0;
                b_org_wptr[s] <= '0;
                b_org_rptr[s] <= '0;
                b_org_cnt[s]  <= '0;
                r_org_wptr[s] <= '0;
                r_org_rptr[s] <= '0;
                r_org_cnt[s]  <= '0;
            end
        end else begin
            for (int unsigned s = 0; s < NM_SLV; s++) begin
                // Write-burst ownership lock
                if (aw_hsk[s]) begin
                    w_busy_q[s] <= 1'b1;
                    w_src_q[s]  <= aw_gnt_src[s];
                end else if (w_hsk_last[s]) begin
                    w_busy_q[s] <= 1'b0;
                end

                // B origin FIFO push (on AW accept) / pop (on B accept)
                if (aw_hsk[s]) begin
                    b_org_mem[s][b_org_wptr[s]] <= aw_gnt_src[s];
                    b_org_wptr[s] <= b_org_wptr[s] + 1'b1;
                end
                if (b_hsk[s]) begin
                    b_org_rptr[s] <= b_org_rptr[s] + 1'b1;
                end
                b_org_cnt[s] <= b_org_cnt[s] + (aw_hsk[s] ? 1 : 0) - (b_hsk[s] ? 1 : 0);

                // R origin FIFO push (on AR accept) / pop (on R last accept)
                if (ar_hsk[s]) begin
                    r_org_mem[s][r_org_wptr[s]] <= ar_gnt_src[s];
                    r_org_wptr[s] <= r_org_wptr[s] + 1'b1;
                end
                if (r_hsk_last[s]) begin
                    r_org_rptr[s] <= r_org_rptr[s] + 1'b1;
                end
                r_org_cnt[s] <= r_org_cnt[s] + (ar_hsk[s] ? 1 : 0) - (r_hsk_last[s] ? 1 : 0);
            end
        end
    end

    // =========================================================================
    // Pack routed signals back into master interface arrays (elaboration-time)
    // =========================================================================
    for (genvar s = 0; s < Cfg.NoMstPorts; s++) begin : gen_pack_mst
        assign mst_ports[s].aw_valid = mst_aw_valid[s];
        assign mst_ports[s].aw_addr = mst_aw_addr[s];
        assign mst_ports[s].aw_len = mst_aw_len[s];
        assign mst_ports[s].aw_size = mst_aw_size[s];
        assign mst_ports[s].aw_burst = mst_aw_burst[s];
        assign mst_ports[s].aw_lock = mst_aw_lock[s];
        assign mst_ports[s].aw_cache = mst_aw_cache[s];
        assign mst_ports[s].aw_prot = mst_aw_prot[s];
        assign mst_ports[s].aw_qos = mst_aw_qos[s];
        assign mst_ports[s].aw_region = mst_aw_region[s];
        assign mst_ports[s].aw_atop = mst_aw_atop[s];
        assign mst_aw_ready[s] = mst_ports[s].aw_ready;

        assign mst_ports[s].w_valid = mst_w_valid[s];
        assign mst_ports[s].w_data = mst_w_data[s];
        assign mst_ports[s].w_strb = mst_w_strb[s];
        assign mst_ports[s].w_last = mst_w_last[s];
        assign mst_w_ready[s] = mst_ports[s].w_ready;

        assign mst_b_valid[s] = mst_ports[s].b_valid;
        assign mst_b_resp[s] = mst_ports[s].b_resp;
        assign mst_ports[s].b_ready = mst_b_ready[s];

        assign mst_ports[s].ar_valid = mst_ar_valid[s];
        assign mst_ports[s].ar_addr = mst_ar_addr[s];
        assign mst_ports[s].ar_len = mst_ar_len[s];
        assign mst_ports[s].ar_size = mst_ar_size[s];
        assign mst_ports[s].ar_burst = mst_ar_burst[s];
        assign mst_ports[s].ar_lock = mst_ar_lock[s];
        assign mst_ports[s].ar_cache = mst_ar_cache[s];
        assign mst_ports[s].ar_prot = mst_ar_prot[s];
        assign mst_ports[s].ar_qos = mst_ar_qos[s];
        assign mst_ports[s].ar_region = mst_ar_region[s];
        assign mst_ar_ready[s] = mst_ports[s].ar_ready;

        assign mst_r_valid[s] = mst_ports[s].r_valid;
        assign mst_r_data[s] = mst_ports[s].r_data;
        assign mst_r_resp[s] = mst_ports[s].r_resp;
        assign mst_r_last[s] = mst_ports[s].r_last;
        assign mst_ports[s].r_ready = mst_r_ready[s];
    end

endmodule

module axi_top #(
    // Keep standalone synthesis defaults small enough for medium FPGA packages.
    // Simulation/testbench can and does override these parameters explicitly.
    parameter int unsigned NUM_MASTERS    = 1,
    parameter int unsigned NUM_SLAVES     = 1,
    parameter int unsigned AXI_ADDR_WIDTH = 8,
    parameter int unsigned AXI_DATA_WIDTH = 8,
    parameter int unsigned AXI_ID_WIDTH   = 1
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
