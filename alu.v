`timescale 1ns/1ps
module alu
#(parameter [3:0] aluop_AND = 4'b0000,
            aluop_OR = 4'b0001,
	    aluop_ADD = 4'b0010,
	    aluop_SUB = 4'b0110,
	    aluop_LESSTHAN = 4'b0111,
	    aluop_SRL = 4'b1000,
	    aluop_SLL = 4'b1001,
	    aluop_SRA = 4'b1010,
	    aluop_XOR = 4'b1101)
 (output reg[31:0] result, output reg zero, input wire [31:0] op1, input wire [31:0] op2, input wire[3:0] alu_op); //op1 and op2 are 2's complement numbers


// assign result = (alu_op == aluop_sub1) ? (op1 & op2) : //AND
// 		(alu_op == aluop_sub2) ? (op1 | op2) : //OR
// 		(alu_op == aluop_sub3) ? (op1 + op2) : //addition
// 		(alu_op == aluop_sub4) ? (op1 - op2) : //subtraction 
// 		(alu_op == aluop_sub5) ? ($signed(op1) < $signed(op2)) : //'less than' with op1 and op2 turned into signed
// 		(alu_op == aluop_sub6) ? (op1 >> op2[4:0]) : //logical shift right by op2 bits
// 		(alu_op == aluop_sub7) ? (op1 << op2[4:0]) : //logical shift left by op2 bits
// 		(alu_op == aluop_sub8) ? $unsigned(($signed(op1)) >>> op2[4:0]) : //arithmetic shift right by op2 bits where op1 is turned into signed and the result of the shift is turned into unasigned
// 		(alu_op == aluop_sub9) ? (op1 ^ op2): //XOR
// 		32'h0; //default value for unrecognized operation code

always @* begin
  case (alu_op)
    aluop_AND: result = op1 & op2;        //AND
    aluop_OR: result = op1 | op2;         //OR
    aluop_ADD: result = op1 + op2;        //Addition
    aluop_SUB: result = op1 - op2;        //Subtraction 
    aluop_LESSTHAN: result = ($signed(op1) < $signed(op2)) ? 1 : 0;  //'Less than' with op1 and op2 turned into signed
    aluop_SRL: result = op1 >> op2[4:0];  //Logical shift right by op2 bits
    aluop_SLL: result = op1 << op2[4:0];  //Logical shift left by op2 bits
    aluop_SRA: result = $unsigned(($signed(op1) >>> op2[4:0]));  //Arithmetic shift right by op2 bits where op1 is turned into signed and the result of the shift is turned into unsigned
    aluop_XOR: result = op1 ^ op2;        //XOR
    default: result = 32'b0;              //Default value for unrecognized operation code
  endcase
  zero = (result == 32'b0) ? 1 : 0;       //set zero
end

// assign zero = (result == 32'b0) ? 1 : 0; 

endmodule

