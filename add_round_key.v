module add_round_key (
    input  wire [127:0] state_in,
    input  wire [127:0] key_in,
    output wire [127:0] state_out
);
    assign state_out = state_in ^ key_in;
endmodule