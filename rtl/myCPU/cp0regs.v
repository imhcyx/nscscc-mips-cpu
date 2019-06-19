`include "common.vh"

module cp0regs(
    input               clk,
    input               resetn,
    
    input   [5 :0]      int,
    output              int_sig, // indicates unmasked interrupts
    
    // mtc0/mfc0
    input               mtc0,
    input   [31:0]      mtc0_data,
    output  [31:0]      mfc0_data,
    input   [7 :0]      addr, // rd, sel
    
    // exception commit
    input               commit_exc, // also valid when commit_eret is valid
    input   [4 :0]      commit_code,
    input               commit_bd,
    input   [31:0]      commit_epc,
    input   [31:0]      commit_bvaddr,
    input               commit_eret,
    
    output  [31:0]      status,
    output  [31:0]      cause,
    output reg [31:0]   epc
);

    wire [5:0] hw_int;
    reg timer_int;
    
    assign hw_int[5] = int[5] || timer_int;
    assign hw_int[4:0] = int[4:0];

    // this indicates an exception is to commit, distinguished from an ERET instruction
    wire exception_commit = commit_exc && !commit_eret;
    
    // BadVAddr (8, 0)
    reg [31:0] badvaddr;
    always @(posedge clk) begin
        if (exception_commit) badvaddr <= commit_bvaddr;
    end
    
    // Count (9, 0)
    reg [31:0] count;
    reg tick;
    
    wire count_write = mtc0 && addr == `CP0_COUNT;
    always @(posedge clk) begin
        if (!resetn) tick <= 1'b0;
        else tick <= ~tick;
        // Count
        if (count_write) count <= mtc0_data;
        else if (tick) count <= count + 32'd1;
    end
    
    // Compare (11, 0)
    reg [31:0] compare;
    
    wire compare_write = mtc0 && addr == `CP0_COMPARE;
    always @(posedge clk) begin
        if (compare_write) compare <= mtc0_data;
    end
    
    // Status (12, 0)
    reg status_cu0;
    reg status_bev;
    reg [7:0] status_im;
    reg status_um;
    reg status_erl;
    reg status_exl;
    reg status_ie;
    assign status = {
        3'd0,
        status_cu0, // 28
        5'd0,
        status_bev, // 22
        6'd0,
        status_im,  // 15:8
        3'd0,
        status_um,  // 4
        1'b0,
        status_erl, // 2
        status_exl, // 1
        status_ie   // 0
    };
    
    wire status_write = mtc0 && addr == `CP0_STATUS;
    always @(posedge clk) begin
        // CU0
        if (!resetn) status_cu0 <= 1'b0;
        else if (status_write) status_cu0 <= mtc0_data[`STATUS_CU0];
        // BEV
        if (!resetn) status_bev <= 1'b1;
        else if (status_write) status_bev <= mtc0_data[`STATUS_BEV];
        // IM
        if (!resetn) status_im <= 8'd0;
        else if (status_write) status_im <= mtc0_data[`STATUS_IM];
        // UM
        if (!resetn) status_um <= 1'b0;
        else if (status_write) status_um <= mtc0_data[`STATUS_UM];
        // ERL
        // Note: MIPS specifies 1 as the reset value of ERL while NSCSCC specifies 0
        if (!resetn) status_erl <= 1'b0;
        else if (status_write) status_erl <= mtc0_data[`STATUS_ERL];
        // EXL
        if (!resetn) status_exl <= 1'b1;
        else if (commit_exc) status_exl <= !commit_eret;
        else if (status_write) status_exl <= mtc0_data[`STATUS_EXL];
        // IE
        if (!resetn) status_ie <= 1'b0;
        else if (status_write) status_ie <= mtc0_data[`STATUS_IE];
    end
    
    // Cause (13, 0)
    reg cause_bd;
    reg cause_ti;
    reg [1:0] cause_ce;
    reg cause_iv;
    reg [5:0] cause_ip7_2;
    reg [1:0] cause_ip1_0;
    reg [4:0] cause_exccode;
    assign cause = {
        cause_bd,       // 31
        cause_ti,       // 30
        cause_ce,       // 29:28
        4'd0,
        cause_iv,       // 23
        7'd0,
        cause_ip7_2,    // 15:10
        cause_ip1_0,    // 9:8
        1'd0,
        cause_exccode,  // 6:2
        2'd0
    };
    
    wire cause_write = mtc0 && addr == `CP0_CAUSE;
    always @(posedge clk) begin
        // BD
        if (!resetn) cause_bd <= 1'b0;
        else if (exception_commit) cause_bd <= commit_bd;
        // TI
        if (!resetn) cause_ti <= 1'b0;
        else cause_ti <= timer_int;
        // CE
        if (!resetn) cause_ce <= 2'd0;
        // IV
        if (!resetn) cause_iv <= 1'b0;
        else if (cause_write) cause_iv <= mtc0_data[`CAUSE_IV];
        // IP
        cause_ip7_2 <= hw_int;
        if (!resetn) cause_ip1_0 <= 2'd0;
        else if (cause_write) cause_ip1_0 <= mtc0_data[`CAUSE_IP1_0];
        // ExcCode
        if (!resetn) cause_exccode <= 5'd0;
        else if (exception_commit) cause_exccode <= commit_code;
    end
    
    // EPC (14, 0)
    wire epc_write = mtc0 && addr == `CP0_EPC;
    always @(posedge clk) begin
        if (epc_write) epc <= mtc0_data;
        else if (exception_commit) epc <= commit_epc;
    end
    
    // timer interrupt
    always @(posedge clk) begin
        if (!resetn) timer_int <= 1'b0;
        else if (compare_write) timer_int <= 1'b0;
        else if (count == compare) timer_int <= 1'b1;
    end
    
    assign int_sig = {cause_ip7_2, cause_ip1_0} & status_im && !status_erl && !status_exl && status_ie;
    
    assign mfc0_data =
        {32{addr == `CP0_BADVADDR}} & badvaddr |
        {32{addr == `CP0_STATUS}}   & status |
        {32{addr == `CP0_CAUSE}}    & cause |
        {32{addr == `CP0_EPC}}      & epc;
    
endmodule