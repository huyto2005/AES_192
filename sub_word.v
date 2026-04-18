module sub_word (

	 input  wire [31:0] word_in,  
    output wire [31:0] word_out  
);

sbox_single u_sbox0 (
		.byte_in  (word_in[31:24]), // Lấy 8 bit cao nhất từ word_in
		.byte_out (word_out[31:24]) // Gán 8 bit cao nhất cho word_out
);

sbox_single u_sbox1 (
		.byte_in  (word_in[23:16]), // Lấy 8 bit tiếp theo từ word_in
		.byte_out (word_out[23:16]) // Gán 8 bit tiếp theo cho word_out
);
sbox_single u_sbox2 (
		.byte_in  (word_in[15:8]),  // Lấy 8 bit tiếp theo từ word_in
		.byte_out (word_out[15:8])  // Gán 8 bit tiếp theo cho word_out
);
sbox_single u_sbox3 (
		.byte_in  (word_in[7:0]),   // Lấy 8 bit thấp nhất từ word_in
		.byte_out (word_out[7:0])  // Gán 8 bit thấp nhất cho word_out
);

endmodule