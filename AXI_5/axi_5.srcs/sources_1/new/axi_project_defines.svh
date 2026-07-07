// Shared AXI project-wide sizing defines for both RTL and testbench.
`ifndef AXI_PROJECT_DEFINES_SVH
`define AXI_PROJECT_DEFINES_SVH

// Standalone RTL defaults used when axi_top is synthesized directly.
// Keep these small to avoid package I/O overutilization on medium devices.
`define AXI_TOP_DEFAULT_NUM_MASTERS 1
`define AXI_TOP_DEFAULT_NUM_SLAVES  1
`define AXI_TOP_DEFAULT_ADDR_WIDTH  8
`define AXI_TOP_DEFAULT_DATA_WIDTH  8
`define AXI_TOP_DEFAULT_ID_WIDTH    1

// Testbench configuration values.
`define TB_NUM_MASTERS      2
`define TB_NUM_SLAVES       2
`define TB_AXI_ADDR_WIDTH   32
`define TB_AXI_DATA_WIDTH   64
`define TB_AXI_ID_WIDTH     4

`endif