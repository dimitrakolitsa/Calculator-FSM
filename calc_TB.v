`timescale 1ns/1ps
module calc_TB;

//inputs
reg clk;
reg btnc, btnl, btnu, btnr, btnd;
reg [15:0] sw;

//outputs
wire [15:0] led;

//instantiate calc module
calc dut(.led(led), .clk(clk), .btnc(btnc), .btnl(btnl), .btnu(btnu), .btnr(btnr), .btnd(btnd), .sw(sw));


initial begin //start clock
    clk = 0;
end
always begin
    #5 clk = ~clk; //10 t.u. clock period
end


initial begin
    //start with all 0
    btnc = 0;
    btnl = 0;
    btnu = 0;
    btnr = 0;
    btnd = 0;
    sw = 16'b0;

    //$dumpfile("dump.vcd");
    //$dumpvars(0, calc_TB);

    //test case 1
    btnu = 1; //push reset 
    #20; //wait for 2 periods to apply reset
    btnu = 0; //release reset
    btnd = 1; //update the accumulator
    #10;
    btnd = 0; //release btnd


    //test case 2
    #5;
    btnl = 0;
    btnc = 1;
    btnr = 1;
    sw = 16'h1234;
    btnd = 1; //update the accumulator
    #5;
    btnd = 0; //release


    //test case 3
    #5;
    btnl = 0;
    btnc = 1;
    btnr = 0;
    sw = 16'h0ff0;
    btnd = 1; //update the accumulator
    #5;
    btnd = 0;


    //test case 4
    #5;
    btnl = 0;
    btnc = 0;
    btnr = 0;
    sw = 16'h324f;
    btnd = 1; //update the accumulator
    #5;
    btnd = 0;


    //test case 5
    #5;
    btnl = 0;
    btnc = 0;
    btnr = 1;
    sw = 16'h2d31;
    btnd = 1; //update the accumulator
    #5;
    btnd = 0;


    //test case 6
    #5;
    btnl = 1;
    btnc = 0;
    btnr = 0;
    sw = 16'hffff;
    btnd = 1; //update the accumulator
    #5;
    btnd = 0;


    //test case 7
    #5;
    btnl = 1;
    btnc = 0;
    btnr = 1;
    sw = 16'h7346;
    btnd = 1; //update the accumulator
    #5;
    btnd = 0;


    //test case 8
    #5;
    btnl = 1;
    btnc = 1;
    btnr = 0;
    sw = 16'h0004;
    btnd = 1; //update the accumulator
    #5;
    btnd = 0;


    //test case 9
    #5;
    btnl = 1;
    btnc = 1;
    btnr = 1;
    sw = 16'h0004;
    btnd = 1; //update the accumulator
    #5;
    btnd = 0;


    //test case 10
    #5;
    btnl = 1;
    btnc = 0;
    btnr = 1;
    sw = 16'hffff;
    btnd = 1; //update the accumulator
    #5;
    btnd = 0;

    #5;
    btnd = 1; //update the accumulator
    #5;
    btnd = 0;

    #5;
    btnd = 1; //update the accumulator
    #5;
    btnd = 0;

    #10;


  $stop; //stop simulation

end


   

endmodule

