`timescale 1ns/1ps

import alu_param_pkg::*;

module tb_alu;
    localparam CLK_PERIOD = 10ns;

    logic [ALU_DATA_W-1:0] op0_i;
    logic [ALU_DATA_W-1:0] op1_i;
    
    logic [ALU_ADDR_W-1:0] addr_i;
    logic [ALU_CMD_W-1:0]  cmd_i;

    logic [ALU_DATA_W-1:0] res_o;
    logic [ALU_ADDR_W-1:0] addr_o;
    logic                  flag_o;

    logic clk;
    logic rst_n;
    logic req_i;
    logic busy_o;
    logic ready_o;
    
    `ifdef ALU_DEBUG_MODE
        alu_state_e state_ff_debug, state_next_debug;
    `endif


    alu dut (
        .op0_i      (op0_i),
        .op1_i      (op1_i),
        .addr_i     (addr_i),
        .cmd_i      (cmd_i),
    
        .res_o      (res_o),
        .addr_o     (addr_o),
        .flag_o     (flag_o),
    
        .clk        (clk),
        .rst_n      (rst_n),
        .req_i      (req_i),
        .busy_o     (busy_o),
        .ready_o    (ready_o)
`ifdef ALU_DEBUG_MODE
        ,
        .state_ff_debug  (state_ff_debug),
        .state_next_debug(state_next_debug)
`endif
    );

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end


    task reset();
        rst_n = 'b0;
        req_i  = 'b0;
        op0_i  = 'b0;
        op1_i  = 'b0;
        addr_i = 'b0;
        cmd_i  = 'b0;
        repeat (2) @(posedge clk);
        rst_n = 1;
        repeat (2) @(posedge clk);
    endtask

    task send_cmd(input logic [ALU_DATA_W-1:0] a,
                  input logic [ALU_DATA_W-1:0] b,
                  input logic [ALU_ADDR_W-1:0] adr,
                  input logic [ALU_CMD_W-1:0]  cmd);
        @(posedge clk);
        req_i <= 1;
        op0_i <= a;
        op1_i <= b;
        addr_i<= adr;
        cmd_i <= cmd;
        @(posedge clk);
        req_i <= 0;
    endtask

  
    task wait_ready();
        @(posedge ready_o); 
        @(posedge clk);
    endtask

    task check_comb(input logic [ALU_DATA_W-1:0] expected_res,
                    input logic [ALU_ADDR_W-1:0] expected_addr = '0,
                    input logic expected_flag = 0);
        if (res_o !== expected_res) begin
            $error("res_o mismatch: expected %h, got %h", expected_res, res_o);
        end
        if (addr_o !== expected_addr) begin
            $error("addr_o mismatch: expected %h, got %h", expected_addr, addr_o);
        end
        if (flag_o !== expected_flag) begin
            $error("flag_o mismatch: expected %b, got %b", expected_flag, flag_o);
        end
    endtask

    task check_custom(input logic [ALU_DATA_W-1:0] a,
                      input logic [ALU_DATA_W-1:0] b,
                      input logic [ALU_CMD_W-1:0]  cmd,
                      input logic [ALU_ADDR_W-1:0] addr);
        logic [ALU_DATA_W-1:0] expected;
        int count;
        count = cmd[ALU_CMD_W-2:0];  
        expected = (a + b) * count;        
        if (res_o !== expected) begin
            $error("CUSTOM MUL: expected %h, got %h", expected, res_o);
        end else begin
            $display("CUSTOM MUL OK: %d * %d = %d", a, count, res_o);
        end
    endtask

    initial begin
        $display("===== START TEST =====");

        reset();

        // ----------------------------------------------------------
        // 义耱 1: AND
        $display("Test 1: AND");
        send_cmd(8'b00001111, 8'b11111000, 4'h1, CMD_AND);
        wait_ready();
        check_comb(8'b00001111 & 8'b11111000, 4'h1, 0);

        // ----------------------------------------------------------
        // 义耱 2: OR
        $display("Test 2: OR");
        send_cmd(8'b00001111, 8'b11111000, 4'h2, CMD_OR);
        wait_ready();
        check_comb(8'b00001111 | 8'b11111000, 4'h2, 0);

        // ----------------------------------------------------------
        // 义耱 3: XOR
        $display("Test 3: XOR");
        send_cmd(8'b00001111, 8'b11111000, 4'h3, CMD_XOR);
        wait_ready();
        check_comb(8'b00001111 ^ 8'b11111000, 4'h3, 0);

        // ----------------------------------------------------------
        // 义耱 4: ADD
        $display("Test 4: ADD");
        send_cmd(8'b00001011, 8'b00000001, 4'h4, CMD_ADD);
        wait_ready();
        check_comb(8'b00001100, 4'h4, 0);

        // ----------------------------------------------------------
        // 义耱 5: SUB
        $display("Test 5: SUB");
        send_cmd(8'b00001010, 8'b00000001, 4'h5, CMD_SUB);
        wait_ready();
        check_comb(8'b00001001, 4'h5, 0);

        // ----------------------------------------------------------
        // 义耱 6: CUSTOM count = 3
        $display("Test 6: CUSTOM count = 3");
        send_cmd(8'b00000001, 8'b00000000, 4'h6, {1'b1, 3'b011});  
        wait_ready();
        check_custom(8'b00000001, 8'b00000000, {1'b1, 3'b011}, 4'h6);

        // ----------------------------------------------------------
        // 义耱 7: CUSTOM count = 0
        $display("Test 7: CUSTOM count = 0");
        send_cmd(8'b00000010, 8'b00000001, 4'h7, {1'b1, 3'b000});
        wait_ready();
        check_custom(8'b00000010, 8'b00000001, {1'b1, 3'b000}, 4'h7);
        
        // ----------------------------------------------------------
        // 义耱 8: CUSTOM count = 4
        $display("Test 8: CUSTOM count = 4");
        send_cmd(8'b00000010, 8'b00000001, 4'h7, {1'b1, 3'b100});
        wait_ready();
        check_custom(8'b00000010, 8'b00000001, {1'b1, 3'b100}, 4'h7);

        $display("===== ALL TESTS PASSED =====");
        $finish;
    end

endmodule