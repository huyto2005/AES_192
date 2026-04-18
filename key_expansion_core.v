module key_expansion_core (
	input clk, 
	input start, 
	input reset_n, 
	input [191:0] key_in, 
	 
	output reg bram_we, 
	output reg [5:0] bram_addr, 
	output reg [31:0] bram_data, 
	output reg key_done
);

parameter S_IDLE    = 6'b000001; // trạng thái chờ
parameter S_INIT    = 6'b100000; // nạp key ban đầu vào 6 word buffer
parameter S_LOAD    = 6'b010000; // nạp 6 word buffer vào bram
parameter S_GEN_G   = 6'b001000; 
parameter S_GEN_XOR = 6'b000010; 
parameter S_DONE    = 6'b000100; 

    
	reg [2:0] load_cnt;
	reg [5:0] addr;			// addr của bram
   reg [31:0] wbuf [0:5];
	reg [5:0] current_state, next_state;
	reg [3:0] idx_rcon;
	reg [31:0] next_w0_reg;
	
	
   wire [31:0] g_out;
   wire [31:0] next_word;
	wire [31:0] w0 = wbuf[0];
   wire [31:0] w1 = wbuf[1];
   wire [31:0] w2 = wbuf[2];
   wire [31:0] w3 = wbuf[3];
	wire [31:0] w4 = wbuf[4];
   wire [31:0] w5 = wbuf[5];

g_func u_g (
		.word_in(w5),
		.word_out(g_out),
		.rcon_idx(idx_rcon)
);
	 
   // Tính 6 từ của khóa tiếp theo
   wire [31:0] next_w0 = next_w0_reg;
   wire [31:0] next_w1 = w1 ^ next_w0_reg;
   wire [31:0] next_w2 = w2 ^ next_w1;
   wire [31:0] next_w3 = w3 ^ next_w2;
	wire [31:0] next_w4 = w4 ^ next_w3;
   wire [31:0] next_w5 = w5 ^ next_w4;
	 
always @(*) begin
	key_done = 0;
	next_state = current_state;
	case(current_state)
			S_IDLE: begin
					key_done = 1'b0;
					if(start) begin
							next_state = S_INIT;
					end
			end
			S_INIT: begin
					next_state = S_LOAD;
			end
			S_LOAD: begin
				if(load_cnt < 3'd5) begin
						if(addr == 6'd51) begin
								next_state = S_DONE;
						end
						else begin 
								next_state = S_LOAD;
						end
				end
				else begin
						next_state = S_GEN_G;
				end
			end
			S_GEN_G: begin
					next_state = S_GEN_XOR;
			end
			S_GEN_XOR: begin
					next_state = S_LOAD;
			end
			S_DONE: begin
					key_done = 1'b1;
					if(!start) next_state = S_IDLE;
			end
			default: next_state = current_state;
	endcase
end
    
always @(posedge clk or negedge reset_n) begin
		if(!reset_n) begin
				current_state <= S_IDLE;
				load_cnt <= 3'b0;
				addr <= 6'b0;
				idx_rcon <= 4'b1;
				bram_we <= 1'b0;
				next_w0_reg <= 32'b0;
		end
		else begin
		
				current_state <= next_state;
			
				if(current_state == S_INIT) begin
						wbuf[0] <= key_in[191:160];
						wbuf[1] <= key_in[159:128];
						wbuf[2] <= key_in[127:96];
						wbuf[3] <= key_in[95:64];
						wbuf[4] <= key_in[63:32];
						wbuf[5] <= key_in[31:0];
						idx_rcon <= 1;
				end
				else if(current_state == S_LOAD) begin	
						load_cnt <= load_cnt + 1;
						addr <= addr + 1;
						bram_addr <= addr;
						bram_we <= 1;
						bram_data <= wbuf[load_cnt];
						
				end
				else if(current_state == S_GEN_G) begin
						idx_rcon <= idx_rcon + 1;
						bram_we <= 1'b0;
						load_cnt <= 3'b0;
						next_w0_reg <= w0 ^ g_out;
				end
				else if(current_state == S_GEN_XOR) begin
						wbuf[0] <= next_w0;
						wbuf[1] <= next_w1;
						wbuf[2] <= next_w2;
						wbuf[3] <= next_w3;
						wbuf[4] <= next_w4;
						wbuf[5] <= next_w5;
						
				end
				else begin
						bram_we <= 1'b0;
				end	
		end
end
endmodule