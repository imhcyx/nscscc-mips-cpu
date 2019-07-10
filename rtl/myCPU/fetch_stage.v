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
    
    // tlb
    input               tlb_write,
    output  [31:0]      tlb_vaddr,
    input   [31:0]      tlb_paddr,
    input               tlb_miss,
    input               tlb_invalid,
    
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
    output reg          exc_miss_o,
    output reg [4:0]    exccode_o,
    output reg [31:0]   badvaddr_o,
    input               cancel_i
);
    
    // Note: IF is divided into two sub-stages: IF_req and IF_wait
    // IF_req sends requests to fetch instructions and detects exceptions
    // IF_wait awaits responses for sent requests
    
    ////////// IF_req //////////
    
    wire wait_done;
    
    wire if_adel = pc_i[1:0] != 2'd0;
    
    // tlb query cache
    reg tlbc_valid; // indicates query cache validity
    reg [19:0] tlbc_vaddr_hi, tlbc_paddr_hi;
    reg tlbc_miss, tlbc_invalid;
    
    wire kseg01 = pc_i[31:30] == 2'b10;
    wire tlbc_hit = tlbc_valid && tlbc_vaddr_hi == pc_i[31:12];
    
    // pc is saved for tlb lookup
    reg [31:0] pc_save;
    always @(posedge clk) if (ready_o) pc_save <= pc_i;
    reg pc_saved;
    always @(posedge clk) begin
        if (!resetn) pc_saved <= 1'b0;
        else if (cancel_i) pc_saved <= 1'b0;
        else if (inst_addr_ok) pc_saved <= 1'b0;
        else if (ready_o && !kseg01 && !tlbc_hit) pc_saved <= 1'b1;
    end
    
    assign tlb_vaddr = pc_save;
    
    always @(posedge clk) begin
        if (!resetn) tlbc_valid <= 1'b0;
        if (tlb_write) tlbc_valid <= 1'b0;
        else if (pc_saved) tlbc_valid <= 1'b1;
    end
    
    always @(posedge clk) begin
        if (pc_saved) tlbc_vaddr_hi <= pc_save[31:12];
        if (pc_saved) tlbc_paddr_hi <= tlb_paddr[31:12];
        if (pc_saved) tlbc_miss <= tlb_miss;
        if (pc_saved) tlbc_invalid <= tlb_invalid;
    end
    
    reg tlb_lookup_ok; // tlb lookup is finished
    always @(posedge clk) begin
        if (!resetn) tlb_lookup_ok <= 1'b0;
        else if (cancel_i) tlb_lookup_ok <= 1'b0;
        else if (inst_addr_ok) tlb_lookup_ok <= 1'b0;
        else if (pc_saved) tlb_lookup_ok <= 1'b1;
    end
    
    // {pc_saved, tlb_lookup_ok}
    // hit: 00
    // not hit: 00 -> 10 -> 11
    
    // exceptions
    // for exceptions raised in IF_req, wait until IF_wait is emptied and then output
    wire if_req_exc = !pc_saved && if_adel
                   || (tlb_lookup_ok || tlbc_hit) && (tlbc_miss || tlbc_invalid);
    
    // after addr is sent, the instruction enters an instruction-wait(IW) sub-stage, indicated by wait_valid
    // this design is intended to make the fetch process pipelined
    reg wait_valid;
    always @(posedge clk) begin
        if (!resetn) wait_valid <= 1'b0;
        else if (inst_addr_ok) wait_valid <= 1'b1;
        else if (wait_done && ready_i) wait_valid <= 1'b0;
    end
    
    wire ok_to_req = (!wait_valid || wait_done && ready_i);
    
    assign inst_req     = valid_i && ok_to_req && !if_req_exc && (kseg01 || tlbc_hit || tlb_lookup_ok);
    assign inst_addr    = (tlbc_hit || tlb_lookup_ok) ? {tlbc_paddr_hi, pc_save[11:0]} : pc_i;
    
    assign ready_o      = ok_to_req && !pc_saved && !if_adel && (inst_addr_ok || !kseg01 && !tlbc_hit);
    
    ////////// IF_wait //////////
    
    // IF_wait pc
    reg [31:0] ifw_pc;
    always @(posedge clk) if (inst_addr_ok) ifw_pc <= pc_saved ? pc_save : pc_i;
    
    // instruction is saved in case of ID is stalled
    reg [31:0] inst_save;
    always @(posedge clk) if (inst_data_ok) inst_save <= inst_rdata;
    
    // cancel_save saves the cancel_i to indicate an instruction is cancelled
    // we have to wait for the response even though an instruction is cancelled since the bus does not support cancellation
    // only a valid instruction in IF_wait can be cancelled
    reg cancel_save;
    always @(posedge clk) begin
        if (!resetn) cancel_save <= 1'b0;
        else if (wait_done && ready_i) cancel_save <= 1'b0;
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
    
    assign wait_done    = !inst_saved && inst_data_ok
                       || inst_saved
                       || if_req_exc && !wait_valid;
    
    // Note: exception in IF_req must be passwd to ID after the instruction in IF_wait has been passed to ID
    always @(posedge clk) begin
        if (!resetn) begin
            valid_o     <= 1'b0;
            pc_o        <= 32'd0;
            inst_o      <= 32'd0;
            exc_o       <= 1'b0;
            exc_miss_o  <= 1'b0;
            exccode_o   <= 5'd0;
        end
        else if (ready_i) begin
            valid_o     <= (wait_valid || if_req_exc) && wait_done && ready_i && !cancel_i && !cancel_save;
            pc_o        <= wait_valid ? ifw_pc : pc_saved ? pc_save : pc_i;
            inst_o      <= (!wait_valid && if_req_exc) ? 32'd0 : inst_saved ? inst_save : inst_rdata; // pass NOP on exception to prevent potential errors
            exc_o       <= !wait_valid && if_req_exc;
            exc_miss_o  <= (pc_saved || tlbc_hit) && tlbc_miss;
            exccode_o   <= {5{if_adel}} & `EXC_ADEL
                         | {5{!if_adel&&(tlbc_miss||tlbc_invalid)}} & `EXC_TLBL;
        end
    end
    
    assign wait_data    = wait_valid;

endmodule