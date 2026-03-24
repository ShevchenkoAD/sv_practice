import alu_param_pkg::*;

module alu (
`ifdef ALU_DEBUG_MODE
  output alu_state_e state_ff_debug,
  output alu_state_e state_next_debug,
`endif

  input  logic [ALU_DATA_W-1:0] op0_i,
  input  logic [ALU_DATA_W-1:0] op1_i,

  input  logic [ALU_ADDR_W-1:0] addr_i,
  input  logic [ALU_CMD_W -1:0] cmd_i,
  
  output logic [ALU_DATA_W-1:0] res_o,
  output logic [ALU_ADDR_W-1:0] addr_o,
  output logic                  flag_o,
  
  input  logic clk, 
  input  logic rst_n, 
  input  logic req_i,
  output logic busy_o,
  output logic ready_o
);

    alu_state_e state_ff, state_next; 
    
`ifdef ALU_DEBUG_MODE   
    assign state_ff_debug = state_ff;
    assign state_next_debug = state_next;
`endif

    logic [ALU_DATA_W-1:0] res_o_ff,  res_o_next; 
    logic [ALU_ADDR_W-1:0] addr_o_ff, addr_o_next;
    logic                  flag_o_ff, flag_o_next;
    logic busy_o_ff,  busy_o_next;
    logic ready_o_ff, ready_o_next;
    
    logic [ALU_DATA_W-1:0] op0_i_ff,  op0_i_next;
    logic [ALU_DATA_W-1:0] op1_i_ff,  op1_i_next;
    logic [ALU_ADDR_W-1:0] addr_i_ff, addr_i_next;
    logic [ALU_CMD_W -1:0] cmd_i_ff,  cmd_i_next;
    
    assign res_o   = res_o_ff;
    assign addr_o  = addr_o_ff;
    assign flag_o  = flag_o_ff;
    assign busy_o  = busy_o_ff;
    assign ready_o = ready_o_ff;

    logic [ALU_CMD_W-2:0]  counter_ff, counter_next;
    logic [ALU_DATA_W-1:0] result_ff,  result_next;

    always_ff @(posedge clk or negedge rst_n) begin : proc_state_sync
      if (!rst_n) begin
        state_ff <= ALU_IDLE;
      end else begin
        state_ff <= state_next;
      end
    end
    
    always_ff @(posedge clk or negedge rst_n) begin : proc_ff_sync
          if (!rst_n) begin
            res_o_ff   <= 'b0;
            addr_o_ff  <= 'b0;
            flag_o_ff  <= 'b0;
            busy_o_ff  <= 'b0;
            ready_o_ff <= 'b0;
            
            op0_i_ff  <= 'b0;
            op1_i_ff  <= 'b0;
            addr_i_ff <= 'b0;
            cmd_i_ff  <= 'b0;
            
            counter_ff <= 'b0;
            result_ff  <= 'b0;
          end else begin
            res_o_ff   <= res_o_next;
            addr_o_ff  <= addr_o_next;
            flag_o_ff  <= flag_o_next;
            busy_o_ff  <= busy_o_next;
            ready_o_ff <= ready_o_next;
            
            op0_i_ff  <= op0_i_next;
            op1_i_ff  <= op1_i_next;
            addr_i_ff <= addr_i_next;
            cmd_i_ff  <= cmd_i_next;
            
            counter_ff <= counter_next;
            result_ff  <= result_next;
          end
        end
    
    always_comb begin : proc_state_ctrl 
        state_next = state_ff;
        
        unique case (state_ff) 
            ALU_IDLE: begin
                if (req_i) state_next = ALU_REQUEST;
            end
            ALU_REQUEST: begin
                 casez (cmd_i_ff)
                   CMD_CUSTOM_MUL: state_next = ALU_CUSTOM_LOOP;
                   default:        state_next = ALU_COMB_SAVE;
               endcase      
            end
            ALU_COMB_SAVE: begin
                state_next = ALU_IDLE;
            end
            ALU_CUSTOM_LOOP: begin
                if (counter_ff == 0) 
                    state_next = ALU_CUSTOM_SAVE;
                else 
                    state_next = ALU_CUSTOM_STEP;
            end
            ALU_CUSTOM_STEP: begin
                state_next = ALU_CUSTOM_LOOP;
            end                        
            ALU_CUSTOM_SAVE: begin
                state_next = ALU_IDLE;
            end 
            default: begin
            end
        endcase
    end

    always_comb begin : proc_out_ctrl 
        res_o_next   = res_o_ff;
        addr_o_next  = addr_o_ff;
        flag_o_next  = flag_o_ff;
        busy_o_next  = busy_o_ff;
        ready_o_next = ready_o_ff;
        
        op0_i_next  = op0_i_ff;
        op1_i_next  = op1_i_ff;
        addr_i_next = addr_i_ff;
        cmd_i_next  = cmd_i_ff;     
        
        counter_next = counter_ff;
        result_next  = result_ff;
          
        unique case (state_ff) 
            ALU_IDLE: begin
                busy_o_next  = 'b0;
                ready_o_next = 'b0;  
                
                op0_i_next  = op0_i;
                op1_i_next  = op1_i;
                addr_i_next = addr_i;
                cmd_i_next  = cmd_i; 
            end
            ALU_REQUEST: begin
                busy_o_next  = 'b1;
                ready_o_next = 'b0;      
                
                result_next  = 'b0;
                counter_next = unsigned'(cmd_i_ff[ALU_CMD_W-2:0]);  
            end
            ALU_COMB_SAVE: begin    
                logic   [ALU_DATA_W-1:0] and_res;
                logic   [ALU_DATA_W-1:0] or_res;
                logic   [ALU_DATA_W-1:0] xor_res;
                logic   [ALU_DATA_W-1:0] add_res;
                logic   [ALU_DATA_W-1:0] sub_res;
            
                busy_o_next  = 'b0;
                ready_o_next = 'b1;
                addr_o_next  = addr_i_ff;
            
                and_res  = op0_i_ff & op1_i_ff;
                or_res   = op0_i_ff | op1_i_ff;
                xor_res  = op0_i_ff ^ op1_i_ff;
                add_res  = signed'(op0_i_ff) + signed'(op1_i_ff);
                sub_res  = signed'(op0_i_ff) - signed'(op1_i_ff);
                
                unique case (cmd_i_ff)
                    CMD_AND: begin
                        res_o_next   = and_res;
                        flag_o_next  = 'b0;
                    end
                    CMD_OR:  begin
                        res_o_next   = or_res;
                        flag_o_next  = 'b0;
                    end
                    CMD_XOR: begin
                        res_o_next   = xor_res;
                        flag_o_next  = 'b0;
                    end
                    CMD_ADD: begin
                        res_o_next   = add_res;
                        flag_o_next  = 'b0;
                    end
                    CMD_SUB: begin
                        res_o_next   = sub_res;
                        flag_o_next  = 'b0;
                    end
                    default: begin
                    end
                endcase       
            end
            ALU_CUSTOM_LOOP: begin
                busy_o_next  = 'b1;
                ready_o_next = 'b0;      
            end
            ALU_CUSTOM_STEP: begin
                logic [ALU_DATA_W-1:0] inter_value;
            
                inter_value = unsigned'(op0_i_ff) + unsigned'(op1_i_ff);
            
                busy_o_next  = 'b1;
                ready_o_next = 'b0;  
                
                result_next   = unsigned'(result_ff) + unsigned'(inter_value);    
                counter_next  = unsigned'(counter_ff - 1'b1);  
            end                        
            ALU_CUSTOM_SAVE: begin
                busy_o_next  = 'b0;
                ready_o_next = 'b1;   
                addr_o_next  = addr_i_ff;
                
                res_o_next  = result_ff;
                flag_o_next = 'b0;       
            end 
            default: begin
            end
        endcase
    end

endmodule