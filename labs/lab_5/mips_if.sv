// MIPS Interface - Connects to MIPS processor instruction memory interface
// Based on serialalu_if.sv pattern

interface mips_if;
	logic        clk;           // Clock signal
	logic        reset;         // Reset signal
	logic [31:0] pc;            // Program counter
	logic [31:0] instruction;   // Fetched instruction
	logic        memwrite;      // Memory write enable (for data memory)
	logic [31:0] writedata;     // Data to write to memory
	logic [31:0] dataadr;       // Data memory address
endinterface: mips_if