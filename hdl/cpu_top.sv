module cpu
import rv32i_types::*;
(
    /* CP1 Signals*/
    // remove after cp1
    input 					instr_mem_resp,
    input rv32i_word 	    instr_mem_rdata,
	input 					data_mem_resp,
    input rv32i_word 	    data_mem_rdata, 
    output logic 			instr_read,
	output rv32i_word 	    instr_mem_address,
    output logic 			data_read,
    output logic 			data_write,
    output logic [3:0] 	    data_mbe,
    output rv32i_word 	    data_mem_address,
    output rv32i_word 	    data_mem_wdata,

    /*...Inputs...*/
    input clk,
    input rst


    /*...Outputs...*/



);
/*
Theory:

We'll need 4 modules for our CPU:

1: datapath (duh)

2: icache

3: dcache

4: arbiter

*/
cpu_datapath cpu_datapath(

//CP2DO: Signals for cache in CP2
    .*
);

/* icache module  */
//CP2DO:
/* .............. */

/* dcache module  */
//CP2DO:
/* .............. */

/* arbiter module */
//CP2DO:
/* .............. */


endmodule : cpu