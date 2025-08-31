`timescale 1ns/1ns

//////////////////////
//DUT
/////////////////////
module dut(input clk, input logic [7:0] a, input logic [7:0] b, output logic[7:0] c);

    always_ff @(posedge clk) begin
        c <= a + b;
    end

endmodule

interface dut_if(input clk);

    logic [7:0] a;
    logic [7:0] b;
    logic [7:0] c;

endinterface

class scoreboard;

    virtual dut_if dut_vif;
    int a,b,c;
    int expected_result;

    function new(virtual dut_if dut_vif);
        this.dut_vif = dut_vif;
    endfunction

    task run();
        forever begin
            @(posedge dut_vif.clk);
            a = dut_vif.a;
            b = dut_vif.b;
            expected_result = a + b;

            @(negedge dut_vif.clk);
            c = dut_vif.c;
            if (expected_result != c) 
                $error("Failed. Time = %0t, Expected = %0d, Observed = %0d", $time, expected_result, c);
            else 
                $display("Passed. Time = %0t, Expected = %0d, Observed = %0d", $time, expected_result, c);
        end
    endtask

endclass

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

    dut_if dut_if_inst(clk);

    dut dut_inst(.clk(clk), .a(dut_if_inst.a), .b(dut_if_inst.b), .c(dut_if_inst.c));

    assign dut_if_inst.a = a;
    assign dut_if_inst.b = b;

    //Create testbench components
    scoreboard sb;
    
    initial begin
        sb = new(dut_if_inst);
        sb.run();
    end


    //Stimulus
    initial begin
        #10;
        @(negedge clk);
        a = 15;
        b = 25;
        @(negedge clk);
        #10;
        #10;
        @(negedge clk);
        a = 10;
        b = 13;
        @(negedge clk);
        #10;
        $finish;
    end

endmodule