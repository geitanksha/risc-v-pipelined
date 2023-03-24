module control_rom
import rv32i_types::*;
(
    input [31:0]                fetched_instruction_i,
    input [31:0]                PC_val_i,
    output rv32i_control_word   control_word_o
);

// Relevant values extracted from read instruction
logic [31:0] i_imm, s_imm, b_imm, u_imm, j_imm;
rv32i_opcode opcode;
logic [6:0] funct7;
logic [4:0] rs1, rs2, rd;
logic [2:0] funct3;
logic bit30;

assign funct3 = fetched_instruction_i[14:12];
assign funct7 = fetched_instruction_i[31:25];
assign opcode = rv32i_opcode'(fetched_instruction_i[6:0]);
assign i_imm = {{21{fetched_instruction_i[31]}}, fetched_instruction_i[30:20]};
assign s_imm = {{21{fetched_instruction_i[31]}}, fetched_instruction_i[30:25], fetched_instruction_i[11:7]};
assign b_imm = {{20{fetched_instruction_i[31]}}, fetched_instruction_i[7], fetched_instruction_i[30:25], fetched_instruction_i[11:8], 1'b0};
assign u_imm = {fetched_instruction_i[31:12], 12'h000};
assign j_imm = {{12{fetched_instruction_i[31]}}, fetched_instruction_i[19:12], fetched_instruction_i[20], fetched_instruction_i[30:21], 1'b0};
assign rs1 = fetched_instruction_i[19:15];
assign rs2 = fetched_instruction_i[24:20];
assign rd = fetched_instruction_i[11:7];
assign bit30 = funct7[5];

function void set_defaults();

  /* Default Assignments */
  // Initialize control_word to be blank
  control_word_o = 0;

  // Insert instruction info

  control_word_o.instruction        = 0;
  control_word_o.opcode             = opcode;
  control_word_o.aluop              = 0;
  control_word_o.cmpop              = 0;

  //EXE sigs
  control_word_o.alumux1_sel        = 0;
  control_word_o.alumux2_sel        = 0;
  control_word_o.cmpmux_sel         = 0;
  control_word_o.branch             = 0;
  control_word_o.data_mem_read      = 0;
  control_word_o.data_mem_write     = 0;

  control_word_o.regfilemux_sel     = 0;
  control_word_o.load_regfile       = 0;

  control_word_o.rs1                = rs1;
  control_word_o.rs2                = rs2;
  control_word_o.rd                 = rd;
  control_word_o.rs1_data           = 0;
  control_word_o.rs2_data           = 0;

  control_word_o.PC_val             = PC_val_i;

  control_word_o.alu_out            = 0;
  control_word_o.data_memory_rdata  = 0;
  control_word_o.cmp_out            = 0;

  control_word_o.i_imm              = i_imm;
  control_word_o.u_imm              = s_imm;
  control_word_o.b_imm              = b_imm;
  control_word_o.j_imm              = u_imm;
  control_word_o.s_imm              = j_imm;

  control_word_o.rmask              = 0;
  control_word_o.wmask              = 0;
  control_word_o.alu_out            = 0;
  control_word_o.data_memory_return = 0;



endfunction

always_comb begin
  set_defaults();

  case (opcode)
    op_lui: begin
      control_word_o.regfilemux_sel = regfilemux::u_imm;
      control_word_o.branch = 1'b0;
    end

    op_auipc: begin
      control_word_o.branch = 1'b0;
      control_word_o.aluop = rv32i_types::alu_add;
      control_word_o.regfilemux_sel = regfilemux::alu_out;
      control_word_o.alumux1_sel = alumux::pc_out;
      control_word_o.alumux2_sel = alumux::u_imm;
    end

    op_jal: begin
      control_word_o.branch = 1'b1;
      control_word_o.regfilemux_sel = regfilemux::pc_plus4;

      control_word_o.alumux1_sel = alumux::pc_out;
      control_word_o.alumux2_sel = alumux::j_imm;
      control_word_o.aluop = rv32i_types::alu_add;
    end

    op_jalr: begin
      control_word_o.branch = 1'b1;
      control_word_o.pcmux_sel = pcmux::alu_mod2;

      control_word_o.alumux1_sel = alumux::pc_out;
      control_word_o.alumux2_sel = alumux::i_imm;
      control_word_o.aluop = rv32i_types::alu_add;
    end

    op_br: begin
      control_word_o.branch = 1'b1;
      control_word_o.cmpmux_sel = cmpmux::rs2_out;
      control_word_o.cmpop = branch_funct3_t'(funct3);

      control_word_o.alumux1_sel = alumux::pc_out;
      control_word_o.alumux2_sel = alumux::b_imm;

      control_word_o.aluop = rv32i_types::alu_add;
    end

    op_load: begin
      control_word_o.branch = 1'b0;

      control_word_o.data_mem_read = 1'b1;

      control_word_o.alumux1_sel = alumux::rs1_out;
      control_word_o.alumux2_sel = alumux::i_imm;
      control_word_o.aluop = rv32i_types::alu_add;

      case(store_funct3_t'(funct3))
        // The Load/Write masks will be set in the Memory stage.
        // This is because we need the source/destination address
        // (respectively) in order to shift the mask appropriately.
        lb:
          control_word_o.regfilemux_sel = regfilemux::lb;

        lh:
          control_word_o.regfilemux_sel = regfilemux::lh;

        lw:
          control_word_o.regfilemux_sel = regfilemux::lw;

        lbu:
          control_word_o.regfilemux_sel = regfilemux::lbu;

        lhu:
          control_word_o.regfilemux_sel = regfilemux::lhu;

        default: ;
      endcase
    end

    op_store: begin
        control_word_o.branch = 1'b0;
        control_word_o.alumux1_sel = alumux::rs1_out;
        control_word_o.alumux2_sel = alumux::s_imm;
        control_word_o.aluop = rv32i_types::alu_add;
        control_word_o.data_mem_write = 1'b1;
       //control_word_o.mem_byte_enable = wmask;
    end

    op_imm: begin
       control_word_o.branch = 1'b0;
       control_word_o.regfilemux_sel = regfilemux::alu_out;
       // Default for ADDI, XORI, ORI, ANDI, SLLI, SRLI
       control_word_o.alumux1_sel = alumux::rs1_out;
       control_word_o.alumux2_sel = alumux::i_imm;
       control_word_o.aluop = alu_ops'(funct3);


       // SRAI, SLTI, SLTIU
       case(arith_funct3_t'(funct3))
         rv32i_types::sr: // SRAI
	   if(bit30)
	     control_word_o.aluop = rv32i_types::alu_sra;

         rv32i_types::slt: begin // SLTI
	    control_word_o.regfilemux_sel = regfilemux::br_en;
	    control_word_o.cmpmux_sel = cmpmux::i_imm;
	    control_word_o.cmpop = rv32i_types::blt;
	 end

         rv32i_types::sltu: begin // SLTIU
	    control_word_o.regfilemux_sel = regfilemux::br_en;
	    control_word_o.cmpmux_sel = cmpmux::i_imm;
	    control_word_o.cmpop = rv32i_types::bltu;
	 end

         default: ;
       endcase
    end

    op_reg: begin

       control_word_o.branch = 1'b0;

       // ADD, XOR, OR, AND, SLL, SRL
       control_word_o.regfilemux_sel = regfilemux::alu_out;
       control_word_o.alumux1_sel = alumux::rs1_out;
       control_word_o.alumux2_sel = alumux::rs2_out;
       control_word_o.alumux2_sel = alumux::i_imm;
       control_word_o.aluop = alu_ops'(funct3);

       // SUB, SLT, SLTU, SRA
       case(arith_funct3_t'(funct3))
         rv32i_types::add:
           if(bit30)
             control_word_o.aluop = rv32i_types::alu_sub;

         rv32i_types::slt: begin
	    control_word_o.regfilemux_sel = regfilemux::br_en;
	    control_word_o.cmpmux_sel = cmpmux::rs2_out;
	    control_word_o.cmpop = rv32i_types::blt;
	 end

         rv32i_types::sltu: begin
	    control_word_o.regfilemux_sel = regfilemux::br_en;
	    control_word_o.cmpmux_sel = cmpmux::rs2_out;
	    control_word_o.cmpop = rv32i_types::blt;

	 end

         rv32i_types::sr:
           if(bit30)
             control_word_o.aluop = rv32i_types::alu_sra;

         default: ;
       endcase
    end

    op_csr:;
      //CP3TD: coremark / cp3

    default: ;
  endcase


end


endmodule : control_rom
