module spike_log_printer
(
    tb_itf itf,
    rvfi_itf rvfi
);


int fd;
initial fd = $fopen("./spike.log", "w");
final $fclose(fd);

int commit_counter;
initial commit_counter = 1;

logic           spike_print_clk      ;
logic			spike_print_valid    ;
logic	[31:0]	spike_print_pc       ;
logic	[31:0]	spike_print_ir       ;
logic			spike_print_regf_we  ;
logic	[4:0]	spike_print_rd_s     ;
logic	[31:0]	spike_print_rd_v     ;
logic	[3:0]	spike_print_rmask    ;
logic	[3:0]	spike_print_wmask    ;
logic	[31:0]	spike_print_dm_addr  ;
logic	[31:0]	spike_print_dm_wdata ;

assign          spike_print_clk      = itf.clk;
assign			spike_print_valid    = rvfi.commit;
assign			spike_print_pc       = rvfi.pc_rdata;
assign			spike_print_ir       = rvfi.inst;
assign			spike_print_regf_we  = rvfi.load_regfile;
assign			spike_print_rd_s     = rvfi.rd_addr;
assign			spike_print_rd_v     = rvfi.rd_wdata;
assign			spike_print_rmask    = rvfi.mem_rmask;
assign			spike_print_wmask    = rvfi.mem_wmask;
assign			spike_print_dm_addr  = rvfi.mem_addr;
assign			spike_print_dm_wdata = rvfi.mem_wdata;

always @ (negedge spike_print_clk) begin
	if(spike_print_valid) begin
		commit_counter += 1;
		if (commit_counter % 1000 == 0) begin
			$display("commit %d, rd_s: x%02d, rd: 0x%h", commit_counter, spike_print_rd_s, spike_print_rd_v);
		end
		$fwrite(fd, "core   0: 3 0x%h (0x%h)", spike_print_pc, spike_print_ir);
		if (spike_print_regf_we == 1'b1 && spike_print_rd_s != 0) begin
			if (spike_print_rd_s < 10)
				$fwrite(fd, " x%0d  ", spike_print_rd_s);
			else
				$fwrite(fd, " x%0d ", spike_print_rd_s);
			$fwrite(fd, "0x%h", spike_print_rd_v);
		end
		if (spike_print_rmask != 0) begin
			$fwrite(fd, " mem 0x%h", spike_print_dm_addr);
		end
		if (spike_print_wmask != 0) begin
			automatic int amount_o_1 = 0;
			for(int i = 0; i < 4; i++) begin
				if(spike_print_wmask[i]) begin
					amount_o_1 += 1;
				end
			end
			$fwrite(fd, " mem 0x%h", spike_print_dm_addr);
			case (amount_o_1)
				1: begin
					automatic logic[7:0] wdata_byte = spike_print_dm_wdata[8*spike_print_dm_addr[1:0] +: 8];
					$fwrite(fd, " 0x%h", wdata_byte);
				end
				2: begin
					automatic logic[15:0] wdata_half = spike_print_dm_wdata[16*spike_print_dm_addr[1] +: 16];
					$fwrite(fd, " 0x%h", wdata_half);
				end
				4:
					$fwrite(fd, " 0x%h", spike_print_dm_wdata);
			endcase
		end
		$fwrite(fd, "\n");
	end
end

endmodule