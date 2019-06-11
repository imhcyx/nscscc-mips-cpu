`include "common.vh"

module fetch_stage(
    input               clk,
    input               resetn,
    
    // memory access interface
    output              inst_req,
    output  [31:0]      inst_addr,
    input   [31:0]      inst_rdata,
    input               inst_addr_ok,
    input               inst_data_ok,
    
    output              req_state,
    
    output              ready_o,
    input               valid_i,
    input   [31:0]      pc_i,
    input               ready_i,
    output reg          valid_o,
    output reg [31:0]   pc_o,
    output reg [31:0]   inst_o
);

    wire valid, done;
    assign valid = valid_i;
    
    localparam STATE_REQ    = 2'd0;
    localparam STATE_WAIT   = 2'd1;
    localparam STATE_KEEP   = 2'd2;
    reg [1:0] state, state_next;
    
    always @(posedge clk) begin
        if (!resetn) state <= STATE_REQ;
        else state <= state_next;
    end
    
    always @(*) begin
        case(state)
            STATE_REQ:  state_next = inst_addr_ok ? STATE_WAIT : STATE_REQ;
            STATE_WAIT: state_next = inst_data_ok ? (ready_i ? STATE_REQ : STATE_KEEP) : STATE_WAIT;
            STATE_KEEP: state_next = ready_i ? STATE_REQ : STATE_KEEP;
            default:    state_next = STATE_REQ;
        endcase
    end
    
    reg [31:0] pc_save, inst_save;
    always @(posedge clk) if (inst_addr_ok) pc_save <= pc_i;
    always @(posedge clk) if (inst_data_ok) inst_save <= inst_rdata;
    
    assign inst_req     = valid && state == STATE_REQ;
    assign inst_addr    = pc_i;
    
    assign done     = state == STATE_WAIT && inst_data_ok && ready_i
                   || state == STATE_KEEP && ready_i;
    
    always @(posedge clk) begin
        if (!resetn) begin
            valid_o     <= 1'b0;
            pc_o        <= 32'd0;
            inst_o      <= 32'd0;
        end
        else if (ready_i) begin
            valid_o     <= valid_i && done; // done must imply ready_i
            pc_o        <= pc_save;
            inst_o      <= state == STATE_KEEP ? inst_save : inst_rdata;
        end
    end
    
    assign req_state    = state == STATE_REQ;
    assign ready_o      = inst_addr_ok;

endmodule