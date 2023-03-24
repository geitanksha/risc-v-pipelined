package rv32i_types;
// Mux types are in their own packages to prevent identiier collisions
// e.g. pcmux::pc_plus4 and regfilemux::pc_plus4 are seperate identifiers
// for seperate enumerated types
import pcmux::*;
import marmux::*;
import cmpmux::*;
import alumux::*;
import regfilemux::*;

typedef logic [31:0] rv32i_word;
typedef logic [4:0] rv32i_reg;
typedef logic [3:0] rv32i_mem_wmask;

typedef enum bit [6:0] {
    op_lui   = 7'b0110111, //load upper immediate (U type)
    op_auipc = 7'b0010111, //add upper immediate PC (U type)
    op_jal   = 7'b1101111, //jump and link (J type)
    op_jalr  = 7'b1100111, //jump and link register (I type)
    op_br    = 7'b1100011, //branch (B type)
    op_load  = 7'b0000011, //load (I type)
    op_store = 7'b0100011, //store (S type)
    op_imm   = 7'b0010011, //arith ops with register/immediate operands (I type)
    op_reg   = 7'b0110011, //arith ops with register operands (R type)
    op_csr   = 7'b1110011  //control and status register (I type)
} rv32i_opcode;

typedef enum bit [2:0] {
    beq  = 3'b000,
    bne  = 3'b001,
    blt  = 3'b100,
    bge  = 3'b101,
    bltu = 3'b110,
    bgeu = 3'b111
} branch_funct3_t;

typedef enum bit [2:0] {
    lb  = 3'b000,
    lh  = 3'b001,
    lw  = 3'b010,
    lbu = 3'b100,
    lhu = 3'b101
} load_funct3_t;

typedef enum bit [2:0] {
    sb = 3'b000,
    sh = 3'b001,
    sw = 3'b010
} store_funct3_t;

typedef enum bit [2:0] {
    add  = 3'b000, //check bit30 for sub if op_reg opcode
    sll  = 3'b001,
    slt  = 3'b010,
    sltu = 3'b011,
    axor = 3'b100,
    sr   = 3'b101, //check bit30 for logical/arithmetic
    aor  = 3'b110,
    aand = 3'b111
} arith_funct3_t;

typedef enum bit [2:0]{
    csrrw  = 3'b001,
    csrrs  = 3'b010,
    csrrc  = 3'b011,
    csrrwi = 3'b101,
    csrrsi = 3'b110,
    csrrci = 3'b111
} csr_funct3_t;

typedef enum bit [2:0] {
    alu_add = 3'b000,
    alu_sll = 3'b001,
    alu_sra = 3'b010,
    alu_sub = 3'b011,
    alu_xor = 3'b100,
    alu_srl = 3'b101,
    alu_or  = 3'b110,
    alu_and = 3'b111
} alu_ops;

typedef struct packed {
    /*....Control Signals....*/
    rv32i_word    instruction;
    rv32i_opcode       opcode;
    alu_ops             aluop;
    branch_funct3_t     cmpop;
    alumux1_sel_t alumux1_sel;
    alumux2_sel_t alumux2_sel;
    cmpmux_sel_t   cmpmux_sel;
    pcmux_sel_t     pcmux_sel;
    logic              branch;
    logic 	    data_mem_read;
    logic      data_mem_write;
    /*....Data Signals....*/
    regfilemux_sel_t   regfilemux_sel;

    logic     load_regfile;
    logic  [4:0]       rs1;
    logic  [4:0]       rs2;
    logic  [4:0]        rd;
    logic  [31:0] rs1_data;
    logic  [31:0] rs2_data;

    logic  [31:0]   PC_val;

    logic  [31:0]  alu_out;
    logic  [31:0] data_memory_rdata;
    logic          cmp_out;
    logic  [31:0]    i_imm;
    logic  [31:0]    u_imm;
    logic  [31:0]    b_imm;
    logic  [31:0]    j_imm;
    logic  [31:0]    s_imm;
    logic  [3:0]     rmask;
    logic  [3:0]     wmask;
    /*....RegfileMux Signals....*/
    //@todo let someone else do these? idk if we actually rly need them.
    logic [31:0]     data_memory_return;
    // regfilemux sel
    // all the regfilemux outputs possible
} rv32i_control_word;

endpackage : rv32i_types
