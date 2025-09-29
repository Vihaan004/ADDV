`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////
// ===================================================================
// This file has the following module implementations:
// 1. controller
// 2. maindec
// 3. aludec
// ===================================================================
//////////////////////////////////////////////////////////////////////
// Controller module
//////////////////////////////////////////////////////////////////////
module controller (
    input logic clk,
    input logic [5:0] op, funct,
    input logic zero,
    output logic memtoregD, memwriteM,
    output logic branchD,
    output logic pcsrc, alusrcD,
    output logic regdstD, regwriteD,
    output logic jump,
    output logic [2:0] alucontrolD,
    output logic perfmonD
);
    logic [1:0] aluop;
    
    logic memwrite, memwriteD, memwriteE;
    
    logic memtoreg, branch, alusrc, regdst, regwrite, perfmon;
    logic [2:0] alucontrol;
    
    always_ff @(posedge clk) begin
        memwriteD <= memwrite;
        memtoregD <= memtoreg;
        branchD <= branch;
        alusrcD <= alusrc;
        regdstD <= regdst;
        regwriteD <= regwrite;
        alucontrolD <= alucontrol;
        perfmonD <= perfmon;
    end 

    always_ff @(posedge clk) begin
        memwriteE <= memwriteD;
    end
    
    always_ff @(posedge clk) begin
        memwriteM <= memwriteE;
    end
    
    maindec md (.*);
    aludec ad (.*);
    
endmodule


//////////////////////////////////////////////////////////////////////
// Main Decoder module
//////////////////////////////////////////////////////////////////////
module maindec(
    input logic [5:0] op,
    output logic memtoreg, memwrite,
    output logic branch, alusrc,
    output logic regdst, regwrite,
    output logic jump,
    output logic perfmon,
    output logic [1:0] aluop
);

    logic [9:0] controls;
    
    assign {regwrite, regdst, alusrc, branch, memwrite, memtoreg, jump, aluop, perfmon} = controls;

    always_comb begin
        case(op)
            6'b000000: controls <= 10'b1100000100; //Rtyp
            6'b110000: controls <= 10'b1010000001; //PERFMON INSTRUCTION
            6'b100011: controls <= 10'b1010010000; //LW
            6'b101011: controls <= 10'b0010100000; //SW
            6'b000100: controls <= 10'b0001000010; //BEQ
            6'b001000: controls <= 10'b1010000000; //ADDI
            6'b000010: controls <= 10'b0000001000; //J
            default: controls <= 10'bxxxxxxxxxx; //???
        endcase
    end
endmodule


//////////////////////////////////////////////////////////////////////
// ALU Decoder module
//////////////////////////////////////////////////////////////////////
module aludec (
    input logic [5:0] funct,
    input logic [1:0] aluop,
    output logic [2:0] alucontrol
);
    always_comb begin
        case (aluop)
            2'b00: alucontrol <= 3'b010; // add
            2'b01: alucontrol <= 3'b110; // sub
            default: case(funct) // RTYPE
                6'b100000: alucontrol <= 3'b010; // ADD
                6'b100010: alucontrol <= 3'b110; // SUB
                6'b100100: alucontrol <= 3'b000; // AND
                6'b100101: alucontrol <= 3'b001; // OR
                6'b101010: alucontrol <= 3'b111; // SLT
                6'b110000: alucontrol <= 3'b011; // muladd (SPECIAL R)
                default: alucontrol <= 3'bxxx; // ???
            endcase
        endcase
    end
endmodule


