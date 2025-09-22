//Add -ntb_opts uvm to the VCS command line
// Simple Template-Based Solution for Lab 5

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
    `uvm_field_int(machine_code, UVM_ALL_ON)
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

  // CONSTRAINT 3: Function code constraint for R-type instructions
  constraint valid_funct {
    if (opcode == 6'h00) funct inside {6'h20, 6'h24}; // ADD=0x20, AND=0x24
    else funct == 6'h00; // Don't care for non-R-type
  }

  // CONSTRAINT 4: Valid memory addresses and branch offsets
  constraint valid_addresses {
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
      machine_code = {opcode, reg_b, reg_c, reg_a, 5'h0, funct};
    end else begin // I-type (LW, SW, BEQ)
      machine_code = {opcode, reg_b, reg_a, mem_addr};
    end
  endfunction

  function void print_me();
    $write("0x%08h: ", machine_code);
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
    $display("[GEN] Generating 10 individual random instructions...");
    instr_list = new[10];
    for (int i = 0; i < 10; i++) begin
      instr_list[i] = new();
      assert(instr_list[i].randomize()) else $error("Randomization failed!");
      instr_list[i].post_randomize();
    end
  endfunction

  // Generate pairs of dependent instructions
  function void generate_pairs();
    $display("[GEN] Generating 4 dependent pair instructions...");
    
    // Extend instruction list to include 4 new instructions
    instruction temp_list[] = new[instr_list.size() + 4];
    
    // Copy existing instructions
    for (int i = 0; i < instr_list.size(); i++) begin
      temp_list[i] = instr_list[i];
    end
    
    // Pair 1: Both instructions use register 1 (RAW dependency)
    temp_list[instr_list.size() + 0] = new();
    temp_list[instr_list.size() + 1] = new();
    assert(temp_list[instr_list.size() + 0].randomize() with { reg_a == 1; }); // First writes to $1
    assert(temp_list[instr_list.size() + 1].randomize() with { reg_b == 1; }); // Second reads from $1
    temp_list[instr_list.size() + 0].post_randomize();
    temp_list[instr_list.size() + 1].post_randomize();
    
    // Pair 2: Both instructions use register 2 (RAW dependency)
    temp_list[instr_list.size() + 2] = new();
    temp_list[instr_list.size() + 3] = new();
    assert(temp_list[instr_list.size() + 2].randomize() with { reg_a == 2; }); // First writes to $2
    assert(temp_list[instr_list.size() + 3].randomize() with { reg_b == 2; }); // Second reads from $2
    temp_list[instr_list.size() + 2].post_randomize();
    temp_list[instr_list.size() + 3].post_randomize();
    
    instr_list = temp_list;
  endfunction

  // Insert gap instructions (NOP-like)
  function void insert_gaps();
    $display("[GEN] Generating 2 gap instructions...");
    instruction temp_list[] = new[instr_list.size() + 2];
    
    // Copy existing instructions
    for (int i = 0; i < instr_list.size(); i++) begin
      temp_list[i] = instr_list[i];
    end
    
    // Add 2 gap instructions (NOP-like: ADD $1, $1, $1)
    for (int i = 0; i < 2; i++) begin
      temp_list[instr_list.size() + i] = new();
      temp_list[instr_list.size() + i].opcode = 6'h00;  // ADD
      temp_list[instr_list.size() + i].reg_a = 1;       
      temp_list[instr_list.size() + i].reg_b = 1;
      temp_list[instr_list.size() + i].reg_c = 1;
      temp_list[instr_list.size() + i].funct = 6'h20;   // ADD function
      temp_list[instr_list.size() + i].post_randomize();
    end
    
    instr_list = temp_list;
  endfunction

  // Generate complete instruction sequence
  function void generate_sequence();
    $display("=== MIPS Instruction Generation Started ===");
    generate_individual(); // 10 instructions
    generate_pairs();      // 4 instructions (2 pairs)
    insert_gaps();         // 2 instructions
    $display("[GEN] Total instructions generated: %0d", instr_list.size());
    $display("===========================================");
  endfunction

  // Convert all instructions to machine code and write to file
  function void generate_machine_code();
    generate_sequence();
    
    // Prepare machine code array
    machine_code_list = new[instr_list.size()];
    for (int i = 0; i < instr_list.size(); i++) begin
      machine_code_list[i] = instr_list[i].machine_code;
    end
    
    // Write to hex file for MIPS processor
    $writememh("instructions.hex", machine_code_list);
    $display("[FILE] Generated %0d machine codes written to instructions.hex", machine_code_list.size());
  endfunction

  // Display all generated instructions for demo
  function void display_all();
    $display("\n=== INSTRUCTION SEQUENCE DISPLAY ===");
    for (int i = 0; i < instr_list.size(); i++) begin
      string category;
      if (i < 10) category = "[RANDOM]";
      else if (i < 14) category = "[DEPEND]";
      else category = "[GAP]   ";
      
      $write("%s Instr %2d: ", category, i+1);
      instr_list[i].print_me();
    end
    $display("====================================");
  endfunction
endclass

// Simple testbench that runs the instruction generator
module simple_testbench;
  instruction_generator gen;

  initial begin
    $display("=== Lab 5 Simple Template Solution ===\n");
    
    // Create and run instruction generator
    gen = new();
    gen.generate_machine_code();
    gen.display_all();
    
    $display("\n=== Test Summary ===");
    $display("✓ Generated 10 individual random instructions");
    $display("✓ Generated 4 dependent pair instructions (2 pairs)"); 
    $display("✓ Generated 2 gap instructions (NOP-like)");
    $display("✓ Total: 16 instructions written to instructions.hex");
    $display("✓ Ready for MIPS processor integration");
    $display("====================\n");
    
    $finish;
  end
endmodule