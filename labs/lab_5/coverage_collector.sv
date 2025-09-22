// Simple Coverage Collector Template - Lab 5
// Based on the original template but simplified for demo

`include "uvm_macros.svh"
import uvm_pkg::*;

// Simple transaction class for monitoring
class transaction extends uvm_sequence_item;
  bit [31:0] pc;              // Program counter
  bit [31:0] instruction;     // Full instruction
  bit [5:0] opcode;          // Instruction opcode
  bit [4:0] rs, rt, rd;      // Register fields
  bit [5:0] funct;           // Function code
  bit [15:0] immediate;      // Immediate field
  
  `uvm_object_utils_begin(transaction)
    `uvm_field_int(pc, UVM_ALL_ON)
    `uvm_field_int(instruction, UVM_ALL_ON)
    `uvm_field_int(opcode, UVM_ALL_ON)
    `uvm_field_int(rs, UVM_ALL_ON)
    `uvm_field_int(rt, UVM_ALL_ON)
    `uvm_field_int(rd, UVM_ALL_ON)
    `uvm_field_int(funct, UVM_ALL_ON)
    `uvm_field_int(immediate, UVM_ALL_ON)
  `uvm_object_utils_end
  
  function new(string name = "");
    super.new(name);
  endfunction
endclass

// Simple interface for MIPS instruction memory
interface instr_mem_if;
  logic clk;
  logic reset;
  logic [31:0] pc;
  logic [31:0] instruction;
  logic [31:0] dataadr;
  logic [31:0] writedata;
  logic memwrite;
endinterface

class instr_monitor extends uvm_monitor;
  `uvm_component_utils(instr_monitor)

  virtual instr_mem_if vif;
  uvm_analysis_port #(transaction) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual instr_mem_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not found")
  endfunction

  task run_phase(uvm_phase phase);
    transaction tr;
    
    @(negedge vif.reset);
    
    forever begin
      @(posedge vif.clk);
      
      tr = new();
      tr.pc = vif.pc;
      tr.instruction = vif.instruction;
      
      // Decode instruction fields
      tr.opcode = vif.instruction[31:26];
      tr.rs = vif.instruction[25:21];
      tr.rt = vif.instruction[20:16];
      tr.rd = vif.instruction[15:11];
      tr.funct = vif.instruction[5:0];
      tr.immediate = vif.instruction[15:0];
      
      ap.write(tr);
    end
  endtask
endclass

class instr_coverage extends uvm_subscriber #(transaction);
  `uvm_component_utils(instr_coverage)

  transaction tr;
  transaction instr_queue[$]; // For sequence tracking
  
  // Coverage counters
  int total_instructions = 0;
  int instruction_counts[6]; // Count each opcode
  int dependency_count = 0;
  int gap_count = 0;

  // COVERGROUP 1: Instruction fields
  covergroup instr_fields_cg;
    option.per_instance = 1;
    
    coverpoint tr.opcode {
      bins r_type = {6'h00};    // ADD/AND
      bins lw     = {6'h23};    // Load Word
      bins sw     = {6'h2B};    // Store Word  
      bins beq    = {6'h04};    // Branch Equal
    }
    
    coverpoint tr.funct {
      bins add_funct = {6'h20};  // ADD
      bins and_funct = {6'h24};  // AND
    }
    
    coverpoint tr.rs {
      bins reg1 = {1}; bins reg2 = {2}; bins reg3 = {3}; bins reg4 = {4};
    }
    
    coverpoint tr.rt {
      bins reg1 = {1}; bins reg2 = {2}; bins reg3 = {3}; bins reg4 = {4};
    }
    
    coverpoint tr.rd {
      bins reg1 = {1}; bins reg2 = {2}; bins reg3 = {3}; bins reg4 = {4};
    }
  endgroup

  // COVERGROUP 2: Instruction order (consecutive pairs)
  covergroup instr_order_cg;
    option.per_instance = 1;
    
    sequence_bins: coverpoint tr.opcode {
      bins r_to_lw   = (6'h00 => 6'h23);
      bins lw_to_sw  = (6'h23 => 6'h2B);
      bins sw_to_beq = (6'h2B => 6'h04);
      bins beq_to_r  = (6'h04 => 6'h00);
      bins any_to_any = (6'h00, 6'h23, 6'h2B, 6'h04 => 6'h00, 6'h23, 6'h2B, 6'h04);
    }
  endgroup

  // COVERGROUP 3: Dependencies 
  covergroup instr_dependencies_cg;
    option.per_instance = 1;
    
    curr_dest: coverpoint tr.rd {
      bins reg1 = {1}; bins reg2 = {2}; bins reg3 = {3}; bins reg4 = {4};
    }
    
    curr_src1: coverpoint tr.rs {
      bins reg1 = {1}; bins reg2 = {2}; bins reg3 = {3}; bins reg4 = {4};
    }
    
    curr_src2: coverpoint tr.rt {
      bins reg1 = {1}; bins reg2 = {2}; bins reg3 = {3}; bins reg4 = {4};
    }
  endgroup

  // COVERGROUP 4: Gap instructions
  covergroup instr_gaps_cg;
    option.per_instance = 1;
    
    coverpoint tr.opcode {
      bins gap_add = {6'h00};
    }
    
    cross tr.opcode, tr.rs, tr.rt, tr.rd {
      bins gap_pattern = binsof(tr.opcode) intersect {6'h00} &&
                        binsof(tr.rs) intersect {1} &&
                        binsof(tr.rt) intersect {1} &&
                        binsof(tr.rd) intersect {1};
    }
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    instr_fields_cg = new();
    instr_order_cg = new();
    instr_dependencies_cg = new();
    instr_gaps_cg = new();
  endfunction

  // Called when transaction arrives from monitor
  function void write(transaction t);
    tr = t;
    total_instructions++;
    
    // Track instruction in queue for sequence analysis
    instr_queue.push_back(t);
    if (instr_queue.size() > 5) instr_queue.pop_front();
    
    // Sample all covergroups
    instr_fields_cg.sample();
    instr_order_cg.sample();
    instr_dependencies_cg.sample();
    instr_gaps_cg.sample();
    
    // Count instruction types
    instruction_counts[t.opcode]++;
    
    // Detect gaps (ADD $1, $1, $1)
    if (t.opcode == 6'h00 && t.rs == 1 && t.rt == 1 && t.rd == 1 && t.funct == 6'h20) begin
      gap_count++;
    end
    
    // Detect dependencies
    check_dependencies();
    
    // Debug print
    $display("[COVERAGE] Instruction %0d: PC=0x%08h, Opcode=0x%02h", 
             total_instructions, t.pc, t.opcode);
  endfunction

  function void check_dependencies();
    if (instr_queue.size() >= 2) begin
      transaction prev = instr_queue[instr_queue.size()-2];
      transaction curr = instr_queue[instr_queue.size()-1];
      
      // Check RAW dependency: prev writes to reg, curr reads from same reg
      if ((prev.rd == curr.rs) || (prev.rd == curr.rt)) begin
        dependency_count++;
        $display("[COVERAGE] RAW dependency detected: $%0d", prev.rd);
      end
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    
    real fields_cov = instr_fields_cg.get_coverage();
    real order_cov = instr_order_cg.get_coverage();
    real deps_cov = instr_dependencies_cg.get_coverage();
    real gaps_cov = instr_gaps_cg.get_coverage();
    
    $display("\n=== MIPS VERIFICATION COVERAGE REPORT ===");
    $display("Total instructions processed: %0d", total_instructions);
    $display("Instruction Fields Coverage: %.2f%%", fields_cov);
    $display("Instruction Order Coverage: %.2f%%", order_cov);
    $display("Dependencies Coverage: %.2f%%", deps_cov);
    $display("Gap Instructions Coverage: %.2f%%", gaps_cov);
    $display("Dependencies detected: %0d", dependency_count);
    $display("Gap instructions detected: %0d", gap_count);
    $display("==========================================");
  endfunction
endclass

// Simple test environment
class simple_env extends uvm_env;
  `uvm_component_utils(simple_env)

  instr_monitor mon;
  instr_coverage cov;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = instr_monitor::type_id::create("mon", this);
    cov = instr_coverage::type_id::create("cov", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    mon.ap.connect(cov.analysis_export);
  endfunction
endclass

// Simple test
class simple_test extends uvm_test;
  `uvm_component_utils(simple_test)

  simple_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = simple_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    $display("=== Simple Coverage Test Started ===");
    
    // In a real test, we would:
    // 1. Load instructions from instruction generator
    // 2. Drive them through the interface
    // 3. Let the monitor observe and coverage collect
    
    #1000; // Run for some time
    
    $display("=== Simple Coverage Test Completed ===");
    phase.drop_objection(this);
  endtask
endclass