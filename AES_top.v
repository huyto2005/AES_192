module AES_top (
		input clk,
		input reset_n,
		input [127:0] data_inA,
		input [127:0] data_inB,
		input [191:0] cipher_key,
		input start_encrypt,
		input start_keygen,
		
		output wire [127:0] data_out,
		output wire done,
		output wire output_valid,
		output wire keygen_done
);

		wire bram_we;
		wire [5:0] bram_addr;
		wire [31:0] bram_data;
		wire [127:0] q_out;
		wire bram_re;
		wire [3:0] bram_rd_addr;
		wire [127:0] aescore_input; 
		wire [127:0] q_outf;
		wire load_B_enable;
		wire [127:0] cipher_data;
		
		assign q_outf = { q_out[31:0], q_out[63:32], q_out[95:64], q_out[127:96] };
		assign aescore_input = (load_B_enable) ? data_inB : data_inA;
		assign data_out = (output_valid) ? cipher_data : 128'bZ;
		
BRAM BRAM_inst(
	.clock(clk),
	.data(bram_data),
	.rden(bram_re),
	.rdaddress(bram_rd_addr),
	.wraddress(bram_addr),
	.wren(bram_we),
	
	.q(q_out)
);
key_expansion_core u_KEC (
		.clk(clk),
		.start(start_keygen),
		.reset_n(reset_n),
		.key_in(cipher_key),
		
		.bram_we(bram_we),
		.bram_addr(bram_addr),
		.bram_data(bram_data),
		.key_done(keygen_done)
);	
AES_core u_AEScore (
		.clk(clk),
		.reset_n(reset_n),
		.start_encrypt(start_encrypt),
		.data_in(aescore_input),
		.round_key(q_outf),
		
		.load_B_ena(load_B_enable),
		.output_valid(output_valid),
		.done(done),
		.bram_rd_addr(bram_rd_addr),
		.bram_re(bram_re),
		.data_out(cipher_data)
);

endmodule 