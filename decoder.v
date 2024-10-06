module decoder (output wire [3:0] alu_op_n, input wire btnr, input wire btnl, input wire btnc);

xor X1 (x1, btnl, btnc);
and A1 (a1, btnr, x1);
not N1 (Nbtnr, btnr);
and A2 (a2, btnl, Nbtnr);
or O1 (out0, a1, a2);

assign alu_op_n[0] = out0;

not N2 (Nbtnc, btnc);
not N3 (Nbtnl, btnl);
and A3 (a3,  Nbtnc, Nbtnl);
and A4 (a4, btnr, btnl);
or O2 (out1, a3, a4);

assign alu_op_n[1] = out1;

xor X2 (x2, btnr, btnl);
or O3 (o3, x2, a4);
and A5 (out2, o3, Nbtnc);

assign alu_op_n[2] = out2;

xnor XN1 (xn1, btnc, btnr);
and A6 (a6, btnc, Nbtnr);
or O4 (o4, a6, xn1);
and A7 (out3, btnl, o4);

assign alu_op_n[3] = out3;



endmodule

