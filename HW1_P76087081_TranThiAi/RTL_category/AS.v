module AS(sel, A, B, S, O);
	input [3:0] A, B;
	input sel;
	output [3:0] S;
	output O;

	wire	C1;
	wire	C2;
	wire	C3;

	wire	B0;
	wire	B1;
	wire	B2;
	wire	B3;
	
	xor(B0, B[0], sel);
	xor(B1, B[1], sel);
	xor(B2, B[2], sel);
	xor(B3, B[3], sel);
	xor(O, C4, C3);
	
	Full_adder FA0(S[0], C1, A[0], B0, sel);
	Full_adder FA1(S[1], C2, A[1], B1, C1);
	Full_adder FA2(S[2], C3, A[2], B2, C2);
	Full_adder FA3(S[3], C4, A[3], B3, C3);
endmodule

module Full_adder(S, Cout, A, B, Cin);
	output	S;
	output	Cout;
	input	A;
	input	B;
	input	Cin;
	
	wire	w0;
	wire	w1;
	wire	w2;
	
	xor(w0, A, B);
	xor(S, w0, Cin);
	and(w1, w0, Cin);
	and(w2, A, B);
	or(Cout, w1, w2);
endmodule

