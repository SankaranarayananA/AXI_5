// SPDX-License-Identifier: MIT
// gaxi_skid_buffer.sv
//
// Parameterized skid (elastic) FIFO buffer used by the AXIS5 master and slave
// modules to decouple producer and consumer handshake timing.
//
// When DEPTH == 1 this is a classical 2-entry skid buffer that breaks the
// combinatorial ready-path.  For DEPTH > 1 a circular FIFO is used, still
// preserving the single-cycle latency property on an empty buffer.
//
// Ports
// -----
//  wr_valid  – producer asserts to push wr_data
//  wr_ready  – asserted when the buffer can accept data (not full)
//  wr_data   – DATA_WIDTH-bit write data
//
//  rd_valid  – asserted when the buffer has data to consume
//  rd_ready  – consumer asserts to pop
//  rd_data   – DATA_WIDTH-bit read data (head of buffer)
//  rd_count  – number of entries currently in the buffer (capped at 4-bit)
//  count     – full occupancy counter (DEPTH+1 entries wide)

`timescale 1ns / 1ps

module gaxi_skid_buffer #(
    parameter int          DEPTH         = 4,
    parameter int          DATA_WIDTH    = 8,
    parameter string       INSTANCE_NAME = "GAXI_SKID"
) (
    input  logic                        axi_aclk,
    input  logic                        axi_aresetn,

    // Write (producer) side
    input  logic                        wr_valid,
    output logic                        wr_ready,
    input  logic [DATA_WIDTH-1:0]       wr_data,

    // Read (consumer) side
    output logic                        rd_valid,
    input  logic                        rd_ready,
    output logic [DATA_WIDTH-1:0]       rd_data,
    output logic [3:0]                  rd_count,   // saturating 4-bit occupancy

    // Full occupancy counter (clog2(DEPTH+1)+1 bits, exposed for monitoring)
    output logic [$clog2(DEPTH+1):0]    count
);

    // -------------------------------------------------------------------------
    // Internal storage
    // -------------------------------------------------------------------------
    localparam int PTR_W = $clog2(DEPTH);           // address bits
    localparam int CNT_W = $clog2(DEPTH + 1) + 1;  // enough to hold 0..DEPTH

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    logic [PTR_W-1:0]  wr_ptr;
    logic [PTR_W-1:0]  rd_ptr;
    logic [CNT_W-1:0]  occ;      // number of valid entries

    // -------------------------------------------------------------------------
    // Occupancy / full / empty
    // -------------------------------------------------------------------------
    logic full, empty;
    assign full  = (occ == CNT_W'(DEPTH));
    assign empty = (occ == '0);

    assign wr_ready  = ~full;
    assign rd_valid  = ~empty;
    assign count     = occ[$clog2(DEPTH+1):0];
    assign rd_count  = (occ > 4'd15) ? 4'd15 : 4'(occ);

    // -------------------------------------------------------------------------
    // Write path
    // -------------------------------------------------------------------------
    always_ff @(posedge axi_aclk or negedge axi_aresetn) begin
        if (!axi_aresetn) begin
            wr_ptr <= '0;
        end else if (wr_valid && wr_ready) begin
            mem[wr_ptr] <= wr_data;
            wr_ptr <= (wr_ptr == PTR_W'(DEPTH - 1)) ? '0 : wr_ptr + 1'b1;
        end
    end

    // -------------------------------------------------------------------------
    // Read path
    // -------------------------------------------------------------------------
    always_ff @(posedge axi_aclk or negedge axi_aresetn) begin
        if (!axi_aresetn) begin
            rd_ptr <= '0;
        end else if (rd_valid && rd_ready) begin
            rd_ptr <= (rd_ptr == PTR_W'(DEPTH - 1)) ? '0 : rd_ptr + 1'b1;
        end
    end

    // Read data is registered-output style: present the head entry
    assign rd_data = mem[rd_ptr];

    // -------------------------------------------------------------------------
    // Occupancy counter
    // -------------------------------------------------------------------------
    always_ff @(posedge axi_aclk or negedge axi_aresetn) begin
        if (!axi_aresetn) begin
            occ <= '0;
        end else begin
            unique case ({wr_valid & wr_ready, rd_valid & rd_ready})
                2'b10:   occ <= occ + 1'b1;   // push only
                2'b01:   occ <= occ - 1'b1;   // pop only
                default: occ <= occ;           // push+pop or idle
            endcase
        end
    end

endmodule : gaxi_skid_buffer
