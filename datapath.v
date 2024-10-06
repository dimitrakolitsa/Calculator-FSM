module datapath 
#(parameter INITIAL_PC = 32'h00400000)
 (output reg [31:0] PC, output reg [0:0] Zero, output reg [31:0] dAddress, output reg [31:0] dWriteData, output reg [31:0] WriteBackData,
		 input wire clk, input wire rst, input wire [31:0] instr, input wire PCSrc, 
		 input wire ALUSrc, input wire RegWrite, input wire MemToReg, input wire [3:0] ALUCtrl,
		 input wire loadPC, input reg [31:0] dReadData);

reg [31:0] IR;  //instruction register
reg [4:0] rs1, rs2; //source registers
reg [31:0] op1, op2; //operands for the alu
reg [31:0] aluResult; //alu result
reg [31:0] dataFromMem;  //data read from memory
reg [3:0] alu_op;  //alu operation signal

//intermediate wire signals
wire [31:0] op1_wire, op2_wire, AluResult;
wire zero;

always @(posedge clk) begin //synchronous reset
    if (rst) begin
        PC <= INITIAL_PC;
    end else begin
	op1 <= op1_wire;
	op2 <= op2_wire;
	Zero <= zero;
	aluResult <= AluResult;
    end
end

//instantiate rom
INSTRUCTION_MEMORY rom (.clk(clk), .addr(PC[8:0]), .dout(instr));

always @* begin
    IR = instr;
    
end

//calculate the immediate of all types of instructions and do sign extension
reg [31:0] i_imm;
reg [31:0] s_imm;
reg [31:0] b_imm;

always @* begin
    i_imm = {{20{instr[31]}}, instr[31:20]}; //i-type
    s_imm = {{20{instr[31]}}, instr[31:25], instr[11:7]}; //s-type
    b_imm = {{20{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8]}; //b-type
end

reg [31:0] immediate;

always @* begin //depending on instruction opcode, we choose the immediate
  case (instr[6:0])
    7'b0?10111: immediate = i_imm;  
    7'b0100011: immediate = s_imm;
    7'b1100011: immediate = b_imm;
    default: immediate = i_imm;
  endcase
end

//instantiate alu
alu current_alu(.result(AluResult), .zero(zero), .op1(current_regfile.readData1), .op2(op2_wire), .alu_op(ALUCtrl));

//instantiate regfile
regfile current_regfile(.readData1(op1_wire), .readData2(op2_wire), .clk(clk), .readReg1(rs1), .readReg2(rs2), .writeReg(instr[11:7]), .writeData(dWriteData), .write(RegWrite));


//PROGRAM COUNTER
always @(posedge clk) begin //synchronous reset -> not in sensitivity list
    if (rst) begin
        PC <= INITIAL_PC; //reset PC to initial/default value
        IR <= 32'h0;   //reset
    end else if (loadPC) begin
	if (PCSrc) begin : branch //if PCSrc = 1, branch out
		integer branch_offset;
            	if (immediate==b_imm) begin //if b-type instruction
               	  branch_offset = (instr[31] << 12)|(instr[30:25] << 5)|(instr[11:8] << 1)|(instr[7] << 11); //calculate branch_offset and do the necessary shifts
		  PC <= PC + branch_offset; //update PC with PC+branch_offset
            	end
	end else begin 
		PC <= PC + 4;
	    end
    end
    IR <= instr; //fetch instruction
end
       /* if (PCSrc) begin
            PC <= dReadData; //load new PC from dReadData if PCSrc is 1
        end else begin : branch
            integer branch_offset;
            if (immediate==b_imm) begin
               branch_offset = (instr[31] << 12)|(instr[30:25] << 5)|(instr[11:8] << 1)|(instr[7] << 11); //calculate branch_offset and do the necessary shifts
            end
            PC <= PC + branch_offset; //update PC with PC+branch_offset if PCSrc is 0
        end
        end else begin
        PC <= PC + 4; //increment PC by 4 for the next instruction
    end
    //fetch instruction from memory
    IR <= instr;
end */


//DECODING 
always @(posedge clk) begin
    if (rst) begin
        rs1 <= 5'b0;
        rs2 <= 5'b0;
        op1 <= 32'b0;
        op2 <= 32'b0;
        alu_op <= 4'b0;
    end else begin
        //decode instruction by bit-index to get register operands and alu operation
        rs1 <= instr[19:15];
        rs2 <= instr[24:20];
        op1 <= current_regfile.readData1;
	case (ALUSrc) //mux: depending on ALUSrc value, we choose what the op2 will be 
		0 : op2 <= current_regfile.readData2;
		1 : op2 <= immediate;
		default: op2 <= current_regfile.readData2; //default value
	endcase
        alu_op <= ALUCtrl;
    end
end


//ALU OPERATION
always @(posedge clk) begin
    if (rst) begin
        aluResult <= 32'b0;
    end else begin
        //alu operation is determined by ALUCtrl signal
        alu_op <= ALUCtrl;
    end
end

//DATA MEMORY
always @(posedge clk) begin
    if (rst) begin
        dAddress <= 32'b0;
        dataFromMem <= 32'b0;
    end else begin
        dAddress <= aluResult;
        dWriteData <= current_regfile.readData2;
    end
end

//WRITE-BACK
always @(posedge clk) begin
    if (rst) begin
        dAddress <= 32'b0;
        dWriteData <= 32'b0;
        Zero <= 1'b0;
        WriteBackData <= 32'b0;
    end else begin
        //data address for the data memory to write to
        dAddress <= aluResult;

        //mux to select between alu result and data from memory
        if (MemToReg) begin
            //MemToReg = 1 so select data from memory
            dWriteData <= dReadData;
        end else begin
            //MemToReg = 0 so select alu result
            dWriteData <= aluResult;
        end

        Zero <= (aluResult == 32'b0); //shows whether aluResult is 0

        //update WriteBackData
        WriteBackData <= current_regfile.writeData;
    end
end


endmodule
