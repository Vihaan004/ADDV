// Minimal UVM-based instruction generator for Lab 5 Part 2
// Add -ntb_opts uvm to the VCS command line

`include "uvm_macros.svh"
import uvm_pkg::*;

// Instruction transaction (limited to 5 opcodes and 4 regs/mem addresses per lab limits)
class instruction extends uvm_transaction;
  // Registers: use rs (reg_b), rt (reg_a), rd (reg_c) naming to match MIPS fields
  rand bit [4:0] reg_a, reg_b, reg_c;          // 1..4 only (per lab limit)
  rand bit [5:0] opcode, funct;                // opcode plus funct for R-type
  rand bit [31:0] mem_addr;                    // word addresses; we limit to 0,4,8,12
  rand bit [15:0] immediate;                   // for ADDI setup
  rand bit [15:0] branch_offset;               // 1..4 per lab limit

  // Restrict to four regs: $1..$4
  constraint unique_regs {
    soft reg_a inside {[1:4]};
    soft reg_b inside {[1:4]};
    soft reg_c inside {[1:4]};
  }

  // Valid opcodes in stream: R-type (ADD/AND via funct), LW, SW, BEQ
  constraint valid_opcode {
    soft opcode dist { 6'b000000 := 20, // R-type
                       6'b100011 := 30, // LW
                       6'b101011 := 30, // SW
                       6'b000100 := 20  // BEQ
                     };
  }

  // If R-type, restrict funct to ADD or AND; else funct=0
  constraint valid_funct {
    if (opcode == 6'b000000) soft funct inside {6'b100000, 6'b100100};
    else                     soft funct == 6'b000000;
  }

  // Immediate bounds (used for setup ADDI only)
  constraint small_immediate {
    soft immediate inside {[0:65535]};
  }

  // Limit memory addresses used by LW/SW to 0,4,8,12; base register use $0 for simplicity
  constraint valid_mem_addr {
    (opcode == 6'b100011 || opcode == 6'b101011) ->
      (mem_addr inside {0, 4, 8, 12} && reg_b == 0);
  }

  // Branch offsets limited to 1..4 per lab; 0 otherwise
  constraint valid_branch_offset {
    if (opcode == 6'b000100) soft branch_offset inside {1,2,3,4};
    else                     soft branch_offset == 0;
  }

  `uvm_object_utils(instruction)

  function new(string name = "instruction");
    super.new(name);
  endfunction

  function void print_me();
    $display("Opcode: %h Funct: %h | rs(reg_b): %0d rt(reg_a): %0d rd(reg_c): %0d | imm: %0d mem_addr: %h br_off: %0d",
             opcode, funct, reg_b, reg_a, reg_c, immediate, mem_addr, branch_offset);
  endfunction
endclass : instruction

class instruction_generator;
  instruction     instr_list[$];
  bit [31:0]      machine_code_list[$];

  function new(string name = "gen");
  endfunction

  // Generate a single random instruction under class constraints
  function void generate_individual();
    instruction instr = new();
    assert(instr.randomize());
    instr_list.push_back(instr);
  endfunction

  // Generate a dependent pair with 1..4 instruction gap inserted later
  function void generate_pairs();
    instruction tx1 = new();
    instruction tx2 = new();
    bit [4:0] dep_reg;
    bit [15:0] dep_mem;

    assert(std::randomize(dep_reg) with { dep_reg inside {[1:4]}; });
    assert(std::randomize(dep_mem) with { dep_mem inside {0,4,8,12}; });

    // First choose among R/LW/SW; BEQ handled separately
    assert(tx1.randomize() with { opcode inside {6'b000000, 6'b100011, 6'b101011}; });

    if (tx1.opcode == 6'b000000) begin
      // R-type result into dep_reg; next uses it as a source
      tx1.reg_c = dep_reg;
      assert(tx2.randomize() with { opcode == 6'b000000 && (reg_a == dep_reg || reg_b == dep_reg); });
    end
    else if (tx1.opcode == 6'b100011) begin
      // LW from dep_mem; pair with SW to same address (mem dep)
      tx1.mem_addr = dep_mem;
      assert(tx2.randomize() with { opcode == 6'b101011 && mem_addr == dep_mem; });
    end
    else begin // SW
      tx1.mem_addr = dep_mem;
      assert(tx2.randomize() with { opcode == 6'b100011 && mem_addr == dep_mem; });
    end

    instr_list.push_back(tx1);
    instr_list.push_back(tx2);
  endfunction

  // Insert 1..4 unrelated R-type instructions to create a gap
  function void insert_gaps();
    instruction gap_instr;
    int gap = $urandom_range(1,4);
    instruction prev_instr = instr_list[instr_list.size()-1];

    for (int i = 0; i < gap; i++) begin
      gap_instr = new();
      // Avoid using prev rd as a source to keep independence
      assert(gap_instr.randomize() with {
        opcode == 6'b000000 && !(reg_a inside {prev_instr.reg_c}) && !(reg_b inside {prev_instr.reg_c});
      });
      instr_list.push_back(gap_instr);
    end
  endfunction

  // Create a BEQ that may be taken or not; if not taken, add a filler instr
  function void generate_branch();
    instruction branch_instr;
    bit taken;
    bit [4:0] dep_reg;
    int offset;

    assert(std::randomize(taken));
    assert(std::randomize(dep_reg) with { dep_reg inside {[1:4]}; });

    branch_instr = new();
    // If taken, reg_a == reg_b; else force inequality by rotating dep_reg
    assert(branch_instr.randomize() with {
      opcode == 6'b000100 && reg_a == dep_reg && reg_b == (taken ? dep_reg : ((dep_reg % 4) + 1));
    });
    offset = branch_instr.branch_offset;
    instr_list.push_back(branch_instr);

    if (!taken) begin
      // Execute fall-through instruction
      generate_individual();
    end

    // Fill up to branch target: offset is number of instructions to skip
    for (int i = 1; i < offset; i++) begin
      insert_gaps();
    end
    // Target instruction
    generate_individual();
  endfunction

  // Build the full sequence: setup + randomized stream with pairs/gaps/branches
  function void generate_sequence();
    instruction setup_instr;

    // Setup: initialize $5..$8 to random small values via ADDI, then store to 4 mem addresses
    for (int i = 5; i < 9; i++) begin
      setup_instr = new();
      assert(setup_instr.randomize() with {
        opcode == 6'b001000 && // ADDI (setup only)
        reg_a == i && reg_b == 0 && immediate inside {[1:256]};
      });
      instr_list.push_back(setup_instr);
    end

    int mem_val = 0;
    for (int i = 5; i < 9; i++) begin
      setup_instr = new();
      assert(setup_instr.randomize() with {
        opcode == 6'b101011 && // SW
        reg_a == i && reg_b == 0 && mem_addr == mem_val;
      });
      instr_list.push_back(setup_instr);
      mem_val += 4;
    end

  // Initialize $1..$4 for randomized ops
    setup_instr = new(); assert(setup_instr.randomize() with { opcode == 6'b001000 && reg_a == 1 && reg_b == 0 && immediate inside {[1:256]}; }); instr_list.push_back(setup_instr);
    setup_instr = new(); assert(setup_instr.randomize() with { opcode == 6'b001000 && reg_a == 2 && reg_b == 0 && immediate inside {[1:256]}; }); instr_list.push_back(setup_instr);
    setup_instr = new(); assert(setup_instr.randomize() with { opcode == 6'b001000 && reg_a == 3 && reg_b == 0 && immediate inside {[1:256]}; }); instr_list.push_back(setup_instr);
    setup_instr = new(); assert(setup_instr.randomize() with { opcode == 6'b001000 && reg_a == 4 && reg_b == 0 && immediate inside {[1:256]}; }); instr_list.push_back(setup_instr);

    // Randomized instruction stream
    for (int blk = 0; blk < 2; blk++) begin
      // Some individuals
      for (int i = 0; i < 3; i++) begin
        generate_individual();
      end

      // A dependent pair and gaps
      generate_pairs();
      insert_gaps();

      // One branch scenario
      generate_branch();

      // More individuals
      for (int i = 0; i < 3; i++) begin
        generate_individual();
      end

      // A few more pairs
      for (int i = 0; i < 3; i++) begin
        generate_pairs();
      end
    end
  endfunction

  // Encode to machine code and write mem file for imem
  function void generate_machine_code();
    bit [31:0] instr_word;

    foreach (instr_list[i]) begin
      instruction instr = instr_list[i];
      case (instr.opcode)
        // R-type: opcode|rs|rt|rd|shamt|funct
        6'b000000: begin
          instr_word = {instr.opcode, instr.reg_b, instr.reg_a, instr.reg_c, 5'b00000, instr.funct};
        end
        // ADDI (setup only)
        6'b001000: begin
          instr_word = {instr.opcode, instr.reg_b, instr.reg_a, instr.immediate};
        end
        // LW / SW: opcode|rs(base)|rt|imm
        6'b100011, 6'b101011: begin
          instr_word = {instr.opcode, instr.reg_b, instr.reg_a, instr.mem_addr[15:0]};
        end
        // BEQ: opcode|rs|rt|offset
        6'b000100: begin
          instr_word = {instr.opcode, instr.reg_b, instr.reg_a, instr.branch_offset};
        end
        default: begin
          $display("Unknown instruction, opcode: %b at idx %0d", instr.opcode, i);
          instr_word = 32'h00000000;
        end
      endcase
      machine_code_list.push_back(instr_word);
    end

    $writememh("instruction_file.memh", machine_code_list);
  endfunction

  function void display_all();
    foreach (instr_list[i]) begin
      instr_list[i].print_me();
    end
  endfunction
endclass : instruction_generator

// Simple testbench: instantiates the provided MIPS top and runs with generated program
module testbench;
  logic clk;
  logic reset;
  logic [31:0] writedata, dataadr;
  logic memwrite;

  top dut(.clk(clk), .reset(reset), .writedata(writedata), .dataadr(dataadr), .memwrite(memwrite));

  instruction_generator gen;

  always begin
    #5 clk = ~clk; // 100 MHz
  end

  initial begin
    clk = 0;
    // Optional Verdi dumps if available
    $fsdbDumpMDA();
    $fsdbDumpvars();

    gen = new();
    gen.generate_sequence();
    gen.generate_machine_code();
    gen.display_all();
    $readmemh("instruction_file.memh", dut.imem.RAM);
    $display("\nseed: %0d\n", $get_initial_random_seed());

    reset = 1;
    @(posedge clk);
    @(posedge clk);
    reset = 0;

    // Run long enough to fetch/execute the sequence
    repeat (120) @(posedge clk);
    $finish;
  end
endmodule

