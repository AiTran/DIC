`timescale 1ns/10ps
module RC4(clk,rst,key_valid,key_in,plain_read,plain_in_valid,plain_in,plain_write,plain_out,cipher_write,cipher_out,cipher_read,cipher_in,cipher_in_valid,done);
    input   clk,rst;
    input   key_valid,plain_in_valid,cipher_in_valid;
    input   [7:0] key_in,cipher_in,plain_in;
    output  reg done;
    output  reg plain_write,cipher_write,plain_read,cipher_read;
    output  [7:0] cipher_out,plain_out;

	reg		activation;
    reg     [7:0]   data_key [0:31];   
    reg     [7:0]   Sbox     [0:63];  
    reg     [7:0]   Sbox_pl     [0:63];  
    reg     [3:0]   state;
    reg     [7:0]   i,j,k1,k2;
    wire     [11:0]  final_data;
	wire     [11:0]  final_data1;
	
	parameter   Size_Key      = 32,
				Size_Sbox        = 64,
				state_sbox = 4'b0000,
				state_mix = 4'b0001,
				state_cipher = 4'b0010,
				state_cipher2 = 4'b0101,
				state_plain = 4'b0110,
				state_plain2 = 4'b1001;

	
assign final_data1  = Sbox_pl[k1[5:0]] + Sbox_pl[k2[5:0]];
assign final_data  = Sbox[k1[5:0]] + Sbox[k2[5:0]];
assign cipher_out       = plain_in ^ Sbox[final_data[5:0]];
assign plain_out       = cipher_in ^ Sbox_pl[final_data1[5:0]];

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            i     <=  8'b0;
        end 
        else begin
            if (key_valid) begin
                if (i > Size_Key)begin
                    i    <= 8'b0;
                end
                else begin
                    data_key[i-1] <= key_in;
                    i    <= i+1;

                end
            end
        end
    end

    always @(posedge clk or posedge rst ) begin
        if (rst) begin
			
            state       <= state_sbox;
            k1              <= 8'b0;
            k2              <= 8'b0;
            plain_write     <= 1'b0;
            cipher_write    <= 1'b0;
            done       <= 1'b0;
            j     <=  8'b0;
			
        end
        else begin
            case(state)
                state_sbox: begin
                    if (j == Size_Sbox) begin
                        state   <= state_mix;
						k2    <= k2 + Sbox[k1] + data_key[k1[4:0]];
                    end
                    else begin
                        Sbox[j] <= j;
                        Sbox_pl[j] <= j;
                        j       <= j+1;
                end
                end

                state_mix: begin
                    Sbox[k1]   <= Sbox[k2[5:0]];
                    Sbox[k2[5:0]]   <= Sbox[k1];
                    Sbox_pl[k1]   <= Sbox_pl[k2[5:0]];
                    Sbox_pl[k2[5:0]]   <= Sbox_pl[k1];
                    if (k1 == Size_Sbox - 1)begin
                        state  <= state_cipher;
                        k1         <= 8'b0;
                        k2         <= 8'b0;
                    end
                    else begin
                        k1         <=  k1 + 1;
                        state  <=  state_sbox;
						
                    end
                end
                //Cipher
                
				state_cipher: begin
					k1     = k1 + 1;
					cipher_write <= 1'b0;
					k2    = k2 + Sbox[k1[5:0]];
					Sbox[k1[5:0]]   <= Sbox[k2[5:0]];
					Sbox[k2[5:0]]   <= Sbox[k1[5:0]];
					state            <= state_cipher2;
					plain_read   <= 1'b1;
					end
				
                state_cipher2: begin
                    plain_read   <= 1'b0;
					cipher_write <= 1'b1;
					state   <= state_cipher;
                    if (!plain_in_valid) begin
                        state <= state_plain;
                        k1 <= 0;
                        k2 <= 0;
						cipher_write <= 1'b0;
                    end
                end

                //  Plain
				state_plain: begin
                    k1     = k1 + 1;
                    plain_write <= 1'b0;
					k2    = k2 + Sbox_pl[k1[5:0]];
					Sbox_pl[k1[5:0]]   <= Sbox_pl[k2[5:0]];
                    Sbox_pl[k2[5:0]]   <= Sbox_pl[k1[5:0]];
                    state            <= state_plain2;
                    cipher_read   <= 1'b1;

				end

                state_plain2: begin
                    cipher_read   <= 1'b0;
					plain_write <= 1'b1;
					state   <= state_plain;
                    if (!plain_in_valid && !cipher_in_valid) begin
                        done <= 1;
						state   <= state_sbox;
                    end
                    
                end
        
            endcase
        end
    end
endmodule

