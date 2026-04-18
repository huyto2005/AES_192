`timescale 1ns / 1ps

module tb_key_expansion;

    // ============================================================
    // 1. KHAI BÁO TÍN HIỆU
    // ============================================================
    reg clk;
    reg reset_n;
    reg start;
    reg [191:0] key_in;

    wire bram_we;
    wire [5:0] bram_addr;
    wire [31:0] bram_data;
    wire key_done;

    reg [31:0] sim_bram [0:63]; 

    integer i;
    
    // --- BIẾN TÍNH LATENCY ---
    time t_start, t_end;
    integer total_cycles;

    // ============================================================
    // 2. KẾT NỐI MODULE (DUT)
    // ============================================================
    key_expansion_core u_dut (
        .clk(clk),
        .start(start),
        .reset_n(reset_n),
        .key_in(key_in),
        
        .bram_we(bram_we),
        .bram_addr(bram_addr),
        .bram_data(bram_data),
        .key_done(key_done)
    );

    // ============================================================
    // 3. TẠO CLOCK (50MHz -> Period = 20ns)
    // ============================================================
    initial begin
        clk = 0;
        forever #10 clk = ~clk; 
    end

    // ============================================================
    // 4. GIẢ LẬP BRAM (CAPTURE DATA)
    // ============================================================
    always @(posedge clk) begin
        if (bram_we) begin
            sim_bram[bram_addr] <= bram_data;
        end
    end

    // ============================================================
    // 5. CHƯƠNG TRÌNH TEST CHÍNH
    // ============================================================
    initial begin
        $display("==============================================");
        $display("      TESTBENCH FOR AES-192 KEY EXPANSION     ");
        $display("==============================================");

        // 1. Khởi tạo
        reset_n = 0;
        start = 0;
        key_in = 0;
        total_cycles = 0;
        
        // Xóa sạch bộ nhớ giả lập
        for (i=0; i<64; i=i+1) sim_bram[i] = 32'h0;

        #100;
        reset_n = 1;
        #20;

        // 2. Nạp Input (Test Vector NIST FIPS-197 Appendix C.2)
        key_in = 192'h000102030405060708090a0b0c0d0e0f1011121314151617;
        
        $display("Input Key: %h", key_in);
        $display("Starting Key Expansion...");

        // 3. Kích xung Start (CÓ DELAY #1)
        @(posedge clk);
        #1; // Delay tín hiệu input để tránh race condition
        start = 1;
        
        // Ghi lại thời điểm bắt đầu (Lưu ý: đã trễ 1ns so với cạnh clock)
        t_start = $time; 

        @(posedge clk);
        #1; // Delay hạ start
        start = 0;

        // 4. Chờ Key Done
        wait(key_done); #1
        
        // Ghi lại thời điểm kết thúc (ngay khi done lên 1)
        t_end = $time;
        
        #50; // Đợi thêm chút cho ổn định
        
        $display("Key Expansion Finished!");
        
        // --- TÍNH TOÁN SỐ CHU KỲ ---
        // Công thức: (Thời gian kết thúc - Thời gian bắt đầu) / Chu kỳ Clock
        // Lưu ý: Kết quả chia số nguyên sẽ tự động làm tròn xuống
        total_cycles = (t_end - t_start) / 20;

        $display("----------------------------------------------");
        $display(" TOTAL CYCLES : %0d Clock Cycles", total_cycles);

        $display("----------------------------------------------");
        $display("Generated Round Keys:");
        $display("----------------------------------------------");

        // 5. In kết quả: Ghép 4 từ 32-bit thành 1 Round Key 128-bit
        // AES-192 có 13 Round Keys (Round 0 -> Round 12)
        for (i = 0; i < 13; i = i + 1) begin
            $display("Round %2d Key: %h%h%h%h", 
                i, 
                sim_bram[i*4],     // Word 0
                sim_bram[i*4 + 1], // Word 1
                sim_bram[i*4 + 2], // Word 2
                sim_bram[i*4 + 3]  // Word 3
            );
        end
        $display("==============================================");
        $stop;
    end

endmodule