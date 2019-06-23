`include "common.vh"

module execute_stage(
    input                       clk,
    input                       resetn,

    // memory access interface
    output                      data_req,
    output                      data_wr,
    output  [3 :0]              data_wstrb,
    output  [31:0]              data_addr,
    output  [2 :0]              data_size,
    output  [31:0]              data_wdata,
    input                       data_addr_ok,

    // data forwarding
    output  [4 :0]              fwd_addr,
    output  [31:0]              fwd_data,
    output                      fwd_ok,      // whether data is generated after ex stage
    
    // mtc0/mfc0
    output                      cp0_w,
    output  [31:0]              cp0_wdata,
    input   [31:0]              cp0_rdata,
    output  [7 :0]              cp0_addr,

    output                      done_o,
    input                       valid_i,
    input   [31:0]              pc_i,
    input   [31:0]              inst_i,
    input   [`I_MAX-1:0]        ctrl_i,
    input   [31:0]              rdata1_i,
    input   [31:0]              rdata2_i,
    input   [4 :0]              waddr_i,
    input                       ready_i,
    output reg                  valid_o,
    output reg [31:0]           pc_o,
    output reg [31:0]           inst_o,
    output reg [`I_MAX-1:0]     ctrl_o,
    output reg [31:0]           result_o,
    output reg [31:0]           eaddr_o,
    output reg [31:0]           rdata2_o,
    output reg [4 :0]           waddr_o,
    
    // exception interface
    input                       exc_i,
    input   [4 :0]              exccode_i,
    input                       bd_i,
    input                       eret_i,
    output                      commit,
    output  [4 :0]              commit_code,
    output                      commit_bd,
    output  [31:0]              commit_epc,
    output  [31:0]              commit_bvaddr,
    output                      commit_eret
);

    wire valid;

    assign valid = valid_i && !exc_i;

    // imm extension
    wire [15:0] imm = `GET_IMM(inst_i);
    wire [31:0] imm_sx = {{16{imm[15]}}, imm};
    wire [31:0] imm_zx = {16'd0, imm};
    wire [31:0] imm_32 = ctrl_i[`I_IMM_SX] ? imm_sx : imm_zx;
    
    // ALU operation
    wire [10:0] alu_op = ctrl_i[10:0];
    
    // ALU module
    wire [31:0] alu_a, alu_b, alu_res_wire;
    wire alu_of;
    alu alu_instance(
        .A          (alu_a),
        .B          (alu_b),
        .ALUop      (alu_op),
        .CarryOut   (),
        .Overflow   (alu_of),
        .Zero       (),
        .Result     (alu_res_wire)
    );

    // select operand sources
    assign alu_a = ctrl_i[`I_ALU_A_SA] ? {27'd0, `GET_SA(inst_i)} : rdata1_i;
    assign alu_b = ctrl_i[`I_ALU_B_IMM] ? imm_32 : rdata2_i;

    // multiplication
    // the multiplier is divided into 3 stages
    wire [63:0] mul_res;
    reg [1:0] mul_flag;
    always @(posedge clk) begin
        if (!resetn) mul_flag <= 2'b00;
        else if (ctrl_i[`I_DO_DIV] && valid) mul_flag <= 2'b00;
        else mul_flag <= {mul_flag[0], ctrl_i[`I_DO_MUL] && valid};
    end
    
    mul u_mul(
        .mul_clk(clk),
        .resetn(resetn),
        .mul_signed(ctrl_i[`I_MD_SIGN]),
        .x(rdata1_i),
        .y(rdata2_i),
        .result(mul_res)
    );
    
    // division
    wire [31:0] div_s, div_r;
    wire div_complete;
    div u_div(
        .div_clk(clk),
        .resetn(resetn),
        .div(ctrl_i[`I_DO_DIV] && valid),
        .div_signed(ctrl_i[`I_MD_SIGN]),
        .x(rdata1_i),
        .y(rdata2_i),
        .s(div_s),
        .r(div_r),
        .complete(div_complete),
        .cancel(ctrl_i[`I_DO_MUL] && valid)
    );
    
    reg muldiv; // mul or div in progreses
    always @(posedge clk) begin
        if (!resetn) muldiv <= 1'b0;
        else if (mul_flag[1] || div_complete) muldiv <= 1'b0;
        else if ((ctrl_i[`I_DO_MUL] || ctrl_i[`I_DO_DIV]) && valid) muldiv <= 1'b1;
    end
    
    // HI/LO registers
    reg [31:0] hi, lo;
    always @(posedge clk) begin
        if (mul_flag[1]) begin
            hi <= mul_res[63:32];
            lo <= mul_res[31:0];
        end
        else if (div_complete) begin
            hi <= div_r;
            lo <= div_s;
        end
        else begin
            if (valid && ctrl_i[`I_MTHI]) hi <= rdata1_i;
            if (valid && ctrl_i[`I_MTLO]) lo <= rdata1_i;
        end
    end
    
    // mtc0/mfc0
    assign cp0_w = valid && ctrl_i[`I_MTC0];
    assign cp0_wdata = rdata2_i;
    assign cp0_addr = {`GET_RD(inst_i), inst_i[2:0]};

    ///// memory access request /////
    wire [31:0] eff_addr = rdata1_i + imm_sx;
    wire [31:0] mem_addr_aligned = eff_addr & 32'hfffffffc;
    wire [1:0] mem_byte_offset = eff_addr[1:0];
    wire [1:0] mem_byte_offsetn = ~mem_byte_offset;
    
    wire mem_adel   = ctrl_i[`I_LW] && eff_addr[1:0] != 2'd0
                   || (ctrl_i[`I_LH] || ctrl_i[`I_LHU]) && eff_addr[0] != 1'd0;
    wire mem_ades   = ctrl_i[`I_SW] && eff_addr[1:0] != 2'd0
                   || ctrl_i[`I_SH] && eff_addr[0] != 1'd0;
    
    wire mem_read = ctrl_i[`I_MEM_R] && !mem_adel;
    wire mem_write = ctrl_i[`I_MEM_W] && !mem_ades;
    
    assign data_req = valid && (mem_read || mem_write);
    assign data_wr = mem_write;
    
    // mem write mask
    assign data_wstrb =
        {4{ctrl_i[`I_SW]}} & 4'b1111 |
        {4{ctrl_i[`I_SH]}} & (4'b0011 << mem_byte_offset) |
        {4{ctrl_i[`I_SB]}} & (4'b0001 << mem_byte_offset) |
        {4{ctrl_i[`I_SWL]}} & (4'b1111 >> mem_byte_offsetn) |
        {4{ctrl_i[`I_SWR]}} & (4'b1111 << mem_byte_offset);
    
    // mem write data
    assign data_wdata =
        {32{ctrl_i[`I_SW]}} & rdata2_i |
        {32{ctrl_i[`I_SH]}} & {rdata2_i[15:0], rdata2_i[15:0]} |
        {32{ctrl_i[`I_SB]}} & {rdata2_i[7:0], rdata2_i[7:0], rdata2_i[7:0], rdata2_i[7:0]} |
        {32{ctrl_i[`I_SWL]}} & (rdata2_i >> (8 * mem_byte_offsetn)) |
        {32{ctrl_i[`I_SWR]}} & (rdata2_i << (8 * mem_byte_offset));
    
    assign data_addr = mem_addr_aligned;
    
    assign data_size =
        {3{ctrl_i[`I_SW]||ctrl_i[`I_SWL]||ctrl_i[`I_SWR]||ctrl_i[`I_LW]||ctrl_i[`I_LWL]||ctrl_i[`I_LWR]}} & 3'd2 |
        {3{ctrl_i[`I_SH]||ctrl_i[`I_LH]||ctrl_i[`I_LHU]}} & 3'd1 |
        {3{ctrl_i[`I_SB]||ctrl_i[`I_LB]||ctrl_i[`I_LBU]}} & 3'd0;

    // mem_exc_r saves the state of AdES and AdEL
    // alu_of_r saves the ALU overflow state
    // only intended to enhance timing for critical path
    reg mem_exc_r, alu_of_r;
    always @(posedge clk) mem_exc_r <= valid && (mem_adel || mem_ades);
    always @(posedge clk) alu_of_r <= valid && ctrl_i[`I_EXC_OF] && alu_of;
    
    reg alu_of_ready; // for ADD/SUB instruction, wait 1 extra cycle for alu_of_r to be filled
    always @(posedge clk) alu_of_ready <= valid && ctrl_i[`I_EXC_OF];

    assign done_o   = ((ctrl_i[`I_MFHI]||ctrl_i[`I_MFLO]||ctrl_i[`I_MTHI]||ctrl_i[`I_MTLO]) && !muldiv
                   || (ctrl_i[`I_MEM_R]||ctrl_i[`I_MEM_W]) && (data_addr_ok)
                   || mem_exc_r
                   || ctrl_i[`I_EXC_OF] && alu_of_ready
                   || !(ctrl_i[`I_MFHI]||ctrl_i[`I_MFLO]||ctrl_i[`I_MTHI]||ctrl_i[`I_MTLO]||ctrl_i[`I_MEM_R]||ctrl_i[`I_MEM_W]||ctrl_i[`I_EXC_OF]));

    // exceptions
    wire exc = alu_of_r || mem_exc_r;
    wire [4:0] exccode = {5{alu_of_r}} & `EXC_OV
                       | {5{mem_adel}} & `EXC_ADEL
                       | {5{mem_ades}} & `EXC_ADES;
    assign commit = valid && exc || valid_i && exc_i;
    assign commit_code = valid && exc ? exccode : exccode_i;
    assign commit_bd = bd_i;
    assign commit_epc = bd_i ? pc_i - 32'd4 : pc_i;
    assign commit_bvaddr = (mem_adel || mem_ades) ? eff_addr : pc_i;
    assign commit_eret = eret_i;

    assign fwd_addr = {5{valid_i}} & waddr_i;
    assign fwd_data = {32{ctrl_i[`I_MFHI]}} & hi
                    | {32{ctrl_i[`I_MFLO]}} & lo
                    | {32{ctrl_i[`I_LUI]}} & {imm, 16'd0}
                    | {32{ctrl_i[`I_LINK]}} & (pc_i + 32'd8)
                    | {32{ctrl_i[`I_MFC0]}} & cp0_rdata
                    | {32{!(ctrl_i[`I_MFHI]||ctrl_i[`I_MFLO]||ctrl_i[`I_LUI]||ctrl_i[`I_LINK]||ctrl_i[`I_MFC0])}} & alu_res_wire;
    assign fwd_ok   = valid && done_o && ready_i && ctrl_i[`I_WEX];

    always @(posedge clk) begin
        if (!resetn) begin
            valid_o     <= 1'b0;
            pc_o        <= 32'd0;
            inst_o      <= 32'd0;
            ctrl_o      <= `I_MAX'd0;
            waddr_o     <= 5'd0;
            result_o    <= 32'd0;
            eaddr_o     <= 32'd0;
            rdata2_o    <= 32'd0;
        end
        else if (ready_i) begin
            valid_o     <= valid_i && done_o && ready_i && !exc_i && !exc;
            pc_o        <= pc_i;
            inst_o      <= inst_i;
            ctrl_o      <= ctrl_i;
            waddr_o     <= waddr_i;
            result_o    <= fwd_data;
            eaddr_o     <= eff_addr;
            rdata2_o    <= rdata2_i;
        end
    end

endmodule