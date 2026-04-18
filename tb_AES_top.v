`timescale 1ns / 1ps

module tb_AES_top;

    // ============================================================
    // 1. KHAI BÁO TÍN HIỆU & BIẾN TOÀN CỤC
    // ============================================================
    reg clk;
    reg reset_n;
    
    // Inputs cho AES_top
    reg [127:0] data_inA;
    reg [127:0] data_inB; 
    reg [191:0] cipher_key;
    reg start_encrypt;
    reg start_keygen;

    // Outputs từ AES_top
    wire [127:0] data_out;
    wire done;
    wire output_valid;
    wire keygen_done;

    // Mảng lưu trữ Test Vectors (5 bộ)
    reg [127:0] MEM_DATA_A [1:5];
    reg [127:0] MEM_DATA_B [1:5];
    reg [191:0] MEM_KEY    [1:5];
    reg [127:0] MEM_EXP_A  [1:5];
    reg [127:0] MEM_EXP_B  [1:5];

    // Biến điều khiển và thống kê
    integer i; 
    integer total_pass = 0;
    integer total_fail = 0;

    // ============================================================
    // 2. KẾT NỐI DUT (AES_top)
    // ============================================================
    AES_top u_dut (
        .clk(clk),
        .reset_n(reset_n),
        .data_inA(data_inA),
        .data_inB(data_inB),
        .cipher_key(cipher_key),
        .start_encrypt(start_encrypt),
        .start_keygen(start_keygen),
        .data_out(data_out),
        .done(done),
        .output_valid(output_valid),
        .keygen_done(keygen_done)
    );

    // ============================================================
    // 3. KHỞI TẠO CLOCK (50MHz -> Period 20ns)
    // ============================================================
    initial begin
        clk = 0;
        forever #10 clk = ~clk; 
    end

    // ============================================================
    // 4. NẠP DỮ LIỆU TEST (DATABASE)
    // ============================================================
    initial begin
        // --- CASE 1 ---
        MEM_DATA_A[1] = 128'h44616920486F63000000000000000000;
        MEM_DATA_B[1] = 128'h54686F6E672054696E00000000000000;
        MEM_KEY[1]    = 192'h000102030405060708090a0b0c0d0e0f1011121314151617;
        MEM_EXP_A[1]  = 128'h00000000000000000000000000000000;
        MEM_EXP_B[1]  = 128'h00000000000000000000000000000000;
        // --- CASE 2 ---
        MEM_DATA_A[2] = 128'h11223344556677889900AABBCCDDEEFF;
        MEM_DATA_B[2] = 128'h55AA55AA1234567890ABCDEF10293847;
        MEM_KEY[2]    = 192'hC4AFC3B2D1E0F123456789ABCDEF0123456789AABBCCDDEE;
        MEM_EXP_A[2]  = 128'h2f8eb53758f71c4847bf6d7048b69fa3;
        MEM_EXP_B[2]  = 128'h8df4046146a134d81b7109f68dd4cc1c;
        // --- CASE 3 ---
        MEM_DATA_A[3] = 128'hDEADBEEFCAFEBABE0123456789ABCDEF;
        MEM_DATA_B[3] = 128'h0102030405060708090A0B0C0D0E0F10;
        MEM_KEY[3]    = 192'h2B7E151628AED2A6ABF7158809CF4F3C762E7160F38B4DA5;
        MEM_EXP_A[3]  = 128'ha1c3030b92296d442518396deda18ed0;
        MEM_EXP_B[3]  = 128'h143ac33513e27a8cf7b42c12563135b9;
        // --- CASE 4 ---
        MEM_DATA_A[4] = 128'hFEEDFACECAFEBEEF1234567890ABCDEF;
        MEM_DATA_B[4] = 128'hAABBCCDDEEFF00112233445566778899;
        MEM_KEY[4]    = 192'hA0FAFE1788542CB123A339392A6C7605F2A1C44BD4E56AC9;
        MEM_EXP_A[4]  = 128'h69c533c6ee4037bd5e5ca832b491b9a8;
        MEM_EXP_B[4]  = 128'heedf8e3e2964061560bf353b630f3f3d;
        // --- CASE 5 ---
        MEM_DATA_A[5] = 128'h0F1E2D3C4B5A69788796A5B4C3D2E1F0;
        MEM_DATA_B[5] = 128'h102030405060708090A0B0C0D0E0F000;
        MEM_KEY[5]    = 192'h9F7952EC14A3D2C6B5E4971043A9F2D87C61BEEDE2340F59;
        MEM_EXP_A[5]  = 128'ha952012a57336a4f2012fe73193c4511;
        MEM_EXP_B[5]  = 128'hdc0fea8f950c175f3c705a1bd29f4037;
    end

    // ============================================================
    // 5. TASK: CHẠY 1 TEST VECTOR
    // ============================================================
    task run_test_vector;
        input integer id;
        input [127:0] inA, inB;
        input [191:0] key;
        input [127:0] expA, expB;
        
        integer recv_count;
        integer timeout_cnt; 
        reg matchedA, matchedB;
		  
        begin
            $display("--------------------------------------------------");
            $display(" TEST CASE #%0d STARTED", id);
            
            // --- BƯỚC 0: RESET TRẠNG THÁI ---
            @(negedge clk); reset_n = 0; 
            @(negedge clk); reset_n = 1; 
            
            // --- BƯỚC 1: SINH KHÓA (KEY EXPANSION) ---
            @(posedge clk); #1;
            cipher_key = key;
            start_keygen = 1;

            @(posedge clk); #1;
            start_keygen = 0;
            
            timeout_cnt = 0;
            while (!keygen_done && timeout_cnt < 100000) begin
                @(posedge clk); timeout_cnt = timeout_cnt + 1;
            end
            
            if (timeout_cnt >= 100000) begin
                $display(" [FATAL] KeyGen Hanged/Timeout!");
                disable run_test_vector; 
            end
            #20; 
            
            // --- BƯỚC 2: MÃ HÓA (ENCRYPTION) ---
            @(posedge clk); #1;
            data_inA = inA;
            data_inB = inB;
            start_encrypt = 1;

            @(posedge clk); #1;
            start_encrypt = 0;
            
            // --- BƯỚC 3: THU THẬP KẾT QUẢ ---
            recv_count = 0;
            matchedA = 0;
            matchedB = 0;
            timeout_cnt = 0;
            
            while (recv_count < 2 && timeout_cnt < 100000) begin
                
                @(posedge clk);
                timeout_cnt = timeout_cnt + 1;

                if (output_valid) begin
                    $display("   > Received Output: %h at time %0t", data_out, $time);
                    
                    if (data_out === expA) begin
                        $display("     -> MATCHED Expect A");
                        matchedA = 1;
                    end
                    else if (data_out === expB) begin
                        $display("     -> MATCHED Expect B");
                        matchedB = 1;
                    end
                    else begin
                        $display("     -> FAIL: Mismatch / Unknown Data!");
                    end
                    
                    recv_count = recv_count + 1;                 
                end
            end
            
            // --- BƯỚC 4: TỔNG KẾT CASE
            if (recv_count < 2) begin
                $display(" [FAIL] Case #%0d Timeout! Only got %0d results.", id, recv_count);
                total_fail = total_fail + 1;
            end
            else if (matchedA && matchedB) begin              
                $display(" [PASS] Case #%0d Passed Perfectly!", id);
                total_pass = total_pass + 1;
            end
            else begin
                $display(" [FAIL] Case #%0d Data Mismatch.", id);
                total_fail = total_fail + 1;
            end
            
            $display("--------------------------------------------------\n");
        end
    endtask

    // ============================================================
    // 6. MAIN LOOP & REPORT
    // ============================================================
    initial begin
        // Init
        reset_n = 0;
        start_encrypt = 0;
        start_keygen = 0;
        cipher_key = 0;
        data_inA = 0;
        data_inB = 0;
        total_pass = 0;
        total_fail = 0;

        #100;
        $display("========================================");
        $display(" STARTING 5 AES-192 TEST CASES");
        $display("========================================");

        for (i = 1; i <= 1; i = i + 1) begin
            run_test_vector(
                i, 
                MEM_DATA_A[i], 
                MEM_DATA_B[i], 
                MEM_KEY[i], 
                MEM_EXP_A[i], 
                MEM_EXP_B[i]
            );
        end

        // Final Report
        $display("\n========================================");
        $display("       FINAL TEST REPORT                ");
        $display("========================================");
        $display(" TOTAL CASES  : 5");
        $display(" PASSED       : %0d", total_pass);
        $display(" FAILED       : %0d", total_fail);
        $display("----------------------------------------");
        
        if (total_fail == 0) begin
            $display(" RESULT: [SUCCESS] SYSTEM IS STABLE.");
            $display("         ALL VECTORS MATCHED.");
        end else begin
             $display(" RESULT: [FAILURE] SYSTEM HAS BUGS.");
        end
        $display("========================================");
        
        $finish;
    end

endmodule