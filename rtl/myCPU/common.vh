// Coprocessor 0 Registers

`define CP0_INDEX           8'b00000_000 // 0 , 0
`define CP0_RANDOM          8'b00001_000 // 1 , 0
`define CP0_ENTRYLO0        8'b00010_000 // 2 , 0
`define CP0_ENTRYLO1        8'b00011_000 // 3 , 0
`define CP0_CONTEXT         8'b00100_000 // 4 , 0
`define CP0_PAGEMASK        8'b00101_000 // 5 , 0
`define CP0_WIRED           8'b00110_000 // 6 , 0
`define CP0_BADVADDR        8'b01000_000 // 8 , 0
`define CP0_COUNT           8'b01001_000 // 9 , 0
`define CP0_ENTRYHI         8'b01010_000 // 10, 0
`define CP0_COMPARE         8'b01011_000 // 11, 0
`define CP0_STATUS          8'b01100_000 // 12, 0
`define CP0_CAUSE           8'b01101_000 // 13, 0
`define CP0_EPC             8'b01110_000 // 14, 0
`define CP0_PRID            8'b01111_000 // 15, 0
`define CP0_CONFIG          8'b10000_000 // 16, 0
`define CP0_ERROREPC        8'b11110_000 // 30, 0

`define CP0_TAGLO_RD        5'd28
`define CP0_TAGHI_RD        5'd29

// Coprocessor 0 Register Bits
// Status (12, 0)
`define STATUS_CU0          28
`define STATUS_BEV          22
`define STATUS_IM           15:8
`define STATUS_UM           4
`define STATUS_ERL          2
`define STATUS_EXL          1
`define STATUS_IE           0

// Cause (13, 0)
`define CAUSE_BD            31
`define CAUSE_TI            30
`define CAUSE_CE            29:28
`define CAUSE_IV            23
`define CAUSE_IP            15:8
`define CAUSE_IP7_2         15:10
`define CAUSE_IP1_0         9:8
`define CAUSE_EXCCODE       6:2

// Exception vectors

`define VEC_RESET           32'hbfc0_0000
`define VEC_REFILL          32'h8000_0000
`define VEC_REFILL_EXL      32'h8000_0180
`define VEC_REFILL_BEV      32'hbfc0_0200
`define VEC_REFILL_BEV_EXL  32'hbfc0_0380
`define VEC_CACHEERR        32'ha000_0100
`define VEC_CACHEERR_BEV    32'dbfc0_0300
`define VEC_INTR            32'h8000_0180
`define VEC_INTR_IV         32'h8000_0200
`define VEC_INTR_BEV        32'hbfc0_0380
`define VEC_INTR_BEV_IV     32'hbfc0_0400
`define VEC_OTHER           32'h8000_0180
`define VEC_OTHER_BEV       32'hbfc0_0380

// EXCCODE

`define EXC_INT         5'h00
`define EXC_MOD         5'h01
`define EXC_TLBL        5'h02
`define EXC_TLBS        5'h03
`define EXC_ADEL        5'h04
`define EXC_ADES        5'h05
`define EXC_IBE         5'h06
`define EXC_DBE         5'h07
`define EXC_SYS         5'h08
`define EXC_BP          5'h09
`define EXC_RI          5'h0a
`define EXC_CPU         5'h0b
`define EXC_OV          5'h0c
`define EXC_TR          5'h0d

`define EXC_WATCH       5'h17

`define EXC_CACHEERR    5'h1e

// instruction encoding

`define GET_RS(x)       x[25:21]
`define GET_RT(x)       x[20:16]
`define GET_RD(x)       x[15:11]
`define GET_SA(x)       x[10:6]
`define GET_IMM(x)      x[15:0]
`define GET_INDEX(x) x[25:0]

// Control signal indexes

`define I_ALU_ADD   0
`define I_ALU_SUB   1
`define I_ALU_AND   2
`define I_ALU_OR    3
`define I_ALU_XOR   4
`define I_ALU_NOR   5
`define I_ALU_SLT   6
`define I_ALU_SLTU  7
`define I_ALU_SLL   8
`define I_ALU_SRL   9
`define I_ALU_SRA   10

`define I_MFHI      11
`define I_MTHI      12
`define I_MFLO      13
`define I_MTLO      14
`define I_LUI       15
`define I_ERET      16
`define I_MFC0      17
`define I_MTC0      18
`define I_LB        19
`define I_LH        20
`define I_LWL       21
`define I_LW        22
`define I_LBU       23
`define I_LHU       24
`define I_LWR       25
`define I_SB        26
`define I_SH        27
`define I_SWL       28
`define I_SW        29
`define I_SWR       30

`define I_MEM_R     31
`define I_MEM_W     32
`define I_RS_R      33
`define I_RT_R      34
`define I_WEX       35
`define I_WWB       36
`define I_IMM_SX    37
`define I_ALU_A_SA  38
`define I_ALU_B_IMM 39
`define I_LINK      40
`define I_DO_MUL    41
`define I_DO_DIV    42
`define I_MD_SIGN   43
`define I_EXC_OF    44

`define I_MAX       45
