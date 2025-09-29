`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////
// ========================================================================
// This file has the following module implementations:
// 1. top
// 2. mips
// 3. dmem
// 4. imem
// =========================================================================
////////////////////////////////////////////////////////////////////////////
// Top Module 
//  - This module connects the MIPS processor to instruction and data memory
////////////////////////////////////////////////////////////////////////////
module top (
    input logic clk, reset,
    output logic [31:0] writedata, dataadr,
    output logic memwrite
);
    logic [31:0] pc, instr, readdata;

    // instantiate processor and memories
    mips mips (.aluout(dataadr), .*);
    imem imem (.a(pc[7:2]), .rd(instr));
    dmem dmem (.we(memwrite), .a(dataadr), .wd(writedata), .rd(readdata), .*);
endmodule


//////////////////////////////////////////////////////////////////////
// Single-cycle MIPS Processor Module
//////////////////////////////////////////////////////////////////////
module mips (
    input logic clk, reset,
    output logic [31:0]  pc,
    input  logic [31:0]  instr,
    output logic memwrite,
    output logic [31:0]  aluout, writedata,
    input logic [31:0]  readdata
);

    logic memtoreg, branch, alusrc, regdst, regwrite, jump, zero, pcsrc, perfmon;
    logic [2:0] alucontrol;

    controller c(.op(instr[31:26]), .funct(instr[5:0]), .memtoregD(memtoreg), .memwriteM(memwrite), .branchD(branch), .alusrcD(alusrc), .regdstD(regdst), .regwriteD(regwrite), .alucontrolD(alucontrol), .perfmonD(perfmon), .*);

    datapath dp( .pcF(pc), .aluoutM(aluout), .writedataM(writedata), .*);
endmodule


//////////////////////////////////////////////////////////////////////
// Data Memory Module
//////////////////////////////////////////////////////////////////////
module dmem (
    input logic clk, we,
    input logic [31:0] a, wd,
    output logic [31:0] rd
);
    logic [31:0] RAM[63:0];

    assign rd = RAM[a[31:2]]; // word aligned
    
    always_ff @(posedge clk) begin
        if (we)
            RAM[a[31:2]] <= wd;
    end
endmodule


//////////////////////////////////////////////////////////////////////
// Instruction Memory Module
// - Note that it uses $readmemh to load imem from memfile.dat
// - This has a capacity of 64 words, If the memfile.dat has fewer than 64 words,
//   you will get a warning that some addresses are not initialized or the file has not enough words
//   you can ignre this warning
//////////////////////////////////////////////////////////////////////
module imem (
    input logic [5:0] a,
    output logic [31:0] rd
);
    logic [31:0] RAM[63:0];
    
    // initial begin
    //     $readmemh("memfile.dat",RAM);
    // end
    assign rd = RAM[a]; // word aligned
endmodule
