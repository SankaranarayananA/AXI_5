// SPDX-License-Identifier: SHL-0.51
// Copyright (c) 2026 sankaran
//
// AXI5 NSAID remapper for the AW and AR channels.
module axi5_nsaid_remap_intf #(
  parameter axi_pkg::nsaid_t MatchNsaid = '0,
  parameter axi_pkg::nsaid_t RemapNsaid = '0
) (
  AXI5_BUS.Slave slv,
  AXI5_BUS.Master mst
);

  assign mst.aw_id     = slv.aw_id;
  assign mst.aw_addr   = slv.aw_addr;
  assign mst.aw_len    = slv.aw_len;
  assign mst.aw_size   = slv.aw_size;
  assign mst.aw_burst  = slv.aw_burst;
  assign mst.aw_lock   = slv.aw_lock;
  assign mst.aw_cache  = slv.aw_cache;
  assign mst.aw_prot   = slv.aw_prot;
  assign mst.aw_qos    = slv.aw_qos;
  assign mst.aw_region = slv.aw_region;
  assign mst.aw_atop   = slv.aw_atop;
  assign mst.aw_nsaid  = (slv.aw_nsaid == MatchNsaid) ? RemapNsaid : slv.aw_nsaid;
  assign mst.aw_user   = slv.aw_user;
  assign mst.aw_valid  = slv.aw_valid;
  assign slv.aw_ready  = mst.aw_ready;

  assign mst.w_data    = slv.w_data;
  assign mst.w_strb    = slv.w_strb;
  assign mst.w_last    = slv.w_last;
  assign mst.w_user    = slv.w_user;
  assign mst.w_valid   = slv.w_valid;
  assign slv.w_ready   = mst.w_ready;

  assign slv.b_id      = mst.b_id;
  assign slv.b_resp    = mst.b_resp;
  assign slv.b_user    = mst.b_user;
  assign slv.b_valid   = mst.b_valid;
  assign mst.b_ready   = slv.b_ready;

  assign mst.ar_id     = slv.ar_id;
  assign mst.ar_addr   = slv.ar_addr;
  assign mst.ar_len    = slv.ar_len;
  assign mst.ar_size   = slv.ar_size;
  assign mst.ar_burst  = slv.ar_burst;
  assign mst.ar_lock   = slv.ar_lock;
  assign mst.ar_cache  = slv.ar_cache;
  assign mst.ar_prot   = slv.ar_prot;
  assign mst.ar_qos    = slv.ar_qos;
  assign mst.ar_region = slv.ar_region;
  assign mst.ar_nsaid  = (slv.ar_nsaid == MatchNsaid) ? RemapNsaid : slv.ar_nsaid;
  assign mst.ar_user   = slv.ar_user;
  assign mst.ar_valid  = slv.ar_valid;
  assign slv.ar_ready  = mst.ar_ready;

  assign slv.r_id      = mst.r_id;
  assign slv.r_data    = mst.r_data;
  assign slv.r_resp    = mst.r_resp;
  assign slv.r_last    = mst.r_last;
  assign slv.r_user    = mst.r_user;
  assign slv.r_valid   = mst.r_valid;
  assign mst.r_ready   = slv.r_ready;

endmodule
