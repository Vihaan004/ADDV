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


class transaction;
    
    bit [7:0] a;
    bit [7:0] b;
    bit [7:0] c;

    function new();
    endfunction

endclass

class monitor;

    virtual dut_if dut_vif;
    mailbox #(transaction) txn_mail;
    transaction txn;

    function new(virtual dut_if dut_vif);
        this.dut_vif = dut_vif;
    endfunction

    task run();
        forever begin
            @(posedge dut_vif.clk);
            txn = new();
            txn.a = dut_vif.a;
            txn.b = dut_vif.b;
            //$display("Time = %0t, a = %0d, b = %0d", $time, txn.a, txn.b);

            @(negedge dut_vif.clk);
            txn.c = dut_vif.c;
            //$display("Time = %0t, c = %0d", $time, txn.c);
            txn_mail.put(txn);
        end
    endtask

endclass

class scoreboard;

    mailbox #(transaction) txn_mail;
    transaction txn;
    int expected_result;

    function new();
    endfunction 

    task run();
        forever begin
            txn_mail.get(txn);
            //reference model
            expected_result = txn.a + txn.b;
            if (expected_result != txn.c) 
                $error("Failed. Time = %0t, Expected = %0d, Observed = %0d", $time, expected_result, txn.c);
            else 
                $display("Passed. Time = %0t, Expected = %0d, Observed = %0d", $time, expected_result, txn.c);
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
    mailbox #(transaction) txn_mail;
    monitor mon;
    scoreboard sb;
    
    initial begin
        mon = new(dut_if_inst);
        sb = new();
        txn_mail = new();
        mon.txn_mail = txn_mail;
        sb.txn_mail = txn_mail;
        fork
            mon.run();
            sb.run();
        join
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