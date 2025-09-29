`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////
// ===================================================================
// This file has the following module implementations:
// 1. datapath
// 2. regfile
// 3. alu
// 4. adder
// 5. mux2
// 6. sl2
// 7. signext
// 8. flopr
// ===================================================================
//////////////////////////////////////////////////////////////////////
// Datapath module
//////////////////////////////////////////////////////////////////////
module datapath (
    input logic clk, reset,
    input logic memtoreg, branch, pcsrc,
    input logic alusrc, regdst,
    input logic regwrite, jump,
    input logic [2:0] alucontrol,
    input logic perfmon,
    output logic zero,
    output logic [31:0] pcF,
    input logic [31:0] instr,
    output logic [31:0] aluoutM, writedataM,
    input logic [31:0] readdata
);
    logic [31:0] aluout;
    logic [31:0] writedata;

    logic [4:0] writereg, writeregE;
    logic [31:0] pcnext, pcnextbr, pcplus4, pcbranch, pcnextplus4, pcbranchD;
    logic [31:0] signimmD, signimmsh;
    logic [31:0] srca, srcb;
    logic [31:0] result;

    logic [1:0] forwardAE, forwardBE;

    logic stallF, stallD, flushE;
    logic equalD, pcsrcD;

    logic [31:0] srcaEQ, writedataEQ;

    // next PC logic
    logic [31:0] pc;
    flopr #(32) pcreg(.d(pcplus4), .r(pcnextplus4), .q(pc), .*);

    adder pcadd1 (.a(pc), .b(32'b100), .y(pcplus4));
    adder pcadd3 (.a(pcnext), .b(32'b100), .y(pcnextplus4));

    assign pcsrcD = equalD & branch;

    always_ff @(branch, pcsrcD)
    begin
        if (pcsrcD == 1'b1) $display("Branch is taken");
        else if ((pcsrcD != 1'b1) && (branch == 1'b1)) $display("Branch not taken");
    end

    logic [31:0] pcplus4D;

    sl2 immsh(.a(signimmD), .y(signimmsh));
    adder pcadd2(.a(pcplus4D), .b(signimmsh), .y(pcbranchD));

    mux2_dontcare #(32) pcbrmux(.d0(pcplus4), .d1(pcbranchD), .s(pcsrcD), .y(pcnextbr));
    mux2_dontcare #(32) pcmux(.d0(pcnextbr), .d1({pcplus4[31:28], instr[25:0], 2'b00}), .s(jump), .y(pcnext));

    //PC->IF
    logic prev_jump;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            pcF <= 32'hx;
            prev_jump <= 0;
        end else begin
            if (pcsrcD == 1'b1) begin
                pcF <= pcF;
            end else begin
                case(stallF)
                    1'bx, 1'b0: begin
                        pcF <= pc;
                        if (instr != 8'hx)
                            $display("Instruction %h entered IF stage", instr);
                    end
                    1'b1: begin
                        if (jump) begin
                            pcF <= pcnext;
                        end else begin
                            pcF <= pcF;
                        end
                        if (instr != 8'hx)
                            $display("Instruction %h stalled in IF", instr);
                    end
                endcase
            end

            prev_jump <= jump;
        end
    end

    //IF->ID
    logic [31:0] instrD;
    logic jumpD;

    always_ff @(posedge clk) begin

        if (pcsrcD == 1'b1) begin
            instrD <= 0;
            pcplus4D <= 0;
        end else begin
            case(stallD)
                1'bx, 1'b0: begin
                    instrD <= instr;
                    pcplus4D <= pcplus4;
                    jumpD <= jump;
                    if (instrD != 8'hx)
                        $display("Instruction %h entered ID stage", instrD);
                end
                1'b1: begin
                    instrD <= instrD;
                    pcplus4D <= pcplus4D;
                    jumpD <= jumpD;
                    if (instrD != 8'hx)
                        $display("Instruction %h stalled in ID", instrD);
                end
            endcase
        end
    end

    logic [4:0] rtE, rdE;
    logic regwriteW, memtoregW;
    logic [31:0] rdvalue, rdvalueE;
    logic [31:0] aluoutW, readdataW;
    logic [4:0] writeregW;
    logic regdstE;

    // register file logic
    regfile rf(.clk(clk), .we3(regwriteW), .ra1(instrD[25:21]), .ra2(instrD[20:16]), .ra3(instrD[15:11]), .wa3(writeregW), .wd3(result), .rd1(srca), .rd2(writedata), .rd3(rdvalue));
    mux2 #(5) wrmux(.d0(rtE), .d1(rdE), .s(regdstE), .y(writeregE));
    mux2 #(32) resmux(.d0(aluoutW), .d1(readdataW), .s(memtoregW), .y(result));
    signext se(.a(instrD[15:0]), .y(signimmD));

    //ID->EX
    logic regwriteE, memtoregE;
    logic [2:0] alucontrolE;
    logic alusrcE;
    logic [31:0] srcaE, srcbE, writedataE;
    logic [31:0] signimmE;
    //logic [31:0] pcplus4E;
    logic [31:0] instrE;
    logic [31:0] srcaMUX, writedataMUX;
    logic [4:0] rsE;

    logic [31:0] cycle_count, instr_count;

    always_ff @(posedge clk) begin

        if (flushE == 1'b1) begin
            regwriteE <= 0;
            memtoregE <= 0;
            alucontrolE <= 0;
            alusrcE <= 0;
            regdstE <= 0;
            srcaMUX <= 0;
            rdvalueE <= 0;
            writedataMUX <= 0;
            rtE <= 0;
            rdE <= 0;
            signimmE <= 0;
            instrE <= 0;
            rsE <= 0;
            if (instrE != 8'hx)
                $display("Instruction %h flushed in EX", instrE);
        end else begin
            regwriteE <= regwrite;
            memtoregE <= memtoreg;
            alucontrolE <= alucontrol;
            alusrcE <= alusrc;
            regdstE <= regdst;
            srcaMUX <= srca;
            rdvalueE <= rdvalue;
            writedataMUX <= writedata;
            rtE <= instrD[20:16];
            rdE <= instrD[15:11];
            
            if (perfmon) begin
                if (signimmD == 32'h0) signimmE <= cycle_count;
                else signimmE <= instr_count;
            end else begin
                signimmE <= signimmD;
            end
            
            instrE <= instrD;
            rsE <= instrD[25:21];
            if (instrE != 8'hx)
            $display("Instruction %h entered EX stage", instrE);
        end
    end

    // ALU logic

    mux3_dontcare #(32) srcamux(.d0(srcaMUX), .d1(result), .d2(aluoutM), .s(forwardAE), .y(srcaE));
    mux3_dontcare #(32) datawritemux(.d0(writedataMUX), .d1(result), .d2(aluoutM), .s(forwardBE), .y(writedataE));

    //mux2 #(32) perfmonmux(.d0(srcaE), .d1())

    mux2 #(32) srcbmux(.d0(writedataE), .d1(signimmE), .s(alusrcE), .y(srcbE));
    alu alu(.a(srcaE), .b(srcbE), .c(rdvalueE), .control(alucontrolE), .result(aluout), .zero(zero));

    hazardUnit hazardUnit(.rsD(instrD[25:21]), .rtD(instrD[20:16]), .*);

    equal #(32) equal(.srca(srcaEQ), .writedata(writedataEQ), .*);

    mux2_dontcare #(32) srcsEQMUX(.d0(srca), .d1(aluoutM), .s(forwardAD), .y(srcaEQ));
    mux2_dontcare #(32) writedataEQMUX(.d0(writedata), .d1(aluoutM), .s(forwardBD), .y(writedataEQ));


    //EX->MEM
    logic regwriteM, memtoregM;
    logic [4:0] writeregM;
    //logic [31:0] pcbranchM;
    logic [31:0] instrM;

    always_ff @(posedge clk) begin
        regwriteM <= regwriteE;
        memtoregM <= memtoregE;
        //zeroM <= zero;
        aluoutM <= aluout;
        writedataM <= writedataE;
        writeregM <= writeregE;
        //pcbranchM <= pcbranch;
        instrM <= instrE;
        if (instrM != 8'hx)
          $display("Instruction %h entered MEM stage", instrM);
    end

    //MEM->WB
    logic [31:0] instrW, prev_instr;

    always_ff @(posedge clk) begin
        regwriteW <= regwriteM;
        memtoregW <= memtoregM;
        aluoutW <= aluoutM;
        readdataW <= readdata;
        writeregW <= writeregM;
        instrW <= instrM;
        prev_instr <= instrW;
        if (instrW != 8'hx)
          $display("Instruction %h entered WB stage", instrW);
    end

    perfmon perfmon1 (.curr_instr(instrW), .*);

endmodule

module perfmon (
    input logic clk, reset,
    input logic [31:0] prev_instr, curr_instr,
    output logic [31:0] cycle_count, instr_count
);
    //logic cycle_count;
    //logic instr_count;
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            cycle_count <= 0;
            instr_count <= 0;
        end else begin
            cycle_count <= cycle_count + 1;
        
            if ((curr_instr != 1'bx))
            begin
                if (prev_instr != 1'bx) begin
                    if ((curr_instr != prev_instr))
                        instr_count <= instr_count + 1;
                end else begin
                    instr_count <= instr_count + 1;
                end 
            end
        end
    end

endmodule

module hazardUnit (
    input logic branch, memtoregE, memtoregM,
    input logic [4:0] rsD, rtD,
    input logic regwriteE, regwriteM, regwriteW,
    input logic [4:0] rsE, rtE,
    input logic [4:0] writeregE, writeregM, writeregW, 
    input logic prev_jump, jump, jumpD,
    output logic [1:0] forwardAE, forwardBE,
    output logic stallF, stallD, flushE,
    output logic forwardAD, forwardBD
);

logic lwstall;
logic branchstall;
logic jumpstall;

always_comb begin

    if ((rsE != 5'b00000) && (rsE == writeregM) && regwriteM) forwardAE = 2'b10;
    else if ((rsE != 5'b00000) && (rsE == writeregW) && regwriteW) forwardAE = 2'b01;
    else forwardAE = 2'b00;

    if ((rtE != 5'b00000) && (rtE == writeregM) && regwriteM) forwardBE = 2'b10;
    else if ((rtE != 5'b00000) && (rtE == writeregW) && regwriteW) forwardBE = 2'b01;
    else forwardBE = 2'b00;

    lwstall = ((rsD == rtE) || (rtD == rtE)) && memtoregE;

    forwardAD = ((rsD != 0) && (rsD == writeregM) && regwriteM);
    forwardBD = ((rtD != 0) && (rtD == writeregM) && regwriteM);

    branchstall =   (branch && regwriteE && ((writeregE == rsD) || (writeregE == rtD))) ||
                    (branch && memtoregM && ((writeregM ==rsD) || (writeregM==rtD)));

    jumpstall = prev_jump ^ (jump | jumpD);

    stallF = lwstall || branchstall || jumpstall;
    stallD = lwstall || branchstall;
    flushE = lwstall || branchstall;

end

endmodule 


//////////////////////////////////////////////////////////////////////
// Register File Module
//////////////////////////////////////////////////////////////////////
module regfile (
    input  logic        clk,
    input  logic        we3,
    input  logic [4:0]  ra1, ra2, ra3, wa3,
    input  logic [31:0] wd3,
    output logic [31:0] rd1, rd2, rd3
);

    logic [31:0] rf[31:0];

    // Write logic
    always_ff @(posedge clk) begin
        if (we3 && wa3 != 0)
            rf[wa3] <= wd3;
    end

    // Read logic with write-before-read bypass
    assign rd1 = (ra1 == 0)        ? 32'b0 :
                 (ra1 == wa3 && we3) ? wd3  : rf[ra1];

    assign rd2 = (ra2 == 0)        ? 32'b0 :
                 (ra2 == wa3 && we3) ? wd3  : rf[ra2];

    assign rd3 = (ra3 == 0)        ? 32'b0 :
                 (ra3 == wa3 && we3) ? wd3  : rf[ra3];

endmodule


//////////////////////////////////////////////////////////////////////
// ALU Module
////////////////////////////////////////////////////////////////////// 
module alu(
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [31:0] c,
    input  logic [2:0] control,
    output logic [31:0] result,
    output logic zero
);

    parameter ALU_AND = 3'b000;
    parameter ALU_OR  = 3'b001;
    parameter ALU_ADD = 3'b010;
    parameter ALU_SUB = 3'b110;
    parameter ALU_SLT = 3'b111;
    parameter ALU_MULADD = 3'b011; //NEW INSTR MULADD
    
    always_comb begin
        case(control)
            ALU_AND:    result = a & b;                     // AND
            ALU_OR:     result = a | b;                     // OR
            ALU_ADD:    result = a + b;                     // ADD
            ALU_SUB:    result = a - b;                     // SUB
            ALU_SLT:    result = ($signed(a) < $signed(b)); // Set Less Than (signed)
            ALU_MULADD: result = (a*b[31:0]) + c; 
            default: result = 32'bx;                     // Undefined operation
        endcase
    end

    assign zero = (result == 32'b0);

endmodule

//////////////////////////////////////////////////////////////////////
// Adder Module
//////////////////////////////////////////////////////////////////////
module adder(
    input  logic [31:0] a, b,
    output logic [31:0] y
);
    assign y = a + b;
endmodule


//////////////////////////////////////////////////////////////////////
// 2-to-1 Multiplexer Module
//////////////////////////////////////////////////////////////////////
module mux2 # (parameter WIDTH = 8)(
    input  logic [WIDTH-1:0] d0, d1,
    input  logic s,
    output logic [WIDTH-1:0] y
);
    assign y = s ? d1 : d0;
endmodule


//////////////////////////////////////////////////////////////////////
// Shift Left by 2 Module
//////////////////////////////////////////////////////////////////////
module sl2 (
    input  logic [31:0] a,
    output logic [31:0] y 
);
    assign y = {a[29:0], 2'b00};
endmodule


//////////////////////////////////////////////////////////////////////
// Sign Extension Module
//////////////////////////////////////////////////////////////////////
module signext (
    input  logic [15:0] a,
    output logic [31:0] y 
);
    assign y = {{16{a[15]}}, a};
endmodule


//////////////////////////////////////////////////////////////////////
// Flop Register Module
//////////////////////////////////////////////////////////////////////
module flopr # (parameter WIDTH = 8)(
    input logic stallF, jump,
    input  logic clk, reset,
    input  logic [WIDTH-1:0] d, r,
    output logic [WIDTH-1:0] q
);
    always_ff @(posedge clk, posedge reset) begin
        if (reset) q <= 0;
        else begin
            case({stallF,jump})
                2'b00 : q <= d;
                2'bxx : q <= d;
                2'b10 : q <= q;
                2'b11 : q <= r;
            endcase
        end
    end
endmodule

module mux2_dontcare #(parameter WIDTH = 8)(
    input logic [WIDTH-1:0] d0, d1,
    input logic s,
    output logic [WIDTH-1:0] y
);
    always_ff @(*) begin
        case(s)
            1'b0 : y <= d0;
            1'bx : y <= d0;
            1'b1 : y <= d1;
        endcase
    end
endmodule

module mux3_dontcare #(parameter WIDTH = 8)(
    input logic [WIDTH-1:0] d0, d1, d2,
    input logic [1:0] s,
    output logic [WIDTH-1:0] y
);
    always_ff @(*) begin
        case(s)
            2'bxx : y <= d0;
            2'b00 : y <= d0;
            2'b01 : y <= d1;
            2'b10 : y <= d2;
            //2'b11 : y <= y;
        endcase
    end
endmodule

module equal #(parameter WIDTH = 8)(
    input logic [WIDTH-1:0] srca, writedata,
    output logic equalD
);

    always_comb begin
        if (writedata == srca) equalD = 1'b1;
        else equalD = 1'b0;
    end
endmodule
