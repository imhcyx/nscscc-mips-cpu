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
    output reg                  ex_fwd_ok,      // whether data is generated after ex stage
    input   [4:0]               wb_fwd_addr,    // 0 if instruction does not write
    input   [31:0]              wb_fwd_data,
    input                       wb_fwd_ok,      // whether data is generated after wb stage

    output                      ready_o,
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
    output reg [4 :0]           waddr_o
);

    wire valid, done;
    
    // data forwarding
    wire [4:0] rf_raddr1    = `GET_RS(inst_i);
    wire [4:0] rf_raddr2    = `GET_RT(inst_i);
    wire fwd_ex_raddr1_hit  = ctrl_i[`I_RS_R] && rf_raddr1 != 5'd0 && rf_raddr1 == waddr_o && valid_o;
    wire fwd_ex_raddr2_hit  = ctrl_i[`I_RT_R] && rf_raddr2 != 5'd0 && rf_raddr2 == waddr_o && valid_o;
    wire fwd_wb_raddr1_hit  = ctrl_i[`I_RS_R] && rf_raddr1 != 5'd0 && rf_raddr1 == wb_fwd_addr;
    wire fwd_wb_raddr2_hit  = ctrl_i[`I_RT_R] && rf_raddr2 != 5'd0 && rf_raddr2 == wb_fwd_addr;
    
    wire [31:0] fwd_rdata1  = fwd_ex_raddr1_hit && ex_fwd_ok ? result_o
                            : fwd_wb_raddr1_hit && wb_fwd_ok ? wb_fwd_data
                            : rdata1_i;
    wire [31:0] fwd_rdata2  = fwd_ex_raddr2_hit && ex_fwd_ok ? result_o
                            : fwd_wb_raddr2_hit && wb_fwd_ok ? wb_fwd_data
                            : rdata2_i;

    
    wire fwd_stall          = fwd_ex_raddr1_hit && !ex_fwd_ok
                            || fwd_ex_raddr2_hit && !ex_fwd_ok
                            || fwd_wb_raddr1_hit && !wb_fwd_ok
                            || fwd_wb_raddr2_hit && !wb_fwd_ok;

    assign valid = valid_i && !fwd_stall;

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
    assign alu_a = ctrl_i[`I_ALU_A_SA] ? {27'd0, `GET_SA(inst_i)} : fwd_rdata1;
    assign alu_b = ctrl_i[`I_ALU_B_IMM] ? imm_32 : fwd_rdata2;

    // multiplication
    wire [63:0] mul_res;
    reg mul_flag;
    always @(posedge clk) begin
        if (!resetn) mul_flag <= 1'b0;
        else mul_flag <= ctrl_i[`I_DO_MUL] && valid;
    end
    
    mul u_mul(
        .mul_clk(clk),
        .resetn(resetn),
        .mul_signed(ctrl_i[`I_MD_SIGN]),
        .x(fwd_rdata1),
        .y(fwd_rdata2),
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
        .x(fwd_rdata1),
        .y(fwd_rdata2),
        .s(div_s),
        .r(div_r),
        .complete(div_complete)
    );
    
    reg muldiv; // mul or div in progreses
    always @(posedge clk) begin
        if (!resetn) muldiv <= 1'b0;
        else if (mul_flag || div_complete) muldiv <= 1'b0;
        else if ((ctrl_i[`I_DO_MUL] || ctrl_i[`I_DO_DIV]) && valid) muldiv <= 1'b1;
    end
    
    // HI/LO registers
    reg [31:0] hi, lo;
    always @(posedge clk) begin
        if (mul_flag) begin
            hi <= mul_res[63:32];
            lo <= mul_res[31:0];
        end
        else if (div_complete) begin
            hi <= div_r;
            lo <= div_s;
        end
        else begin
            if (valid && ctrl_i[`I_MTHI]) hi <= fwd_rdata1;
            if (valid && ctrl_i[`I_MTLO]) lo <= fwd_rdata1;
        end
    end

    ///// memory access request /////
    wire [31:0] eff_addr = fwd_rdata1 + imm_sx;
    wire [31:0] mem_addr_aligned = eff_addr & 32'hfffffffc;
    wire [1:0] mem_byte_offset = eff_addr[1:0];
    wire [1:0] mem_byte_offsetn = ~mem_byte_offset;
    
    wire mem_read = ctrl_i[`I_MEM_R]; // && !mem_adel;
    wire mem_write = ctrl_i[`I_MEM_W]; // && !mem_ades;
    
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
        {32{ctrl_i[`I_SW]}} & fwd_rdata2 |
        {32{ctrl_i[`I_SH]}} & {fwd_rdata2[15:0], fwd_rdata2[15:0]} |
        {32{ctrl_i[`I_SB]}} & {fwd_rdata2[7:0], fwd_rdata2[7:0], fwd_rdata2[7:0], fwd_rdata2[7:0]} |
        {32{ctrl_i[`I_SWL]}} & (fwd_rdata2 >> (8 * mem_byte_offsetn)) |
        {32{ctrl_i[`I_SWR]}} & (fwd_rdata2 << (8 * mem_byte_offset));
    
    assign data_addr = mem_addr_aligned;
    
    assign data_size =
        {3{ctrl_i[`I_SW]||ctrl_i[`I_SWL]||ctrl_i[`I_SWR]||ctrl_i[`I_LW]||ctrl_i[`I_LWL]||ctrl_i[`I_LWR]}} & 3'd2 |
        {3{ctrl_i[`I_SH]||ctrl_i[`I_LH]||ctrl_i[`I_LHU]}} & 3'd1 |
        {3{ctrl_i[`I_SB]||ctrl_i[`I_LB]||ctrl_i[`I_LBU]}} & 3'd0;

    assign done     = ready_i && !fwd_stall
                   && ((ctrl_i[`I_MFHI]||ctrl_i[`I_MFLO]) && !muldiv
                   || (ctrl_i[`I_MEM_R]||ctrl_i[`I_MEM_W]) && data_addr_ok
                   || !(ctrl_i[`I_MFHI]||ctrl_i[`I_MFLO]||ctrl_i[`I_MEM_R]||ctrl_i[`I_MEM_W]));

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
            ex_fwd_ok   <= 1'b0;
        end
        else if (ready_i) begin
            valid_o     <= valid_i && done; // done must imply ready_i
            pc_o        <= pc_i;
            inst_o      <= inst_i;
            ctrl_o      <= ctrl_i;
            waddr_o     <= waddr_i;
            result_o    <= {32{ctrl_i[`I_MFHI]}} & hi
                         | {32{ctrl_i[`I_MFLO]}} & lo
                         | {32{ctrl_i[`I_LUI]}} & {imm, 16'd0}
                         | {32{ctrl_i[`I_LINK]}} & (pc_i + 32'd8)
                         | {32{!(ctrl_i[`I_MFHI]||ctrl_i[`I_MFLO]||ctrl_i[`I_LUI]||ctrl_i[`I_LINK])}} & alu_res_wire;
            eaddr_o     <= eff_addr;
            rdata2_o    <= rdata2_i;
            ex_fwd_ok   <= valid && done && ctrl_i[`I_WEX];
        end
    end

    assign ready_o  = done || !valid_i;

endmodule