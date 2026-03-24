`ifndef ALU_PARAM_PKG
`define ALU_PARAM_PKG

`define ALU_DEBUG_MODE

package alu_param_pkg;
  parameter int  ALU_DATA_W = 32;
  parameter int  ALU_ADDR_W = 5;

  parameter int  ALU_CMD_W = 4;

  parameter logic [ALU_CMD_W-1:0] CMD_AND   = 4'b0000;
  parameter logic [ALU_CMD_W-1:0] CMD_OR    = 4'b0001;
  parameter logic [ALU_CMD_W-1:0] CMD_XOR   = 4'b0010;
  parameter logic [ALU_CMD_W-1:0] CMD_ADD   = 4'b0011;
  parameter logic [ALU_CMD_W-1:0] CMD_SUB   = 4'b0100;
  
  parameter logic [ALU_CMD_W-1:0] CMD_CUSTOM_MUL = 4'b1???;
  
  localparam int ALU_STATE_W = 4;
  
  typedef enum logic [ALU_STATE_W - 1:0] {
    ALU_IDLE         = 4'b0000,
    ALU_REQUEST      = 4'b0001,
    ALU_COMB_SAVE    = 4'b0010,
    ALU_CUSTOM_LOOP  = 4'b0011,
    ALU_CUSTOM_STEP  = 4'b0100,
    ALU_CUSTOM_SAVE  = 4'b0101
  } alu_state_e;

endpackage

`endif