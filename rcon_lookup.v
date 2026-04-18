module rcon_lookup (
    input  wire [3:0]  idx, 
    output reg  [31:0] rcon_val
);
    always @(*) begin
        case (idx)
            4'd1:  rcon_val = 32'h01000000;
            4'd2:  rcon_val = 32'h02000000;
            4'd3:  rcon_val = 32'h04000000;
            4'd4:  rcon_val = 32'h08000000;
            4'd5:  rcon_val = 32'h10000000;
            4'd6:  rcon_val = 32'h20000000;
            4'd7:  rcon_val = 32'h40000000;
            4'd8:  rcon_val = 32'h80000000;
            4'd9:  rcon_val = 32'h1B000000;
            4'd10: rcon_val = 32'h36000000;
            default: rcon_val = 32'h00000000;
        endcase
    end
endmodule