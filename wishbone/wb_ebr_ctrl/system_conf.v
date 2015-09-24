`define LATTICE_FAMILY "iCE40"
`define LATTICE_FAMILY_iCE40
`define LATTICE_DEVICE ""
`ifndef SYSTEM_CONF
`define SYSTEM_CONF
`timescale 1ns / 100 ps
`define CFG_EBA_RESET 32'h0
`define CFG_EBR_POSEDGE_REGISTER_FILE
`define MULT_ENABLE
`define CFG_MC_MULTIPLY_ENABLED
`define SHIFT_ENABLE
`define CFG_MC_BARREL_SHIFT_ENABLED
`define CFG_SIGN_EXTEND_ENABLED
//`define CFG_DRAM_ENABLED
//`define CFG_DRAM_BASE_ADDRESS 32'h1000
//`define CFG_DRAM_LIMIT 32'h1fff
//`define CFG_DRAM_INIT_FILE_FORMAT "hex"
//`define CFG_DRAM_INIT_FILE "none"
`define CFG_IROM_LOCK
`define CFG_DRAM_LOCK
`define ADDRESS_LOCK
`define LM32_I_PC_WIDTH 13
`define ADDRESS_LOCK
`define slave_passthruS_WB_DAT_WIDTH 32
`define S_WB_SEL_WIDTH 4
`define slave_passthruS_WB_ADR_WIDTH 32
`define ADDRESS_LOCK
`define imemEBR_WB_DAT_WIDTH 32
`define imemINIT_FILE_NAME "imem.mem"
`define imemINIT_FILE_FORMAT "hex"
`endif // SYSTEM_CONF
