module MixColumn (
    input wire [127:0] state_in,
    output wire [127:0] state_out
);

    // Hàm nhân 2 trong GF(2^8)
    function [7:0] xtime;
        input [7:0] b;
        begin
            // Nếu bit 7 = 1 thì XOR 1B, ngược lại giữ nguyên
            xtime = {b[6:0], 1'b0} ^ (b[7] ? 8'h1b : 8'h00);
        end
    endfunction

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : COL
            
            // 1. Tách 4 byte của 1 cột
            wire [7:0] s0, s1, s2, s3;
            assign s0 = state_in[127 - (i*32)      -: 8];
            assign s1 = state_in[127 - (i*32 + 8)  -: 8];
            assign s2 = state_in[127 - (i*32 + 16) -: 8];
            assign s3 = state_in[127 - (i*32 + 24) -: 8];

            // 2. Tính biến chung (Shared Variable)
            wire [7:0] tmp, tm, t0, t1, t2, t3;
            
            // Tmp = s0 ^ s1 ^ s2 ^ s3
            assign tmp = s0 ^ s1 ^ s2 ^ s3; 

            // Tính các cặp XOR để đưa vào xtime
            // tm = xtime(s0 ^ s1)
            assign t0 = s0 ^ tmp ^ xtime(s0 ^ s1);
            assign t1 = s1 ^ tmp ^ xtime(s1 ^ s2);
            assign t2 = s2 ^ tmp ^ xtime(s2 ^ s3);
            assign t3 = s3 ^ tmp ^ xtime(s3 ^ s0); // Chú ý vòng lặp về s0

            // 3. Gán kết quả ra Output
            assign state_out[127 - (i*32)      -: 8] = t0;
            assign state_out[127 - (i*32 + 8)  -: 8] = t1;
            assign state_out[127 - (i*32 + 16) -: 8] = t2;
            assign state_out[127 - (i*32 + 24) -: 8] = t3;
            
        end
    endgenerate
endmodule 