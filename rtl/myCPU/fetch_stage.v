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
    
    // indicates if there is an instruction waiting for data
    output              wait_data,
    
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
    
    reg [31:0] pc_save, inst_save;
    always @(posedge clk) if (inst_addr_ok) pc_save <= pc_i;
    always @(posedge clk) if (inst_data_ok) inst_save <= inst_rdata;
    
    // after addr is sent, the instruction enters an instruction-wait(IW) sub-stage, indicated by wait_valid
    // this design is intended to make the fetch process pipelined
    reg wait_valid;
    always @(posedge clk) begin
        if (!resetn) wait_valid <= 1'b0;
        else if (inst_addr_ok) wait_valid <= 1'b1;
        else if (done) wait_valid <= 1'b0;
    end
    
    // indicates if a fetched instruction is saved due to ID stall
    // note that this flag should be cleared once the saved instruction is accepted by ID
    reg inst_saved;
    always @(posedge clk) begin
        if (!resetn) inst_saved <= 1'b0;
        else if (ready_i) inst_saved <= 1'b0;
        else if (inst_data_ok) inst_saved <= 1'b1;
    end
    
    wire ok_to_req = !wait_valid || ready_i;
    
    assign inst_req     = valid && ok_to_req;
    assign inst_addr    = pc_i;
    
    assign done     = !inst_saved && inst_data_ok && ready_i
                   || inst_saved && ready_i;
    
    always @(posedge clk) begin
        if (!resetn) begin
            valid_o     <= 1'b0;
            pc_o        <= 32'd0;
            inst_o      <= 32'd0;
        end
        else if (ready_i) begin
            valid_o     <= wait_valid && done; // done must imply ready_i
            pc_o        <= pc_save;
            inst_o      <= inst_saved ? inst_save : inst_rdata;
        end
    end
    
    assign wait_data    = wait_valid;
    assign ready_o      = inst_addr_ok;

endmodule