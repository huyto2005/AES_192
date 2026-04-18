/******************************************************************
* Module: top_gfunc_test (ĐÃ SỬA LỖI)
******************************************************************/
module top_gfunc_test (
    input wire clk,
    // THÊM DÒNG NÀY:
    output wire [31:0] test_out 
);

    // 1. Thanh ghi cho tất cả các đầu vào
    reg [31:0] word_in_reg;
    reg [3:0]  rcon_idx_reg;

    // 2. Dây nối để bắt đầu ra
    wire [31:0] word_out_wire;

    // 3. Thanh ghi cho tất cả các đầu ra
    reg [31:0] word_out_reg;

    // 4. Khởi tạo DUT
    g_func u_dut (
        .clk(clk),
        .word_in(word_in_reg),
        .rcon_idx(rcon_idx_reg),
        .word_out(word_out_wire)
    );

    // 5. Logic để giữ các thanh ghi
    always @(posedge clk) begin
        word_in_reg  <= word_in_reg + 1;
        rcon_idx_reg <= rcon_idx_reg + 1;
        word_out_reg <= word_out_wire;
    end
    
    // THÊM DÒNG NÀY:
    // Kết nối thanh ghi cuối cùng ra cổng output
    assign test_out = word_out_reg;

endmodule