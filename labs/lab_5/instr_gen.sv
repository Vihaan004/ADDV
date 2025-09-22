//Add -ntb_opts uvm to the VCS command line

`include "uvm_macros.svh"
import uvm_pkg::*;

class instruction extends uvm_sequence_item;
  // MIPS instruction fields - using proper bit widths
  rand bit [4:0] reg_a, reg_b, reg_c;  // Register fields (5 bits for 32 registers)
  rand bit [5:0] opcode;               // MIPS opcode (6 bits)
  rand bit [5:0] funct;                // Function code for R-type instructions
  rand bit [15:0] mem_addr;            // Memory address/immediate (16 bits)
  
  // Generated machine code
  bit [31:0] machine_code;

  // UVM utilities
  `uvm_object_utils_begin(instruction)
    `uvm_field_int(reg_a, UVM_ALL_ON)
    `uvm_field_int(reg_b, UVM_ALL_ON)
    `uvm_field_int(reg_c, UVM_ALL_ON)
    `uvm_field_int(opcode, UVM_ALL_ON)
    `uvm_field_int(funct, UVM_ALL_ON)
    `uvm_field_int(mem_addr, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "");
    super.new(name);
  endfunction

  // CONSTRAINT 1: Limit to 4 registers as per lab requirements
  constraint unique_regs {
    reg_a inside {1, 2, 3, 4};
    reg_b inside {1, 2, 3, 4};
    reg_c inside {1, 2, 3, 4};
  }

  // CONSTRAINT 2: Only allow the 5 instruction types
  constraint valid_opcode {
    opcode inside {6'h00, 6'h23, 6'h2B, 6'h04}; // R-type(ADD/AND), LW, SW, BEQ
  }

  // CONSTRAINT 2.5: Function code constraint for R-type instructions
  constraint valid_funct {
    if (opcode == 6'h00) funct inside {6'h20, 6'h24}; // ADD=0x20, AND=0x24
    else funct == 6'h00; // Don't care for non-R-type
  }

  // CONSTRAINT 3: Valid memory addresses and branch offsets
  constraint illegal_opcode {
    if (opcode == 6'h23 || opcode == 6'h2B) { // LW or SW
      mem_addr inside {16'h0040, 16'h0044, 16'h0048, 16'h004C}; // 4 memory addresses
    }
    if (opcode == 6'h04) { // BEQ
      mem_addr inside {1, 2, 3, 4}; // 4 branch offsets
    }
  }

  // SIMPLE FIX: ensure opcode is solved before mem_addr to avoid bias toward R-type
  constraint opcode_first_c { solve opcode before mem_addr; }

  // Convert to machine code after randomization
  function void post_randomize();
    if (opcode == 6'h00) begin // R-type (ADD or AND instruction)
      machine_code = {opcode, reg_b, reg_c, reg_a, 5'h0, funct}; // Use randomized funct
    end else begin // I-type (LW, SW, BEQ)
      machine_code = {opcode, reg_b, reg_a, mem_addr};
    end
  endfunction

  function void print_me();
    case (opcode)
      6'h00: begin
        if (funct == 6'h20) $display("ADD $%0d, $%0d, $%0d", reg_a, reg_b, reg_c);
        else if (funct == 6'h24) $display("AND $%0d, $%0d, $%0d", reg_a, reg_b, reg_c);
        else $display("Unknown R-type instruction");
      end
      6'h23: $display("LW $%0d, 0x%0h($%0d)", reg_a, mem_addr, reg_b);
      6'h2B: $display("SW $%0d, 0x%0h($%0d)", reg_a, mem_addr, reg_b);
      6'h04: $display("BEQ $%0d, $%0d, %0d", reg_b, reg_a, mem_addr);
      default: $display("Unknown instruction");
    endcase
  endfunction
endclass

class instruction_generator;
  instruction instr_list[];      // Dynamic array to store instructions
  bit [31:0] machine_code_list[]; // Machine code array

  // Generate individual random instructions
  function void generate_individual();
    instr_list = new[10]; // Generate 10 instructions
    for (int i = 0; i < 10; i++) begin
      instr_list[i] = new();
      assert(instr_list[i].randomize()) else $error("Randomization failed!");
    end
  endfunction

  // Create one dependent pair with 1-4 gap instructions in between, then append to instr_list
  function void generate_pairs();
    instruction first_i, second_i;
    int unsigned gap_n;
    bit [4:0] produced_reg;
    instruction tmp[];
    instruction gap_i;
    int idx;

    // if (instr_list == null) instr_list = new[0];

    // Randomize first instruction
    first_i = new();
    if (!first_i.randomize() with { opcode inside {6'h00, 6'h23}; }) begin
      $error("First instruction randomization failed for dependent pair");
      return;
    end

    // Choose the produced register for dependency (destination register)
    produced_reg = first_i.reg_a; // reg_a is destination for both R-type and LW

    // Randomize number of gaps between 1 and 4
    assert(std::randomize(gap_n) with { gap_n inside {[1:4]}; }) else gap_n = 1;

    // Randomize second instruction such that it reads 'produced_reg'
    second_i = new();
    if (!second_i.randomize() with {
          // Allow any of the 4 supported opcodes
          opcode inside {6'h00, 6'h23, 6'h2B, 6'h04};
          // Enforce RAW dependency based on opcode read operands
          if (opcode == 6'h00) { reg_b == produced_reg; }          // R-type reads reg_b/reg_c
          if (opcode == 6'h23) { reg_b == produced_reg; }          // LW reads base (reg_b)
          if (opcode == 6'h2B) { reg_a == produced_reg; }          // SW reads data from reg_a
          if (opcode == 6'h04) { reg_b == produced_reg; }          // BEQ reads reg_b/reg_a
        }) begin
      $error("Second instruction randomization failed for dependent pair");
      return;
    end

    // Build temporary list with first, gaps, and second
    tmp = new[instr_list.size() + gap_n + 2];

    // Copy existing instructions
    for (int i = 0; i < instr_list.size(); i++) tmp[i] = instr_list[i];

    idx = instr_list.size();
    tmp[idx++] = first_i;

    // Insert gap instructions (simple ALU ops that don't affect dependency)
    for (int g = 0; g < gap_n; g++) begin
      gap_i = new();
      // Create an ADD $1, $1, $1 as a NOP-like instruction under given constraints
      gap_i.opcode = 6'h00;   // R-type
      gap_i.funct  = 6'h20;   // ADD
      gap_i.reg_a  = 5'd1;    // Within allowed set {1..4}
      gap_i.reg_b  = 5'd1;
      gap_i.reg_c  = 5'd1;
      tmp[idx++] = gap_i;
    end

    tmp[idx++] = second_i;

    // Update main list
    instr_list = tmp;
  endfunction

  // Generate complete instruction sequence
  function void generate_sequence();
    generate_individual(); // Generate 10 random instructions
    generate_pairs();      // Append one dependent pair with 1-4 gap instructions between
    // Final sequence size: 10 + (2 + gaps[1..4])
  endfunction

  // Convert all instructions to machine code and write to file
  function void generate_machine_code();
    generate_sequence(); // First generate the instruction sequence
    
    // Convert to machine code
    machine_code_list = new[instr_list.size()];
    for (int i = 0; i < instr_list.size(); i++) begin
      instr_list[i].post_randomize(); // Generate machine code
      machine_code_list[i] = instr_list[i].machine_code;
    end
    
    // Write to file for MIPS processor
    $writememh("instructions.hex", machine_code_list);
    $display("Generated %0d machine codes written to instructions.hex", machine_code_list.size());
  endfunction

  // Display all generated instructions
  function void display_all();
    $display("=== Generated Instruction Sequence ===");
    $display("Total instructions: %0d", instr_list.size());
    $display("Breakdown:");
    $display("  - Individual random: %0d instructions", instr_list.size());
    $display("=====================================");
    
    for (int i = 0; i < instr_list.size(); i++) begin
      $write("Instr_%2d: ", i+1);
      
      // Add markers for instruction types
      $write("[RANDOM] ");
      
      instr_list[i].print_me();
    end
    $display("=====================================");
  endfunction
endclass

module testbench;
  instruction_generator gen;
  
  // Simple clock and reset
  logic clk = 0;
  logic reset = 1;
  
  // Clock generation
  always #5 clk = ~clk;

  initial begin
    $display("=== MIPS Instruction Generator ===");
    
    gen = new();
    gen.generate_machine_code(); // Generate instructions and write to file
    gen.display_all();           // Show what was generated

    $display("\n=== Integration with MIPS CPU ===");
    // Copy memory from gen to the MIPS instruction memory
    // Call $readmemh("instructions.hex", mips_cpu.instruction_memory);
    
    #10 reset = 0; // Deassert reset
    $display("Reset deasserted - start MIPS processor");
    
    // Run for some time
    #1000;
    $display("\n=== Test Complete ===");
    $finish;
  end
endmodule

