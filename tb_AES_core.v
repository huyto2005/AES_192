`timescale 1ns / 1ps

module tb_AES_core;

    // --- 1. KHAI BÁO TÍN HIỆU ---
    reg clk;
    reg reset_n;
    reg start_encrypt;
    reg [127:0] data_in;
    reg [127:0] round_key;

    wire load_B_ena;
    wire done;
    wire [3:0] bram_rd_addr;
    wire bram_re;
    wire [127:0] data_out;
    wire output_valid;

    reg [127:0] key_rom [0:15];
    reg [127:0] plain_A, plain_B;
    reg [127:0] exp_A, exp_B;

    // --- BIẾN TÍNH CHU KỲ (MỚI THÊM) ---
    time t_start, t_end;
    integer total_cycles;

    // --- 2. KẾT NỐI DUT ---
    AES_core uut (
        .clk(clk),
        .reset_n(reset_n),
        .start_encrypt(start_encrypt),
        .data_in(data_in),
        .round_key(round_key),
        .load_B_ena(load_B_ena),
        .done(done),
        .bram_rd_addr(bram_rd_addr),
        .bram_re(bram_re),
        .data_out(data_out),
        .output_valid(output_valid)
    );

    // --- 3. CLOCK & BRAM ---
    initial begin
        clk = 0;
        forever #10 clk = ~clk; // Chu kỳ = 20ns
    end

    // Nạp Key
    initial begin
        key_rom[0]  = 128'h000102030405060708090a0b0c0d0e0f; 
        key_rom[1]  = 128'h10111213141516175846f2f95c43f4fe;
        key_rom[2]  = 128'h544afef55847f0fa4856e2e95c43f4fe;
        key_rom[3]  = 128'h40f949b31cbabd4d48f043b810b7b342;
        key_rom[4]  = 128'h58e151ab04a2a5557effb5416245080c;
        key_rom[5]  = 128'h2ab54bb43a02f8f662e3a95d66410c08;
        key_rom[6]  = 128'hf501857297448d7ebdf1c6ca87f33e3c;
        key_rom[7]  = 128'he510976183519b6934157c9ea351f1e0;
        key_rom[8]  = 128'h1ea0372a995309167c439e77ff12051e;
        key_rom[9]  = 128'hdd7e0e887e2fff68608fc842f9dcc154;
        key_rom[10] = 128'h859f5f237a8d5a3dc0c02952beefd63a;
        key_rom[11] = 128'hde601e7827bcdf2ca223800fd8aeda32;
        key_rom[12] = 128'ha4970a331a78dc09c418c271e3a41d5d; 
    end

    reg [3:0] addr_pipe;
    always @(posedge clk) begin
        if (bram_re) addr_pipe <= bram_rd_addr;
        round_key <= key_rom[addr_pipe];
    end

    // --- 4. KỊCH BẢN TEST TUẦN TỰ (CÓ TÍNH CHU KỲ) ---
    initial begin
        $display("========================================");
        $display("   TESTBENCH AES_CORE");
        $display("========================================");

        plain_A = 128'h00112233445566778899aabbccddeeff;
        exp_A   = 128'hdda97ca4864cdfe06eaf70a0ec0d7191;
        
        plain_B = 128'h00000000000000000000000000000000;
        exp_B   = 128'h916251821c73a522c396d62738019607;

        // 1. Reset
        reset_n = 0; start_encrypt = 0; data_in = 0;
        #50; reset_n = 1; #20;

        // 2. Nạp A và Start
        $display(" [STEP 1] Loading Block A...");
        data_in = plain_A;
        @(posedge clk); #1;
        
        // --- BẮT ĐẦU TÍNH GIỜ TẠI ĐÂY ---
        start_encrypt = 1;
        t_start = $time; // <--- Ghi lại thời điểm bắt đầu
        
        @(posedge clk); #1;
        start_encrypt = 0;

        // 3. Nạp B
        wait(load_B_ena == 1); 
        data_in = plain_B;

        // 4. Chờ KQ A
        wait(output_valid); 
        $display("----------------------------------------");
        $display(" Output 1 Received: %h", data_out);
        if (data_out === exp_A) $display(" [PASS] Block A Matched!");
        else $display(" [FAIL] Block A Mismatch!");
        
        @(posedge clk); 

        // 5. Chờ KQ B
        wait(output_valid);
		  #1;
        // --- KẾT THÚC TÍNH GIỜ TẠI ĐÂY ---
        t_end = $time; // <--- Ghi lại thời điểm kết thúc (khi nhận Block B)
        
        $display("----------------------------------------");
        $display(" Output 2 Received: %h", data_out);
        if (data_out === exp_B) $display(" [PASS] Block B Matched!");
        else $display(" [FAIL] Block B Mismatch!");

        // --- 6. TÍNH TOÁN VÀ IN SỐ CHU KỲ ---
        $display("----------------------------------------");
        // Công thức: Thời gian trôi qua / Chu kỳ clock (20ns)
        total_cycles = (t_end - t_start) / 20;

        $display(" TOTAL LATENCY: %0d CLOCK CYCLES (For 2 Blocks)", total_cycles);
        $display("----------------------------------------");
        #100;
        $stop;
    end

endmodule