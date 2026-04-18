module g_func (
   input clk,
	input  wire [31:0] word_in,   
   input  wire [3:0]  rcon_idx,  
	output wire [31:0] word_out   
);
   wire [31:0] rotw;
   wire [31:0] subw;
   wire [31:0] rconw;

   rot_word   u_rot (.word_in(word_in), .word_out(rotw));
   sub_word   u_sub (.word_in(rotw),    .word_out(subw));
   rcon_lookup u_rc (.idx(rcon_idx),    .rcon_val(rconw));

	assign word_out = subw ^ rconw;
 
endmodule 