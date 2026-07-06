// SPDX-License-Identifier: MIT
// reset_defs.svh
// Common reset macros for AMBA5 RTL modules.
//
// ALWAYS_FF_RST(clk, rstn, body)
//   Generates an always_ff block with asynchronous active-low reset.
//   Usage:
//     `ALWAYS_FF_RST(aclk, aresetn,
//         if (!aresetn) q <= '0;
//         else          q <= d;
//     )

`ifndef RESET_DEFS_SVH
`define RESET_DEFS_SVH

// Asynchronous active-low reset always_ff block.
// The reset edge and the clock posedge are both listed as sensitivity events
// so the synthesiser infers flip-flops with asynchronous reset.
`define ALWAYS_FF_RST(clk, rstn, body) \
    always_ff @(posedge clk or negedge rstn) begin \
        body \
    end

// Synchronous active-low reset always_ff block (alternative).
`define ALWAYS_FF_SRST(clk, rstn, body) \
    always_ff @(posedge clk) begin \
        body \
    end

`endif // RESET_DEFS_SVH
