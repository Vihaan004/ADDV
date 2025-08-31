// Import the C function using DPI
import "DPI-C" function int add(int a, int b);

`timescale 1ns/1ns

//////////////////////
//DUT
/////////////////////
module dut(input clk, input logic [7:0] a, input logic [7:0] b, output logic[7:0] c);

    always_ff @(posedge clk) begin
        c <= a + b;
    end

endmodule

//////////////////////
//Testbench
/////////////////////
module testbench;

    logic [7:0] a;
    logic [7:0] b;
    logic [7:0] c;
    integer result;

    logic clk = 0;

    always begin
        #10 clk = ~clk;
    end

    dut dut_inst(.clk(clk), .a(a), .b(b), .c(c));

    //Self checking stimulus
    initial begin
        #10;
        @(negedge clk);
        a = 15;
        b = 25;
        result = add(a, b);
        $display("Result from C function: %0d", result);
        @(negedge clk);
        if (result != c) $error("Failed");
        else $display("Pass");
        #10;
        $finish;
    end

endmodule



//vcs -sverilog dpi_class_example.sv dpi_add.c -o dpi_class_sim