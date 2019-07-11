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
    
    // tlb query fsm (0=check/bypass, 1=query, 2=request)
    reg [1:0] qstate, qstate_next;
    
    // tlb query cache
    reg tlbc_valid; // indicates query cache validity
    reg [19:0] tlbc_vaddr_hi, tlbc_paddr_hi;
    reg tlbc_miss, tlbc_invalid;
    
    wire if_adel = pc_i[1:0] != 2'd0;
    wire kseg01 = pc_i[31:30] == 2'b10;
    wire tlbc_hit = tlbc_valid && tlbc_vaddr_hi == pc_i[31:12];
    
    always @(posedge clk) begin
        if (!resetn) qstate <= 2'd0;
        else qstate <= qstate_next;
    end
    
    always @(*) begin
        if (cancel_i)   qstate_next = 2'd0;
        else begin
            case (qstate)
            2'd0:       qstate_next = (kseg01 || tlbc_hit || !valid_i) ? 2'd0 : 2'd1;
            2'd1:       qstate_next = 2'd2;
            2'd2:       qstate_next = inst_addr_ok ? 2'd0 : 2'd2;
            default:    qstate_next = 2'd0;
            endcase
        end
    end
    
    // pc is saved for tlb lookup
    reg [31:0] pc_save;
    always @(posedge clk) if (qstate_next == 2'd1) pc_save <= pc_i;
    
    assign tlb_vaddr = pc_save;
    
    always @(posedge clk) begin
        if (!resetn) tlbc_valid <= 1'b0;
        else if (tlb_write) tlbc_valid <= 1'b0;
        else if (qstate == 2'd1) tlbc_valid <= 1'b1;
    end
    
    always @(posedge clk) begin
        if (qstate == 2'd1) begin
            tlbc_vaddr_hi <= pc_save[31:12];
            tlbc_paddr_hi <= tlb_paddr[31:12];
            tlbc_miss <= tlb_miss;
            tlbc_invalid <= tlb_invalid;
        end
    end
    
    // exceptions
    // for exceptions raised in IF_req, wait until IF_wait is emptied and then output
    wire if_req_exc = qstate == 2'd0 && (if_adel || tlbc_hit && (tlbc_miss || tlbc_invalid))
                   || qstate == 2'd2 && (tlbc_miss || tlbc_invalid);
    
    // after addr is sent, the instruction enters an instruction-wait(IW) sub-stage, indicated by wait_valid
    // this design is intended to make the fetch process pipelined
    reg wait_valid;
    always @(posedge clk) begin
        if (!resetn) wait_valid <= 1'b0;
        else if (inst_addr_ok) wait_valid <= 1'b1;
        else if (wait_done && ready_i) wait_valid <= 1'b0;
    end
    
    wire ok_to_req = (!wait_valid || wait_done && ready_i);
    wire req_state = qstate == 2'd0 && (kseg01 || tlbc_hit)
                  || qstate == 2'd2;
    
    assign inst_req     = valid_i && ok_to_req && !if_req_exc && req_state;
    assign inst_addr    = qstate == 2'd0 ? (tlbc_hit ? {tlbc_paddr_hi, pc_i[11:0]} : pc_i)
                        : {tlbc_paddr_hi, pc_save[11:0]};
    
    assign ready_o      = ok_to_req && (qstate_next == 2'd1 || qstate == 2'd0 && inst_addr_ok);
    
    ////////// IF_wait //////////
    
    // IF_wait pc
    reg [31:0] ifw_pc;
    always @(posedge clk) if (inst_addr_ok) ifw_pc <= qstate == 2'd0 ? pc_i : pc_save;
    
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
            pc_o        <= wait_valid ? ifw_pc : qstate == 2'd0 ? pc_i : pc_save;
            inst_o      <= (!wait_valid && if_req_exc) ? 32'd0 : inst_saved ? inst_save : inst_rdata; // pass NOP on exception to prevent potential errors
            exc_o       <= !wait_valid && if_req_exc;
            exc_miss_o  <= (qstate == 2'd0 && tlbc_hit || qstate == 2'd2) && tlbc_miss;
            exccode_o   <= if_adel ? `EXC_ADEL : `EXC_TLBL;
        end
    end
    
    assign wait_data    = wait_valid;

endmodule