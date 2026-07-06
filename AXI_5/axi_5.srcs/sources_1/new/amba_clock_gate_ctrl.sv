// SPDX-License-Identifier: MIT
// amba_clock_gate_ctrl.sv
//
// Clock gate controller for AMBA5 AXI/AXIS power management.
//
// Operation
// ---------
// The gated output clock (clk_out) is enabled whenever activity is detected
// and stays enabled for an idle-countdown period after the last activity, then
// gates off.
//
// Activity sources (either is sufficient to keep the clock running):
//   user_valid  – user-side activity (e.g. TWAKEUP, pending data)
//   axi_valid   – AXI channel valid (aw_valid, w_valid, ar_valid …)
//
// Configuration
// -------------
//   cfg_cg_enable     – 1 = clock gating active, 0 = clock always on
//   cfg_cg_idle_count – number of idle cycles before gating (min 1)
//
// Outputs
// -------
//   clk_out  – gated clock (combinatorial ICG gate driven by latch enable)
//   gating   – 1 when the clock is currently gated off
//   idle     – 1 when the idle counter has expired (clock will gate next cycle)
//
// Implementation note: On an FPGA the ICG is modelled with an always_latch
// enable register which synthesizers map to LUT-based clock enables.  In an
// ASIC flow replace the always_latch cell with an integrated clock-gating cell
// (ICG) from the standard cell library.

`timescale 1ns / 1ps

module amba_clock_gate_ctrl #(
    parameter int CG_IDLE_COUNT_WIDTH = 4   // idle counter width (1..15 cycles)
) (
    input  logic                            clk_in,
    input  logic                            aresetn,

    // Configuration
    input  logic                            cfg_cg_enable,
    input  logic [CG_IDLE_COUNT_WIDTH-1:0]  cfg_cg_idle_count,

    // Activity signals
    input  logic                            user_valid,
    input  logic                            axi_valid,

    // Outputs
    output logic                            clk_out,
    output logic                            gating,
    output logic                            idle
);

    // -------------------------------------------------------------------------
    // Idle counter
    // -------------------------------------------------------------------------
    logic [CG_IDLE_COUNT_WIDTH-1:0] idle_cnt;
    logic                            active;
    logic                            clk_en;     // enable register (pre-latch)
    logic                            clk_en_latch; // ICG latch output

    assign active = user_valid | axi_valid;

    always_ff @(posedge clk_in or negedge aresetn) begin
        if (!aresetn) begin
            idle_cnt <= '0;
            clk_en   <= 1'b1;   // clock on after reset
        end else begin
            if (active) begin
                // Activity detected – reload counter and keep clock on
                idle_cnt <= cfg_cg_idle_count;
                clk_en   <= 1'b1;
            end else if (cfg_cg_enable && (idle_cnt == '0)) begin
                // No activity and idle count expired – gate the clock
                clk_en <= 1'b0;
            end else if (idle_cnt != '0) begin
                // Counting down
                idle_cnt <= idle_cnt - 1'b1;
                clk_en   <= 1'b1;
            end
        end
    end

    // -------------------------------------------------------------------------
    // ICG latch (positive-level sensitive)
    // Maps to an integrated clock-gating cell in ASIC; on FPGA the synthesiser
    // will absorb this into the register clock-enable logic.
    // -------------------------------------------------------------------------
    always_latch begin
        if (!clk_in)                    // transparent on low phase
            clk_en_latch <= clk_en;
    end

    // -------------------------------------------------------------------------
    // Gated clock output
    // -------------------------------------------------------------------------
    assign clk_out = clk_in & clk_en_latch;

    // Status
    assign gating = ~clk_en_latch;
    assign idle   = (idle_cnt == '0) & ~active;

endmodule : amba_clock_gate_ctrl
