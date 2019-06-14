`timescale 10ns / 1ns

`include "common.vh"

module mips_cpu(
    input               clk,
    input               resetn,            //low active

    input   [5 :0]      int,

    output              inst_req,
    output  [31:0]      inst_addr,
    input   [31:0]      inst_rdata,
    input               inst_addr_ok,
    input               inst_data_ok,
    output              data_req,
    output              data_wr,
    output  [3 :0]      data_wstrb,
    output  [31:0]      data_addr,
    output  [2 :0]      data_size,
    output  [31:0]      data_wdata,
    input   [31:0]      data_rdata,
    input               data_addr_ok,
    input               data_data_ok,

    //debug interface
    output  [31:0]      debug_wb_pc,
    output  [3 :0]      debug_wb_rf_wen,
    output  [4 :0]      debug_wb_rf_wnum,
    output  [31:0]      debug_wb_rf_wdata
);
    
    //////////////////// IF ////////////////////
    
    wire if_valid, if_ready;
    wire [31:0] if_pc;
    wire if_id_valid, id_if_ready;
    wire [31:0] if_id_pc, if_id_inst;
    
    wire if_wait_data;
    wire branch, branch_ack;
    wire [31:0] branch_pc;
    
    reg [31:0] pc;
    
    always @(posedge clk) begin
        if (!resetn) pc <= `VEC_RESET;
        else if (if_ready) pc <= if_pc + 32'd4;
        else pc <= if_pc;
    end
    
    assign branch_ack = if_wait_data;
    
    assign if_valid = 1'b1; //TODO
    assign if_pc = (branch && branch_ack) ? branch_pc : pc; //TODO
    
    fetch_stage fetch(
        .clk            (clk),
        .resetn         (resetn),
        .inst_req       (inst_req),
        .inst_addr      (inst_addr),
        .inst_rdata     (inst_rdata),
        .inst_addr_ok   (inst_addr_ok),
        .inst_data_ok   (inst_data_ok),
        .wait_data      (if_wait_data),
        .ready_o        (if_ready),
        .valid_i        (if_valid),
        .pc_i           (if_pc),
        .ready_i        (id_if_ready),
        .valid_o        (if_id_valid),
        .pc_o           (if_id_pc),
        .inst_o         (if_id_inst)
    );
    
    //////////////////// ID ////////////////////
    
    // reg file
    wire [4:0] rf_raddr1, rf_raddr2, rf_waddr;
    wire [31:0] rf_rdata1, rf_rdata2, rf_wdata;
    wire rf_wen;
    reg_file rf(
       .clk         (clk),
	   .waddr      (rf_waddr),
	   .raddr1     (rf_raddr1),
	   .raddr2     (rf_raddr2),
	   .wen        (rf_wen),
	   .wdata      (rf_wdata),
	   .rdata1     (rf_rdata1),
	   .rdata2     (rf_rdata2)
    );
    
    wire [4:0] ex_fwd_addr, wb_fwd_addr;
    wire [31:0] ex_fwd_data, wb_fwd_data;
    wire ex_fwd_ok, wb_fwd_ok;
    
    wire id_ex_valid, ex_id_ready;
    wire [31:0] id_ex_pc, id_ex_inst;
    wire [`I_MAX-1:0] id_ex_ctrl;
    wire [31:0] id_ex_rdata1, id_ex_rdata2;
    wire [4:0] id_ex_waddr;
    
    decode_stage decode(
        .clk            (clk),
        .resetn         (resetn),
        .rf_raddr1      (rf_raddr1),
        .rf_raddr2      (rf_raddr2),
        .rf_rdata1      (rf_rdata1),
        .rf_rdata2      (rf_rdata2),
        .branch         (branch),
        .branch_ack     (branch_ack),
        .branch_pc      (branch_pc),
        .ex_fwd_addr    (ex_fwd_addr),
        .ex_fwd_data    (ex_fwd_data),
        .ex_fwd_ok      (ex_fwd_ok),
        .wb_fwd_addr    (wb_fwd_addr),
        .wb_fwd_data    (wb_fwd_data),
        .wb_fwd_ok      (wb_fwd_ok),
        .ready_o        (id_if_ready),
        .valid_i        (if_id_valid),
        .pc_i           (if_id_pc),
        .inst_i         (if_id_inst),
        .ready_i        (ex_id_ready),
        .valid_o        (id_ex_valid),
        .pc_o           (id_ex_pc),
        .inst_o         (id_ex_inst),
        .ctrl_o         (id_ex_ctrl),
        .rdata1_o       (id_ex_rdata1),
        .rdata2_o       (id_ex_rdata2),
        .waddr_o        (id_ex_waddr)
    );
    
    //////////////////// EX ////////////////////
    
    wire ex_wb_valid, wb_ex_ready;
    wire [31:0] ex_wb_pc, ex_wb_inst;
    wire [`I_MAX-1:0] ex_wb_ctrl;
    wire [31:0] ex_wb_result, ex_wb_eaddr, ex_wb_rdata2;
    wire [4:0] ex_wb_waddr;
    
    execute_stage execute(
        .clk            (clk),
        .resetn         (resetn),
        .data_req       (data_req),
        .data_wr        (data_wr),
        .data_wstrb     (data_wstrb),
        .data_addr      (data_addr),
        .data_size      (data_size),
        .data_wdata     (data_wdata),
        .data_addr_ok   (data_addr_ok),
        .ex_fwd_ok      (ex_fwd_ok),
        .wb_fwd_addr    (wb_fwd_addr),
        .wb_fwd_data    (wb_fwd_data),
        .wb_fwd_ok      (wb_fwd_ok),
        .ready_o        (ex_id_ready),
        .valid_i        (id_ex_valid),
        .pc_i           (id_ex_pc),
        .inst_i         (id_ex_inst),
        .ctrl_i         (id_ex_ctrl),
        .rdata1_i       (id_ex_rdata1),
        .rdata2_i       (id_ex_rdata2),
        .waddr_i        (id_ex_waddr),
        .ready_i        (wb_ex_ready),
        .valid_o        (ex_wb_valid),
        .pc_o           (ex_wb_pc),
        .inst_o         (ex_wb_inst),
        .ctrl_o         (ex_wb_ctrl),
        .result_o       (ex_wb_result),
        .eaddr_o        (ex_wb_eaddr),            
        .rdata2_o       (ex_wb_rdata2),
        .waddr_o        (ex_wb_waddr)   
    );
    
    assign ex_fwd_addr  = {5{ex_wb_valid}} & ex_wb_waddr;
    assign ex_fwd_data  = ex_wb_result;
    
    //////////////////// WB ////////////////////
    
    wire wb_valid;
    wire [4:0] wb_waddr;
    wire [31:0] wb_result;
    
    writeback_stage writeback(
        .clk            (clk),
        .resetn         (resetn),
        .data_rdata     (data_rdata),
        .data_data_ok   (data_data_ok),
        .rf_wen         (rf_wen),
        .rf_waddr       (rf_waddr),
        .rf_wdata       (rf_wdata),
        .wb_fwd_ok      (wb_fwd_ok),
        .ready_o        (wb_ex_ready),
        .valid_i        (ex_wb_valid),
        .pc_i           (ex_wb_pc),
        .inst_i         (ex_wb_inst),
        .ctrl_i         (ex_wb_ctrl),
        .result_i       (ex_wb_result),
        .eaddr_i        (ex_wb_eaddr), 
        .rdata2_i       (ex_wb_rdata2),
        .waddr_i        (ex_wb_waddr),
        .valid_o        (wb_valid),
        .waddr_o        (wb_waddr),
        .result_o       (wb_result)
    );
    
    assign wb_fwd_addr  = {5{wb_valid}} & wb_waddr;
    assign wb_fwd_data  = wb_result;
    
    assign debug_wb_pc          = ex_wb_pc;
    assign debug_wb_rf_wen      = {4{rf_wen}};
    assign debug_wb_rf_wnum     = rf_waddr;
    assign debug_wb_rf_wdata    = rf_wdata;

endmodule

