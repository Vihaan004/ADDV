interface instr_mem_if(
    input logic clk,
    input logic reset
);
  logic [31:0] pc;
  logic [31:0] instr;
endinterface
