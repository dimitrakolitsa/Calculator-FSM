`timescale 1ns/1ps

module multicycle_TB;

//inputs
reg clk;
reg rst;
reg [31:0] instr;
wire [31:0] dReadData;

//outputs
wire [31:0] PC;
wire [31:0] dAddress;
wire [31:0] dWriteData;
wire [0:0] MemRead;
wire [0:0] MemWrite;
wire [31:0] WriteBackData;

//instantiate multicycle
multicycle uut (.PC(PC), .dAddress(dAddress), .dWriteData(dWriteData), .MemRead(MemRead), .MemWrite(MemWrite), 
		.WriteBackData(WriteBackData), .clk(clk), .rst(rst), .instr(instr), .dReadData(dReadData) );

wire [31:0] instr_internal; //intermediate reg for initial block

//instantiate rom
INSTRUCTION_MEMORY rom (.clk(clk), .addr(PC), .dout(instr_internal));

assign instr_internal = instr ; //connect instr_internal to instr


//clock
always begin
    #5 clk = ~clk; //10t.u. clock period
end

always @(posedge clk) begin
    $display("Time: %0t, State: %0d", $time, uut.current_state);
end

initial begin
clk = 0;
rst = 1; //push reset button

    //read instructions from file
    //$readmemh("rom_bytes.data", uut.current_datapath.rom.ROM);

    //release reset after a period
    #10 rst = 0;

repeat (5) begin 
	#10; //10t.u. delay
	$readmemh("rom_bytes.data", rom.ROM); //read instructions from instruction memory

	$display("Time: %0t", $time);
end


    $stop; //stop simulation
end

endmodule

