module sub_bytes (
	 input  wire [127:0] state_in,
    output wire [127:0] state_out
);

    wire [7:0] s_out [0:15];
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : SBOX_SUBSTITUTION_LOOP
            sbox_single u_sbox (
                // Lấy lát cắt 8-bit trực tiếp từ state_in
                .byte_in(state_in[127 - i*8 -: 8]),
                .byte_out(s_out[i])

            );
        end
    endgenerate

    assign state_out = {
        s_out[0],  s_out[1],  s_out[2],  s_out[3],
        s_out[4],  s_out[5],  s_out[6],  s_out[7],
        s_out[8],  s_out[9],  s_out[10], s_out[11],
        s_out[12], s_out[13], s_out[14], s_out[15]
    };

endmodule 