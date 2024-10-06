module multicycle
#(parameter INITIAL_PC = 32'h00400000,
//I have 5 states so I will encode them using 3 bits
	    IF_STATE = 3'b000,
            ID_STATE = 3'b001,
            EX_STATE = 3'b010,
	    MEM_STATE = 3'b011,
	    WB_STATE = 3'b100)

 (output reg [31:0] PC, output reg [31:0] dAddress, output reg [31:0] dWriteData, 
  output reg [0:0] MemRead, output reg [0:0] MemWrite, output reg [31:0] WriteBackData,
  input wire clk, input wire rst, input wire [31:0] instr, input reg [31:0] dReadData);

reg [3:0] ALUCtrl; //alu control signal
wire Zero; //is 1 if alu result is 0
reg [0:0] PCSrc;
reg [0:0] ALUSrc;
reg [0:0] RegWrite;
reg [0:0] MemToReg;
reg [0:0] loadPC;


//reg [31:0] op1, op2; //operands for the alu
reg [4:0] rs1, rs2; //source registers
reg [31:0] op1, op2; //operands for the alu
reg [31:0] aluResult; //alu result

//reg [31:0] dataFromMem;  //data read from memory
reg [3:0] alu_op;  //alu operation signal
reg [31:0] op1_intermediate, op2_intermediate;
reg [31:0] din;
reg [31:0] dReadDataH;

always @(posedge clk) begin //synchronous reset
    if (rst) begin
        PC <= INITIAL_PC;
    end else begin
	op1_intermediate <= current_datapath.current_alu.op1;
	op2_intermediate <= current_datapath.current_alu.op2;
	alu_op <= current_datapath.current_alu.alu_op;
	din <= ram.din;
	dReadDataH <= dReadData;
    end
end

//intermediate wire signals
wire [31:0] PC_wire, dAddress_wire, dWriteData_wire, WriteBackData_wire, op1_wire, op2_wire, AluResult;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        PC <= INITIAL_PC;
    end else begin
        PC <= PC_wire;
        dAddress <= dAddress_wire;
        dWriteData <= dWriteData_wire;
        WriteBackData <= WriteBackData_wire;
	op1 <= op1_wire;
	op2 <= op2_wire;
	aluResult <= AluResult;
    end
end

//instantiate alu
//alu current_alu(.result(AluResult), .zero(Zero), .op1(current_regfile.readData1), .op2(op2_wire), .alu_op(ALUCtrl));

//instantiate regfile
//regfile current_regfile(.readData1(op1_wire), .readData2(op2_wire), .clk(clk), .readReg1(rs1), .readReg2(rs2), .writeReg(instr[11:7]), .writeData(dWriteData), .write(RegWrite));


//instantiate datapath
datapath current_datapath(.PC(PC_wire), .Zero(Zero), .dAddress(dAddress_wire), .dWriteData(dWriteData_wire), .WriteBackData(WriteBackData_wire), .clk(clk),  
			  .rst(rst), .instr(instr), .PCSrc(PCSrc), .ALUSrc(ALUSrc), .RegWrite(RegWrite), .MemToReg(MemToReg),
			  .ALUCtrl(ALUCtrl), .loadPC(loadPC), .dReadData(dReadData));

//instantiate ram
DATA_MEMORY ram (.clk(clk), .we(MemWrite), .addr(dAddress[8:0]), .din(dWriteData), .dout(dReadData)); 

//ALUCtrl
reg [6:0] opcode; 
reg [2:0] funct3;
reg [6:0] funct7;

always @* begin
    opcode = instr[6:0]; //extract opcode, funct3, and funct7 fields from instruction 
    funct3 = instr[14:12];
    funct7 = instr[31:25];
end

always @* begin //find the alu operation that must be executed based on the given instr
  case (opcode) //5 cases for opcode (7 bits)
    7'b0110011: 
      case (funct3)
        3'b000:
          case (funct7)
            7'b0000000: ALUCtrl = 4'b0010; //add
            7'b0100000: ALUCtrl = 4'b0110; //sub
            default: ALUCtrl = 4'b0000;
          endcase
        3'b001: ALUCtrl = 4'b0101; //sll
        3'b010: ALUCtrl = 4'b0101; //slt
        3'b100: ALUCtrl = 4'b0111; //xor
        3'b101: 
	  case (funct7)
            7'b0000000: ALUCtrl = 4'b1000; //srl
            7'b0100000: ALUCtrl = 4'b1100; //sra
            default: ALUCtrl = 4'b0000;
          endcase
	3'b110: ALUCtrl = 4'b0001; //or
	3'b111: ALUCtrl = 4'b0010; //and
      endcase
    7'b0010011:
      case (funct3)
        3'b000: ALUCtrl = 4'b0011; //addi
        3'b010: ALUCtrl = 4'b0100; //slti
        3'b100: ALUCtrl = 4'b1001; //xori
        3'b110: ALUCtrl = 4'b1101; //ori
        3'b111: ALUCtrl = 4'b0010; //andi
        3'b001: ALUCtrl = 4'b0101; //slli
	3'b101:
	  case (funct7)
	    7'b0000000: ALUCtrl = 4'b1000; //srli
            7'b0100000: ALUCtrl = 4'b1100; //srai
            default: ALUCtrl = 4'b0000;
          endcase
      endcase
    7'b0100011:
	ALUCtrl = 4'b0010; //sw
    7'b0000011:
	ALUCtrl = 4'b1000; //lw
    7'b1100011:
	ALUCtrl = 4'b0110; //beq
    default: ALUCtrl = 4'b0000;

endcase
end

reg [31:0] immediate;

always @* begin //depending on opcode, we choose the immediate -> only for lw, sw and alu-immediate
  case (opcode)
    7'b0000011: immediate = instr[31:20]; //lw
    7'b0100011: immediate = {instr[31:25], instr[11:7]}; //sw
    7'b1100011: immediate = instr[31:20]; //addi, slti, xori, ori, andi, slli, srli, srai
    default: immediate = instr[31:20];
  endcase
end

//ALUSrc
always @(posedge clk) begin
    if (rst) begin
        ALUSrc <= 1'b0; //reset
    end else begin
        //mux: depending on ALUSrc value, choose what op2 will be
        if (ALUSrc == 0) begin
            op2 <= current_datapath.current_regfile.readData2; //if ALUSrc is 0, use the value from the register file
        end else begin
            op2 <= immediate; //if ALUSrc is 1, use the immediate value
        end

        alu_op <= ALUCtrl;
    end
end

//MemRead -> for load instructrions (lw)
//MemWrite -> for store instructions (sw)

//RegWrite -> if 1, write to regfile
//MemToReg -> 1 when we have lw

//loadPC -> 1 when in WriteBack stage in order to update the PC (before the Instruction Fetch stage)
//PCSrc -> depends on branch and zero


reg [2:0] current_state, next_state; //will hold currect & next state

always @(posedge clk) begin : CURRENT_STATE
	if (rst) begin
	   current_state <= IF_STATE;
	end else begin 
	   current_state <= next_state;
	end
end

always @(posedge clk) begin : NEXT_STATE
	if (rst) begin
	   next_state = IF_STATE; //back to the start -> fetch another instruction
	end else begin 
	   case (current_state)
         IF_STATE:
            next_state = ID_STATE; //IF_STATE to ID_STATE
         ID_STATE:
            if (opcode == 7'b1100011) begin //ID_STATE to EX_STATE or back to IF_STATE
               //opcode for beq (branch) -> if there is a branch -> Branch = 1
               if (current_datapath.Zero) begin
                  next_state = IF_STATE; //follow branch
               end else begin
                  next_state = EX_STATE;//don't follow branch & go to the next stage
               end
            end else if (opcode == 7'b0000011 || opcode == 7'b0100011) begin //opcode for lw or sw instruction
               next_state = MEM_STATE; //go to MEM_STATE
            end else begin
               next_state = EX_STATE; //if no branch and no lw/sw, go to EX_STATE
            end

         EX_STATE:
            if (MemWrite == 1'b1 || MemRead == 1'b1) begin
		next_state = MEM_STATE;
            end else begin
		next_state = EX_STATE; //stay here 
	    end

         MEM_STATE:
	    if (current_datapath.MemToReg == 1'b1) begin
		next_state = WB_STATE; //MEM_STATE to WB_STATE
	    end else begin
		next_state = MEM_STATE; //stay here
            end

         WB_STATE:
            next_state = IF_STATE; //WB_STATE back to IF_STATE

         default:
            next_state = IF_STATE; //default state
      endcase
   end
end


integer branch_offset;

always @(posedge clk) begin : OUTPUT_LOGIC
 case (current_state)
    IF_STATE: begin
      if (opcode == 7'b1100011 && current_datapath.Zero) begin //if there is a beq instr and zero signal from the alu is 1
	branch_offset = (instr[31] << 12)|(instr[30:25] << 5)|(instr[11:8] << 1)|(instr[7] << 11); //calculate branch_offset and do the necessary shifts
	PC <= PC + branch_offset; //update PC with PC+branch_offset
      end else begin
        PC <= PC + 4; //if no branch, increment PC by 4 for the next instruction
      end
    end

    ID_STATE: begin
      case (opcode)
        7'b1100011: begin //if beq instruction
          PCSrc <= 1'b1; //set PCSrc to 1 -> enable PC update in the next state
          ALUSrc <= 1'b0; //register value is used as op2 for the ALU
	  end

        7'b0000011, 7'b0100011: //lw & sw instructions
          ALUSrc <= 1'b1; //immediate is used as op2 for the ALU
        default: ALUSrc <= 1'b0;
      endcase
    end

     EX_STATE: begin
      //alu operation
      op1_intermediate <= current_datapath.current_regfile.readData1;
      op2_intermediate <= op2;
      alu_op <= ALUCtrl;

      //signals for the next stage (MEM_STATE)
      MemRead <= (opcode == 7'b0000011) ? 1'b1 : 1'b0; //if lw -> set MemRead to 1 to enable 'reading' from memory
      MemWrite <= (opcode == 7'b0100011) ? 1'b1 : 1'b0; //if sw -> set MemWrite to 1 to enable 'writing' to memory
      dAddress <= current_datapath.current_alu.result; //set data memory address
      dWriteData <= current_datapath.current_regfile.readData2; //data to be written to memory
      end

    MEM_STATE: begin //access memory
      if (MemRead) begin //'reading' from memory
        dReadDataH <= ram.dout; //read data to be read from the data address
      end
      else if (MemWrite) begin //'writing' to memory
	//current_datapath.dWriteData <= current_datapath.current_regfile.readData2;
	din <= current_datapath.current_regfile.readData2; //current_datapath.dAddress;
      end

      //signals for the next stage (WB_STATE)
      RegWrite <= (opcode == 7'b0000011 || opcode == 7'b0010011 || opcode == 7'b1100011) ? 1'b1 : 1'b0; //RegWrite=1 for all instructions except beq and sw -> these don't write back
      MemToReg <= (opcode == 7'b0000011) ? 1'b1 : 1'b0; //if lw -> MemToReg=1
      WriteBackData <= (MemToReg) ? dReadData : current_datapath.current_alu.result; //data to be written back to regfile
    end

    WB_STATE: begin //write back to regfile
      if (RegWrite) begin
        current_datapath.dWriteData <= WriteBackData; //pass the write back data to regfile
      end

      //signals for the next stage (IF_STATE)
      loadPC <= 1'b1; //update PC in the next cycle
      PCSrc <= (opcode == 7'b1100011 && current_datapath.Zero) ? 1'b1 : 1'b0; //beq instruction -> choose the correct value for next PC
    end

 endcase
end
         

endmodule