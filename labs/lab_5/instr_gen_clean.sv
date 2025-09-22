//Add -ntb_opts uvm to the VCS command line

class instruction extends uvm_sequence_item;
  rand bit [4:0] reg_a, reg_b, reg_c;
  rand bit [5:0] opcode;
  rand bit [15:0] mem_addr;
  rand bit [5:0] funct;
  bit [31:0] machine_code;

  // Valid registers: 1, 2, 3, 4
  constraint valid_regs {
    reg_a inside {1, 2, 3, 4};
    reg_b inside {1, 2, 3, 4};
    reg_c inside {1, 2, 3, 4};
  }

  // Valid opcodes: ADD(00), LW(23), SW(2B), BEQ(04), AND(00)
  constraint valid_opcode {
    opcode inside {6'h00, 6'h23, 6'h2B, 6'h04};
  }

  // R-type function codes for ADD/AND
  constraint valid_funct {
    if (opcode == 6'h00) {
      funct inside {6'h20, 6'h24}; // ADD or AND
    } else {
      funct == 6'h00;
    }
  }

  // Valid memory addresses and branch offsets
  constraint valid_addresses {
    if (opcode == 6'h23 || opcode == 6'h2B) { // LW or SW
      mem_addr inside {16'h0040, 16'h0044, 16'h0048, 16'h004C};
    }
    if (opcode == 6'h04) { // BEQ
      mem_addr inside {1, 2, 3, 4};
    }
  }

  function void post_randomize();
    if (opcode == 6'h00) begin // R-type
      machine_code = {opcode, reg_b, reg_c, reg_a, 5'h0, funct};
    end else begin // I-type
      machine_code = {opcode, reg_b, reg_a, mem_addr};
    end
  endfunction

  function void print_me();
    $write("0x%08h: ", machine_code);
    case (opcode)
      6'h00: begin
        if (funct == 6'h20) $display("ADD $%0d, $%0d, $%0d", reg_a, reg_b, reg_c);
        else if (funct == 6'h24) $display("AND $%0d, $%0d, $%0d", reg_a, reg_b, reg_c);
      end
      6'h23: $display("LW $%0d, 0x%0h($%0d)", reg_a, mem_addr, reg_b);
      6'h2B: $display("SW $%0d, 0x%0h($%0d)", reg_a, mem_addr, reg_b);
      6'h04: $display("BEQ $%0d, $%0d, %0d", reg_b, reg_a, mem_addr);
    endcase
  endfunction
endclass

class instruction_generator;
  instruction instr_list[];
  bit [31:0] machine_code_list[];

  // Generate 10 individual random instructions
  function void generate_individual();
    $display("[GEN] Generating 10 individual instructions...");
    instr_list = new[10];
    for (int i = 0; i < 10; i++) begin
      instr_list[i] = new();
      assert(instr_list[i].randomize());
      instr_list[i].post_randomize();
    end
  endfunction

  // Generate 2 dependent pairs (4 instructions total)
  function void generate_pairs();
    $display("[GEN] Generating 2 dependent pairs...");
    int old_size = instr_list.size();
    instr_list = new[old_size + 4] (instr_list);
    
    // Pair 1: reg_a=1, reg_b=1 dependency
    instr_list[old_size + 0] = new();
    assert(instr_list[old_size + 0].randomize() with { reg_a == 1; });
    instr_list[old_size + 0].post_randomize();
    
    instr_list[old_size + 1] = new();
    assert(instr_list[old_size + 1].randomize() with { reg_b == 1; });
    instr_list[old_size + 1].post_randomize();
    
    // Pair 2: reg_a=2, reg_b=2 dependency  
    instr_list[old_size + 2] = new();
    assert(instr_list[old_size + 2].randomize() with { reg_a == 2; });
    instr_list[old_size + 2].post_randomize();
    
    instr_list[old_size + 3] = new();
    assert(instr_list[old_size + 3].randomize() with { reg_b == 2; });
    instr_list[old_size + 3].post_randomize();
  endfunction

  // Insert 2 gap instructions between pairs
  function void insert_gaps();
    $display("[GEN] Inserting 2 gap instructions...");
    int old_size = instr_list.size();
    instr_list = new[old_size + 2] (instr_list);
    
    // Gap 1: NOP-like ADD $1, $1, $1
    instr_list[old_size + 0] = new();
    instr_list[old_size + 0].opcode = 6'h00;
    instr_list[old_size + 0].reg_a = 1;
    instr_list[old_size + 0].reg_b = 1;
    instr_list[old_size + 0].reg_c = 1;
    instr_list[old_size + 0].funct = 6'h20;
    instr_list[old_size + 0].post_randomize();
    
    // Gap 2: NOP-like ADD $1, $1, $1
    instr_list[old_size + 1] = new();
    instr_list[old_size + 1].opcode = 6'h00;
    instr_list[old_size + 1].reg_a = 1;
    instr_list[old_size + 1].reg_b = 1;
    instr_list[old_size + 1].reg_c = 1;
    instr_list[old_size + 1].funct = 6'h20;
    instr_list[old_size + 1].post_randomize();
  endfunction

  // Generate complete sequence: 10 individual + 4 pairs + 2 gaps = 16 total
  function void generate_sequence();
    $display("=== MIPS Instruction Generation ===");
    generate_individual();  // 10 instructions
    generate_pairs();       // 4 instructions 
    insert_gaps();          // 2 instructions
    $display("[GEN] Total: %0d instructions generated", instr_list.size());
  endfunction

  // Convert to machine code and write to file
  function void generate_machine_code();
    machine_code_list = new[instr_list.size()];
    for (int i = 0; i < instr_list.size(); i++) begin
      machine_code_list[i] = instr_list[i].machine_code;
    end
    $writememh("instructions.hex", machine_code_list);
    $display("[GEN] Machine code written to instructions.hex");
  endfunction

  // Display all generated instructions
  function void display_all();
    $display("\n=== Generated Instruction Sequence ===");
    for (int i = 0; i < instr_list.size(); i++) begin
      $write("[%02d] ", i);
      instr_list[i].print_me();
    end
    $display("=======================================\n");
  endfunction
endclass

module testbench;
  instruction_generator gen;

  initial begin
    gen = new();
    gen.generate_sequence();
    gen.generate_machine_code();
    gen.display_all();
    
    $finish;
  end
endmodule