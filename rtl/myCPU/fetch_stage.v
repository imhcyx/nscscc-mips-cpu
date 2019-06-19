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
    output reg [31:0]   inst_o,
    
    // exception interface
    output reg          exc_o,
    output reg [4:0]    exccode_o,
    output reg [31:0]   badvaddr_o,
    input               cancel_i
);
    
    wire valid, done;
    
    // Note: IF is divided into two sub-stages: IF_req and IF_wait
    // IF_req sends requests to fetch instructions and detects exceptions
    // IF_wait awaits responses for sent requests
    
    ////////// IF_req //////////
    
    assign valid = valid_i;
    
    // pc is saved between the two sub-stages of IF
    reg [31:0] pc_save;
    always @(posedge clk) if (inst_addr_ok) pc_save <= pc_i;
    
    // exceptions
    // for exceptions raised in IF_req, wait until IF_wait is emptied and then output
    wire if_adel = pc_i[1:0] != 2'd0;
    wire if_req_exc = if_adel; // TODO: TLB exceptions
    
    // after addr is sent, the instruction enters an instruction-wait(IW) sub-stage, indicated by wait_valid
    // this design is intended to make the fetch process pipelined
    reg wait_valid;
    always @(posedge clk) begin
        if (!resetn) wait_valid <= 1'b0;
        else if (inst_addr_ok) wait_valid <= 1'b1;
        else if (done) wait_valid <= 1'b0;
    end
    
    wire ok_to_req = !wait_valid || ready_i;
    
    assign inst_req     = valid && ok_to_req && !if_adel;
    assign inst_addr    = pc_i;
    
    ////////// IF_wait //////////
    
    // instruction is saved in case of ID is stalled
    reg [31:0] inst_save;
    always @(posedge clk) if (inst_data_ok) inst_save <= inst_rdata;
    
    // cancel_save saves the cancel_i to indicate an instruction is cancelled
    // we have to wait for the response even though an instruction is cancelled since the bus does not support cancellation
    // only a valid instruction in IF_wait can be cancelled
    reg cancel_save;
    always @(posedge clk) begin
        if (!resetn) cancel_save <= 1'b0;
        else if (done) cancel_save <= 1'b0;
        else if (cancel_i && wait_valid) cancel_save <= 1'b1;
    end
    
    // indicates if a fetched instruction is saved due to ID stall
    // note that this flag should be cleared once the saved instruction is accepted by ID
    reg inst_saved;
    always @(posedge clk) begin
        if (!resetn) inst_saved <= 1'b0;
        else if (ready_i) inst_saved <= 1'b0;
        else if (inst_data_ok) inst_saved <= 1'b1;
    end
    
    assign done     = !inst_saved && inst_data_ok && ready_i
                   || inst_saved && ready_i
                   || if_req_exc && !wait_valid && ready_i;
    
    // Note: exception in IF_req must be passwd to ID after the instruction in IF_wait has been passed to ID
    always @(posedge clk) begin
        if (!resetn) begin
            valid_o     <= 1'b0;
            pc_o        <= 32'd0;
            inst_o      <= 32'd0;
            exc_o       <= 1'b0;
            exccode_o   <= 5'd0;
        end
        else if (ready_i) begin
            valid_o     <= (wait_valid || if_req_exc) && done && !cancel_i && !cancel_save; // done must imply ready_i
            pc_o        <= wait_valid ? pc_save : pc_i;
            inst_o      <= inst_saved ? inst_save : inst_rdata;
            exc_o       <= !wait_valid && if_req_exc;
            exccode_o   <= {5{if_adel}} & `EXC_ADEL;
        end
    end
    
    assign wait_data    = wait_valid;
    assign ready_o      = inst_addr_ok;

endmodule