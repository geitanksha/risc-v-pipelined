module cpu_datapath
import rv32i_types::*;
(
    /* CP1 Signals*/
    // remove after cp1
    input 		        instr_mem_resp,
    input rv32i_word   instr_mem_rdata,
    input 		        data_mem_resp,
    input rv32i_word   data_mem_rdata,
    output logic 	    instr_read,
    output rv32i_word  instr_mem_address,
    output logic 	    data_read,
    output logic 	    data_write,
    output logic [3:0] data_mbe,
    output rv32i_word  data_mem_address,
    output rv32i_word  data_mem_wdata,

        /*...Inputs...*/
    input 		    clk,
    input 		    rst
    //CP2DO:

    /*...Outputs...*/
    //CP2DO:

);

/*****************************************************/
/*.............Instruction Decode Signals ...........*/
/*****************************************************/


/*
Control Word name scheme:
part1_part2_controlword
part1 is the RECIEVING edge of the control word register.
part2 is the SENDING edge of the control word register.
*/
/*.....Control words......*/
rv32i_control_word IFE_DEL_controlword;
rv32i_control_word DEL_EXE_controlword;
rv32i_control_word EXE_MEM_controlword;
rv32i_control_word MEM_WRB_controlword;
/*........................*/

logic load_pc;
logic load_ir;
logic load_regfile;
alumux::alumux1_sel_t alumux1_sel;
alumux::alumux2_sel_t alumux2_sel;
regfilemux::regfilemux_sel_t regfilemux_sel;
logic cmpmux_sel;
alu_ops aluop;
branch_funct3_t cmpop;
rv32i_reg rs1;
rv32i_reg rs2;
rv32i_reg rd;

/* Output of the muxes */
rv32i_word pcmux_out;
rv32i_word pc_out;
rv32i_word alumux1_out;
rv32i_word alumux2_out;
rv32i_word cmp_mux_out;
rv32i_word regfilemux_out;
rv32i_word rs1_out;
rv32i_word rs2_out;
rv32i_word mem_rdata_out_mem;
rv32i_word mem_rdata_out_wb;
logic br_en;
logic cmp_op_mux_out;
/* regfile intermediate variables */
rv32i_word regfile_rs1_data;
rv32i_word regfile_rs2_data;
/* ALU module intermediate variable */
rv32i_word alu_data_out;
/* Writeback intermediate variable */
logic [1:0] bottom_two_bits;




/*********************************/
/**********............***********/
/*****.......................*****/
/*........Instruction Fetch......*/
/*****.......................*****/
/**********............***********/
/*********************************/
/* Control rom for instantiating the first control word.*/
control_rom control_rom
(
    //NOTE: using the raw instr_mem_rdata feels bad. I want to maybe put a register here for safety. Idk how necessary that is tho. -q
    .fetched_instruction_i(instr_mem_rdata),
    .PC_val_i(pc_out),
    .control_word_o(IFE_DEL_controlword)
);

always_comb begin

    unique case (br_en)
        pcmux::pc_plus4: pcmux_out = pc_out + 4;
        pcmux::alu_out: begin
            if(IFE_DEL_controlword.opcode == op_jalr)
            pcmux_out = alu_data_out & ~1;
            else
            pcmux_out = alu_data_out;
        end
        default:         pcmux_out = pc_out  +  4; // Appendix D
    endcase

end

always_ff @(posedge clk) begin
    /* PC reg */
    pc_out <= pcmux_out;
    /* Reset conditions */
    if(rst) begin
        pc_out <= 32'h80000000; // Initial PC value.
    end
    //Initial control word is done by control rom.
end



/*********************************/
/**********............***********/
/*****.......................*****/
/*........Decode / Load ........ */
/*****.......................*****/
/**********............***********/
/*********************************/

regfile regfile (
    .clk    (clk),
    .rst    (rst),
    .load   (IFE_DEL_controlword.load_regfile),
    .in     (regfilemux_out),
    .src_a  (IFE_DEL_controlword.rs1),
    .src_b  (IFE_DEL_controlword.rs2),
    .dest   (IFE_DEL_controlword.rd),
    .reg_a  (regfile_rs1_data),
    .reg_b  (regfile_rs2_data)
);


always_ff @(posedge clk) begin

    /* Things lower in this list have priority over things higher, so some parts of instruction controlword will be overwritten.*/
    DEL_EXE_controlword <= IFE_DEL_controlword;
    /*Overwrites to DEL_EXE_controlword go here ⬇️*/
    // overwrites from decode / load
    DEL_EXE_controlword.rs1_data <= regfile_rs1_data;
    DEL_EXE_controlword.rs2_data <= regfile_rs2_data;
    if(rst) begin
        DEL_EXE_controlword <= {$bits(rv32i_control_word){1'b0}};
    end

end




/*********************************/
/**********............***********/
/*****.......................*****/
/*............Execute............*/
/*****.......................*****/
/**********............***********/
/*********************************/
alu alu(
    .aluop(DEL_EXE_controlword.aluop),
    .a(alumux1_out),
    .b(alumux2_out),
    .f(alu_data_out)
);
always_comb begin
//TODO: check correctness and signal declaration

/* Muxes */
    /* ALU MUX 1 */
    unique case (DEL_EXE_controlword.alumux1_sel)
        alumux::rs1_out:   alumux1_out = DEL_EXE_controlword.rs1_data;
        alumux::pc_out:    alumux1_out = DEL_EXE_controlword.PC_val;
        default:           alumux1_out = DEL_EXE_controlword.rs1_data;
    endcase
    /* ALU MUX 2 */
    unique case (DEL_EXE_controlword.alumux2_sel)
        alumux::rs2_out:    alumux2_out = DEL_EXE_controlword.rs2_data;
        alumux::i_imm:      alumux2_out = DEL_EXE_controlword.i_imm;
        alumux::u_imm:      alumux2_out = DEL_EXE_controlword.u_imm;
        alumux::b_imm:      alumux2_out = DEL_EXE_controlword.b_imm;
        alumux::s_imm:      alumux2_out = DEL_EXE_controlword.s_imm;
        alumux::j_imm:      alumux2_out = DEL_EXE_controlword.j_imm;
        default:            alumux2_out = DEL_EXE_controlword.i_imm;
    endcase
    /* CMP MUX */
    unique case (DEL_EXE_controlword.cmpmux_sel)
        cmpmux::rs2_out: cmp_mux_out = DEL_EXE_controlword.rs2_data;
        cmpmux::i_imm:   cmp_mux_out = DEL_EXE_controlword.i_imm;
        default:         cmp_mux_out = DEL_EXE_controlword.rs2_data;
    endcase

    //cmp_op_mux
    case (DEL_EXE_controlword.cmpop)
            beq :    cmp_op_mux_out =  DEL_EXE_controlword.rs1_data     == cmp_mux_out;
            bne :    cmp_op_mux_out =  DEL_EXE_controlword.rs1_data     != cmp_mux_out;
            blt :    cmp_op_mux_out = $signed( DEL_EXE_controlword.rs1_data )   <  $signed( cmp_mux_out );
            bge :    cmp_op_mux_out = $signed( DEL_EXE_controlword.rs1_data )   >= $signed( cmp_mux_out );
            bltu :   cmp_op_mux_out = $unsigned( DEL_EXE_controlword.rs1_data )   <  $unsigned( cmp_mux_out );
            bgeu :   cmp_op_mux_out = $unsigned( DEL_EXE_controlword.rs1_data )   >= $unsigned( cmp_mux_out );
            default: cmp_op_mux_out = 1'b0;
    endcase

        br_en = (DEL_EXE_controlword.branch == 1'b1) && (cmp_op_mux_out);

end

always_ff @(posedge clk) begin
    EXE_MEM_controlword <= DEL_EXE_controlword;
    /*Overwrites to EXE_MEM_controlword go here ⬇️*/
    // control word EXE overwrites
    EXE_MEM_controlword.cmp_out <= cmp_op_mux_out;
    EXE_MEM_controlword.alu_out <= alu_data_out;
    if(rst) begin
        EXE_MEM_controlword <= {$bits(rv32i_control_word){1'b0}}; // Initial PC value.
    end
end


/*********************************/
/**********............***********/
/*****.......................*****/
/*.............Memory............*/
/*****.......................*****/
/**********............***********/
/*********************************/


always_comb begin
    /*
    * Consume: alu_out, mem_read, mem_write
    * Produce: data_memory_rdata
    */

    data_mem_address = EXE_MEM_controlword.alu_out;
    data_read = EXE_MEM_controlword.data_mem_read;
    data_write = EXE_MEM_controlword.data_mem_write;

end





always_ff @(posedge clk) begin

MEM_WRB_controlword <= EXE_MEM_controlword;
/*Overwrites to MEM_controlword go here ⬇️*/
    MEM_WRB_controlword.data_memory_rdata <= data_mem_rdata;
    // If it's a write, additional logic is not necessary
    if(rst) begin
        MEM_WRB_controlword <= {$bits(rv32i_control_word){1'b0}}; // Initial PC value.
    end
end

/*********************************/
/**********............***********/
/*****.......................*****/
/*...........Writeback...........*/
/*****.......................*****/
/**********............***********/
/*********************************/

always_comb begin
   bottom_two_bits = MEM_WRB_controlword.alu_out[1:0];
   // TODO!: Is this next line necessary? data_memory_rdata isn't used anywhere else.
   // data_memory_rdata = MEM_WRB_controlword.data_memory_rdata;

/* REGFILE MUX */
    unique case (regfilemux_sel)
        regfilemux::alu_out:   regfilemux_out = MEM_WRB_controlword.alu_out;
        regfilemux::br_en:     regfilemux_out = {31'b0, MEM_WRB_controlword.branch};     // since we need to load 1 in, we zero extend branch enable so that the output of the mux is 32 bits storing val br_en
        regfilemux::u_imm:     regfilemux_out = MEM_WRB_controlword.u_imm;
        regfilemux::lw:        regfilemux_out = mem_rdata_out_mem;
        regfilemux::pc_plus4:  regfilemux_out = MEM_WRB_controlword.PC_val + 4;
        regfilemux::lb: begin
            case (bottom_two_bits)
                2'b00:
                    regfilemux_out = {{24{mem_rdata_out_mem[7]}}, mem_rdata_out_mem[7:0]}; //sext 24 bits
                2'b01:
                    regfilemux_out = {{24{mem_rdata_out_mem[15]}}, mem_rdata_out_mem[15:8]};
                2'b10:
                    regfilemux_out = {{24{mem_rdata_out_mem[23]}}, mem_rdata_out_mem[23:16]};
                2'b11:
                    regfilemux_out = {{24{mem_rdata_out_mem[31]}}, mem_rdata_out_mem[31:24]};
                default:
                    regfilemux_out = {{24{mem_rdata_out_mem[7]}}, mem_rdata_out_mem[7:0]}; //sext 24 bits
            endcase
        end
        regfilemux::lbu: begin
            case (bottom_two_bits)
                2'b00:
                    regfilemux_out = {24'b0, mem_rdata_out_mem[7:0]}; //sext 24 bits
                2'b01:
                    regfilemux_out = {24'b0, mem_rdata_out_mem[15:8]};
                2'b10:
                    regfilemux_out = {24'b0, mem_rdata_out_mem[23:16]};
                2'b11:
                    regfilemux_out = {24'b0, mem_rdata_out_mem[31:24]};
                default:
                    regfilemux_out = {24'b0, mem_rdata_out_mem[7:0]}; //sext 24 bits
            endcase
        end
        regfilemux::lh: begin
            case (bottom_two_bits)
                2'b00:
                    regfilemux_out = {{16{mem_rdata_out_mem[15]}}, mem_rdata_out_mem[15:0]};
                2'b10:
                    regfilemux_out = {{16{mem_rdata_out_mem[31]}}, mem_rdata_out_mem[31:16]};
                default:
                    regfilemux_out = {{16{mem_rdata_out_mem[15]}}, mem_rdata_out_mem[15:0]};
            endcase
        end
        regfilemux::lhu: begin
            case (bottom_two_bits)
                2'b00:
                    regfilemux_out = {16'b0, mem_rdata_out_mem[15:0]};
                2'b10:
                    regfilemux_out = {16'b0, mem_rdata_out_mem[31:16]};
                default:
                    regfilemux_out = {16'b0, mem_rdata_out_mem[15:0]};
            endcase
        end
        default:  regfilemux_out = MEM_WRB_controlword.alu_out; // Appendix D
    endcase
end







endmodule : cpu_datapath
