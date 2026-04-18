module rot_word (
    input  wire [31:0] word_in,  
    output wire [31:0] word_out  
);

    wire [7:0] byte3_in; // byte cao nhất
    wire [7:0] byte2_in;
    wire [7:0] byte1_in;
    wire [7:0] byte0_in; // byte thấp nhất

    assign byte3_in = word_in[31:24];
    assign byte2_in = word_in[23:16];
    assign byte1_in = word_in[15:8];
    assign byte0_in = word_in[7:0];

    // Thực hiện dịch vòng trái 1 byte:

    assign word_out = {byte2_in, byte1_in, byte0_in, byte3_in};

endmodule