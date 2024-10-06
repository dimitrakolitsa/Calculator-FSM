module calc (output reg[15:0] led, 
	     input wire clk, input wire btnc, input wire btnl, input wire btnu, input wire btnr, input wire btnd, input wire[15:0] sw);
reg [15:0] accumulator; 
wire [3:0] alu_op_n; //the alu function that is calculated by the decoder based on the btnr, btnl, btnc
wire zero;

//instantiate decoder
decoder current_decoder(.alu_op_n(alu_op_n), .btnr(btnr), .btnl(btnl), .btnc(btnc)); //calculates the alu function

wire [31:0] current_result; //the alu result
reg [31:0] op1, op2; //the two operands of the alu

always @(accumulator) begin
  op1 = {{16{accumulator[15]}}, accumulator};
end

always @(sw) begin
    op2 = {{16{sw[15]}}, sw}; //sign extension

end

//instantiate alu
alu current_alu(.result(current_result), .zero(zero), .op1(op1), .op2(op2), .alu_op(current_decoder.alu_op_n));


always @(posedge clk, posedge btnu) begin
    if (btnu) begin
      accumulator <= 16'b0; //reset accumulator on btnu press
    end
    else if (btnd) begin
      accumulator <= current_result[15:0];  //update accumulator with the 16 lower bits of the alu result
    end
    led <= accumulator; //update led with the accumulator on the posedge of clk
  end

endmodule

