`timescale 1ns / 10ps
module div(out, in1, in2, dbz);
parameter width = 8;
input  	[width-1:0] in1; // Dividend
input  	[width-1:0] in2; // Divisor
output  [width-1:0] out; // Quotient
output dbz;


/********************************

You need to write your code at here

********************************/

reg	[width-1:0] out;
reg	[width-1:0] a;
reg	[width-1:0] b;
reg	[width-1:0] nb;
reg	[width:0] P;
reg				dbz;
integer	i;

always @ (in1, in2)
begin
	a = in1;
	b = in2;
	P = 9'b0;
	
	if( b == 0) begin
		dbz = 1; end
	
	for(i=0; i<8; i = i+1) begin
		P[8:0] = {P[7:0], a[7]}; //shift left
		a[7:1] = a[6:0]; // shift left in1
		P=P-b;
		if(P[8] == 1) begin
			a[0] = 0;
			P=P+b;
		end
		else begin
			a[0] = 1;
		end
	end
	out[7:0] = a[7:0];
end

endmodule