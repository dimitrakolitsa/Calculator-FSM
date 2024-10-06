`timescale 1ns/1ps
module regfile (output wire [31:0] readData1, output wire [31:0] readData2,
		input wire clk, input reg [4:0] readReg1, input reg [4:0] readReg2, 
		input wire [4:0] writeReg, input reg [31:0] writeData, input wire write);

reg [31:0] registers [0:31]; //32x32 bit register file array -> has 32 vectors of 32 bits each
reg [31:0] internalReadData1; //use them in order to keep readData1 & readData2 as wire types and be able to connect them to output ports
reg [31:0] internalReadData2;

//initialize all registers vectors to 0
initial begin : init
   integer i;
   for (i=0; i<32; i=i+1) begin
     registers[i] = 32'b0;
   end
end

//read & write
always @(posedge clk) begin
    internalReadData1 <= registers[readReg1];
    internalReadData2 <= registers[readReg2];

   if (write && (writeReg != readReg1) && (writeReg != readReg2)) begin
     registers[writeReg] <= writeData;
   end
    //ignore write when writeReg address is the same as one of the readReg1 and readReg2 addresses
end

  assign readData1 = internalReadData1;
  assign readData2 = internalReadData2;


endmodule