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

  // ------------------------------------?
  // Generate pairs of dependent instructions
  function void generate_pairs();
    instruction pair_list[];
    pair_list = new[4]; // Generate 2 pairs (4 instructions total)
    
    // Pair 1: Both instructions use register 1 (RAW dependency)
    pair_list[0] = new();
    pair_list[1] = new();
    assert(pair_list[0].randomize() with { reg_a == 1; }); // First writes to $1
    assert(pair_list[1].randomize() with { reg_b == 1; }); // Second reads from $1
    
    // Pair 2: Both instructions use register 2 (RAW dependency)
    pair_list[2] = new();
    pair_list[3] = new();
    assert(pair_list[2].randomize() with { reg_a == 2; }); // First writes to $2
    assert(pair_list[3].randomize() with { reg_b == 2; }); // Second reads from $2
    
    // Add pairs to main instruction list
    if (instr_list == null) instr_list = new[0];
    instruction temp_list[] = new[instr_list.size() + pair_list.size()];
    
    // Copy existing instructions
    for (int i = 0; i < instr_list.size(); i++) begin
      temp_list[i] = instr_list[i];
    end
    
    // Add new pairs
    for (int i = 0; i < pair_list.size(); i++) begin
      temp_list[instr_list.size() + i] = pair_list[i];
    end
    
    instr_list = temp_list;
  endfunction

  // Insert gaps between instructions (simple implementation)
  function void insert_gaps();
    if (instr_list == null || instr_list.size() == 0) return;
    
    instruction temp_list[];
    int gap_count = 2;
    temp_list = new[instr_list.size() + gap_count];
    
    // Copy original instructions
    for (int i = 0; i < instr_list.size(); i++) begin
      temp_list[i] = instr_list[i];
    end
    
    // Add gap instructions at the end
    for (int i = 0; i < gap_count; i++) begin
      temp_list[instr_list.size() + i] = new();
      temp_list[instr_list.size() + i].opcode = 6'h00;  // R-type
      temp_list[instr_list.size() + i].reg_a = 1;       // $1 = $1 + $1 (NOP-like)
      temp_list[instr_list.size() + i].reg_b = 1;
      temp_list[instr_list.size() + i].reg_c = 1;
      temp_list[instr_list.size() + i].funct = 6'h20;   // ADD function
    end
    
    // Update instruction list
    instr_list = temp_list;
  endfunction

  // Generate complete instruction sequence
  function void generate_sequence();
    generate_individual(); // Generate 10 random instructions
    generate_pairs();      // Add 4 dependent instructions (2 pairs)
    insert_gaps();         // Add 2 NOP-like gap instructions
    // Final sequence: 10 + 4 + 2 = 16 instructions total
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
    $display("  - Individual random: 10 instructions");
    $display("  - Dependent pairs: 4 instructions (2 pairs)");
    $display("  - Gap instructions: 2 instructions");
    $display("=====================================");
    
    for (int i = 0; i < instr_list.size(); i++) begin
      $write("Instruction %2d: ", i+1);
      
      // Add markers for instruction types
      if (i < 10) $write("[RANDOM] ");
      else if (i < 14) $write("[DEPEND] ");
      else $write("[GAP]    ");
      
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
    $display("=== MIPS Instruction Generator Test ===");
    
    // Create and run generator
    gen = new();
    gen.generate_machine_code(); // Generate instructions and write to file
    gen.display_all();           // Show what was generated

    $display("\n=== Integration with MIPS CPU ===");
    // In a real testbench, you would:
    // 1. Copy memory from gen to the MIPS instruction memory
    // 2. OR: Call $readmemh("instructions.hex", mips_cpu.instruction_memory);
    // 3. Deassert reset to start MIPS processor
    
    #10 reset = 0; // Deassert reset
    $display("Reset deasserted - MIPS processor would start executing instructions");
    
    // Run for some time
    #1000;
    $display("\n=== Test Complete ===");
    $finish;
  end
endmodule

