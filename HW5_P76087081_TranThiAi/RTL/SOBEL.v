`timescale 1ns/10ps
module  SOBEL(clk,reset,busy,ready,iaddr,idata,cdata_rd,cdata_wr,caddr_rd,caddr_wr,cwr,crd,csel	);
	input					clk;
	input					reset;
	output  				busy;	
	input					ready;	
	output 		[16:0]  	iaddr;
	input  		[7:0]		idata;	
	input		[7:0]		cdata_rd;
	output		 [7:0]		cdata_wr;
	output 		[15:0]		caddr_rd;
	output 	 	[15:0]		caddr_wr;
	output	reg 			cwr,crd;
	output 	reg [1:0]		csel;
	
parameter   idle 			= 3'b000,
            State_Kernel1   = 3'b001,
            State_Kernel2   = 3'b010,
            State_Kernel3   = 3'b011,
            State_SobelX   	= 3'b100,
            State_SobelY   	= 3'b101,
            state_comb   	= 3'b110,
            state_fin  		= 3'b111;
parameter	Val1			= 2'b01,
			Val2			= 2'b10,
			Val3			= 2'b11;
parameter	K1				= 10'hff,
			K2				= 8'hff,
			K3				= 17'h204,
			K4				= 17'h206,
			K5				= 17'h102,
			K6				= 17'h100,
			K7				= 17'h104;
			
reg 			check;
reg 			State_Kernel1_st;
reg 			State_Kernel1_done;
reg 			State_Kernel2_st;
reg 			State_Kernel2_done;
reg 			State_Kernel3_st;
reg 			State_Kernel3_done;
reg 			State_SobelX_en;
reg 			State_SobelY_en;
reg 			state_comb_en;
reg 			count_inp;
reg 			shift;
wire 			test;
reg 			total_count;
reg 	[2:0] 	state, next_state;
reg 	[16:0]	row1_fir;
reg 	[16:0]	row2_fir;
reg 	[16:0]	row3_fir;
reg 	[7:0] 	store_data[0:8];
reg 	[16:0]	count;
reg 	[16:0]	count_add;
reg 	[16:0]	row1;
reg 	[16:0]	row2;
reg 	[16:0]	row3;
wire 	[1:0]	val;
reg 	[16:0] 	total_cnt;
reg 	[7:0]	sobelX_fun;
reg 	[7:0]	sobelY_fun;
reg 	[10:0]	sobelX;
reg 	[10:0]	sobelY;
wire 	[10:0]	Result_sobelX;
wire 	[10:0]	Result_sobelY;
wire 	[8:0]	sobel_Comb;
reg 	[10:0]	sobelX_reg;
reg 	[10:0]	sobelY_reg;
reg 	[8:0]	sobel_Comb_reg;
integer i;

assign 	caddr_wr 	= count;
assign 	sobel_Comb 	= sobelX_fun + sobelY_fun;
assign 	iaddr 		= (State_Kernel1_st)?row1:(State_Kernel2_st)?row2:(State_Kernel3_st)?row3:17'b0;
assign 	cdata_wr 	= (State_SobelY_en)?(sobelX_reg[10]==1'b1)?8'b0:(sobelX_reg[9:0]>K1)?K2:sobelX_reg[7:0]:(state_comb_en)?(sobelY_reg[10]==1'b1)?8'b0:(sobelY_reg[9:0]>K1)?K2:sobelY_reg[7:0]:(count_inp)?(sobel_Comb_reg[8:1] + sobel_Comb_reg[0]):8'b0;
assign	val = (State_SobelY_en)?(sobelX_reg[10]==1'b1)?2'b01:(sobelX_reg[9:0]>K1)?2'b10:2'b11:(state_comb_en)?(sobelY_reg[10]==1'b1)?2'b01:(sobelY_reg[9:0]>K1)?2'b10:2'b11:2'b00;
assign 	Result_sobelX = sobelX;
assign 	Result_sobelY = sobelY;
assign 	busy = (reset)?1'b0:(ready)?1'b1:(count == 17'h10000)?1'b0:busy;
assign test		= (total_cnt == count_add || total_cnt == count_add + 1'b1)?1'b1:1'b0;

always @(posedge clk or posedge reset)begin
    if(reset)begin
		sobelX_reg 		<= 11'b0;
        sobelY_reg 		<= 11'b0;
        sobel_Comb_reg 	<= 9'b0;
		count 			<= 17'b0;
		state 			<= idle;
    end
    else begin
		sobelX_reg 		<= Result_sobelX;
        sobelY_reg 		<= Result_sobelY;
        sobel_Comb_reg 	<= sobel_Comb;
		state 			<= next_state;
		if(total_count&&~test)begin
            count 		<= count + 1'b1;
        end
    end
end

always @(*) begin
    next_state <= state;
    case(state)
        idle: next_state <= State_Kernel1;
        State_Kernel1:next_state <= State_Kernel1_done ? State_Kernel2 : State_Kernel1;
        State_Kernel2:next_state <= State_Kernel2_done ? State_Kernel3 : State_Kernel2;
        State_Kernel3:next_state <= State_Kernel3_done ? State_SobelX : State_Kernel3;
        State_SobelX: next_state <= State_SobelY;
        State_SobelY:next_state	<= state_comb;
        state_comb:next_state 	<= state_fin;
        state_fin:next_state 	<= (count != 17'h10000)?(check == 1'b1)?State_Kernel1:state_fin:idle;
    endcase
end

always @(*) begin
    cwr <= 1'b0;
    crd <= 1'b0;
    State_Kernel1_st 	<= 1'b0;
    State_Kernel1_done 	<= 1'b0;
    State_Kernel2_st 	<= 1'b0;
    State_Kernel2_done 	<= 1'b0;
    State_Kernel3_st 	<= 1'b0;
    State_Kernel3_done 	<= 1'b0;
    State_SobelX_en 	<= 1'b0;
    State_SobelY_en 	<= 1'b0;
    state_comb_en 		<= 1'b0;
    shift 				<= 1'b0;
    csel 				<= 2'b0;
    total_count 		<= 1'b0;
    count_inp 			<= 1'b0;
	sobelX 		<= store_data[0] - store_data[2] + (store_data[3]<<1) - (store_data[5]<<1) + store_data[6] - store_data[8]; 
    sobelY 		<= store_data[0] + (store_data[1]<<1) + store_data[2] - store_data[6] - (store_data[7]<<1) - store_data[8];
    case(state)
        idle:begin
        end
        State_Kernel1:begin 
            State_Kernel1_st 	<= 1'b1;  
			shift 	<= 1'b1;
			State_Kernel1_done 	<= (row1 == row1_fir)? 1'b1: 1'b0;
        end
        State_Kernel2:begin
            State_Kernel2_st 	<= 1'b1;
			shift 	<= 1'b1;
			State_Kernel2_done 	<= (row2 == row2_fir)? 1'b1: 1'b0;
        end
        State_Kernel3:begin
            State_Kernel3_st 	<= 1'b1;
			shift 	<= 1'b1;
			State_Kernel3_done 	<= (row3 == row3_fir)? 1'b1: 1'b0;
        end
        State_SobelX:begin
            State_SobelX_en 	<= 1'b1;
			cwr	 	<= (test)?1'b0: 1'b1;
        end
        State_SobelY:begin
            State_SobelY_en 	<= 1'b1;
			csel 	<= 2'b01;
			cwr 	<= (test)?1'b0: 1'b1;
        end
        state_comb:begin
            state_comb_en		 <= 1'b1;
			csel 	<= 2'b10;
			cwr 	<= (test)?1'b0: 1'b1;
        end
        state_fin:begin
            count_inp 	<= 1'b1;
			cwr 		<= (test)? 1'b0: 1'b1;
			total_count <= (check==1'b1) ?1'b1: 1'b0;
            csel 		<= 2'b11;
        end
    endcase
end

always @(posedge clk or posedge reset)begin
    if(reset)begin
		row1 		<= 17'b0;
		row1_fir 	<= 17'd2;
		row2_fir 	<= K7; 
		count_add 	<= K6;
		check 		<= 1'b0;
		total_cnt 	<= 17'b0;
        row2 		<= K5;
		row3_fir 	<= K4;
		row3 		<= K3;
		sobelX_fun 	<= 8'b0;
        sobelY_fun 	<= 8'b0;
		for(i = 0; i<9 ;i = i+1 )begin
            store_data[i] <= 12'b0;
        end
    end
    else begin
		check 		<= ~check;
		total_cnt 	<=(total_count)?total_cnt + 1'b1: total_cnt;
		row1_fir 	<= (State_Kernel1_st)?(row1 == row1_fir)?row1_fir + 1'b1:row1_fir:row1_fir;
		row2_fir 	<= (State_Kernel2_st)?(row2 == row2_fir )?row2_fir + 1'b1:row2_fir:row2_fir;
		count_add 	<= (total_count)?(test)?(total_cnt == count_add + 1'b1)?count_add+ K5:count_add:count_add:count_add;
		row1 		<= (State_Kernel1_st)?(row1 < row1_fir)?row1 + 1'b1:row1: row1_fir - 2'd2;
		row3 		<= (State_Kernel3_st)?(row3<row3_fir)?row3 + 1'b1:row3: row3_fir - 2'd2;
		row2 		<= (State_Kernel2_st)?(row2 < row2_fir)?row2 + 1'b1:row2: row2;
		row3_fir 	<= (State_Kernel3_st)?(row3 == row3_fir)?row3_fir + 1'b1:row3_fir: row3_fir;
		if(state_comb_en) begin
        case(val)
            Val1:sobelY_fun <= 8'b0;
            Val2:sobelY_fun <= K2; 
            Val3:sobelY_fun <= sobelY[7:0];
		endcase
		end
		if(State_SobelY_en) begin
		case(val)
			Val1: sobelX_fun <= 8'b0;
			Val2: sobelX_fun <= K2;
			Val3: sobelX_fun <= sobelX[7:0];
			endcase
		end
		if(shift)begin
            store_data[8] <= idata;
            for(i=0; i<8; i=i+1)begin
                store_data[i] <= store_data[i+1];
            end
        end
        else begin
            row2 	<= row2_fir - 2'd2;
        end
    end
end
endmodule
