module AES_core(
   input wire clk,
   input wire reset_n,
   input wire start_encrypt,
   input wire [127:0] data_in,
   input wire [127:0] round_key,
	
	output wire load_B_ena,
   output reg done,
   output reg [3:0] bram_rd_addr,
   output reg bram_re,
   output reg [127:0] data_out,
   output reg output_valid
); 

   parameter S_IDLE    = 5'b00001;  
   parameter S_PREPARE = 5'b00010; 
	parameter S_PREPARE_2 = 5'b00100;
   parameter S_RUN     = 5'b10000;               
   parameter S_DONE    = 5'b01000;         

   reg [4:0] current_state, next_state;   
   reg [127:0] stage1_reg; 
   reg [127:0] stage2_reg; 
   reg cycle_cnt; // 0: Block A in Stage 1; 1: Block B in Stage 1
	reg [3:0] round_cnt;
    
   wire [127:0] subbytes_out;
   wire [127:0] shiftrows_out;
   wire [127:0] mixcolumn_out;
   wire [127:0] addroundkey_out;
   wire [127:0] shiftmix_mux;      
   wire [127:0] input_addroundkey; 
   wire is_last_round;
	wire is_first_round;
   
    // --- Instantiations ---
   sub_bytes u_subbytes (
       .state_in(stage1_reg),
       .state_out(subbytes_out)
   );
   shift_rows u_shiftrows (
       .state_in(stage2_reg),
       .state_out(shiftrows_out)
   );
   MixColumn u_mixcolumn (
       .state_in(shiftrows_out),
       .state_out(mixcolumn_out)
   );
   add_round_key u_addroundkey(
       .state_in(input_addroundkey),
       .key_in(round_key),
       .state_out(addroundkey_out)
   );

	assign is_last_round = (round_cnt == 4'd12);
	assign is_first_round = (round_cnt == 4'b0);
	assign shiftmix_mux = (is_last_round) ? shiftrows_out : mixcolumn_out;
	assign input_addroundkey = (is_first_round) ? data_in : shiftmix_mux;
	assign load_B_ena = (is_first_round && cycle_cnt == 1);

always @(*) begin
		next_state = current_state;
      done = 1'b0;
      case (current_state)
				S_IDLE: begin
						if(start_encrypt) begin 
								next_state = S_PREPARE;
						end
            end
				S_PREPARE: begin
						next_state = S_PREPARE_2;
				end
				S_PREPARE_2: begin
						next_state = S_RUN;
				end
            S_RUN : begin
                if(is_last_round && cycle_cnt == 1'b1)
                    next_state = S_DONE;
            end
            S_DONE: begin
                done = 1'b1;
                if (!start_encrypt)
                    next_state = S_IDLE; 
				end
		endcase
end

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		round_cnt <= 4'b0;
      cycle_cnt <= 1'b0;
      current_state <= S_IDLE;
      bram_re <= 0;
      bram_rd_addr <= 0;
      output_valid <= 0;
	end
   else begin
      current_state <= next_state;
		output_valid <= 0;	
            
      if (current_state == S_IDLE) begin
			round_cnt <= 0;
			cycle_cnt <= 0;
			if(start_encrypt) begin
					bram_re <= 1;
					bram_rd_addr <= 0;
			end
      end
		else if (current_state == S_PREPARE_2) begin
			bram_rd_addr <= 4'd1; // Get Key 1
			bram_re <= 1;
		end
      else if(current_state == S_RUN) begin
			stage1_reg <= addroundkey_out;
			stage2_reg <= subbytes_out;
               
			if(is_last_round) begin
					output_valid <= 1;          
					bram_re <= 0;                
			end
			else begin 
				if(cycle_cnt == 1'b1) begin
					bram_rd_addr <= round_cnt + 4'd2;
					bram_re <= 1;
					round_cnt <= round_cnt + 4'd1;
				end
			end

         if (cycle_cnt == 1'b0)
					cycle_cnt <= 1'b1;
         else 
					cycle_cnt <= 1'b0;
         end
			
			data_out <= addroundkey_out; 
   end
end
            
endmodule 

// 44616920486F630000000000000000
// 54686F6E672054696E000000000000
