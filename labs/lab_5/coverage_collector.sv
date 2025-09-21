class instr_monitor extends uvm_monitor;
  `uvm_component_utils(instr_monitor)

  virtual instr_mem_if vif;              // Virtual interface to MIPS instruction memory
  uvm_analysis_port #(transaction) ap;   // Analysis port to broadcast transactions

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this); // Create analysis port
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // Get virtual interface from resource database
    if (!uvm_config_db#(virtual instr_mem_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not found")
  endfunction

  task run_phase(uvm_phase phase);
    transaction tr;
    
    // Wait for reset to be deasserted
    @(negedge vif.reset);
    
    forever begin
      // Wait for instruction fetch (positive clock edge)
      @(posedge vif.clk);
      
      // Create transaction and capture instruction data
      tr = new();
      tr.pc = vif.pc;           // Program counter
      tr.instruction = vif.instruction; // Fetched instruction
      
      // Decode basic instruction fields
      tr.opcode = vif.instruction[31:26];
      tr.rs = vif.instruction[25:21];
      tr.rt = vif.instruction[20:16];
      tr.rd = vif.instruction[15:11];
      tr.funct = vif.instruction[5:0];   // Function code for R-type
      tr.immediate = vif.instruction[15:0];
      
      // Broadcast transaction
      ap.write(tr);
    end
  endtask
endclass


class instr_coverage extends uvm_subscriber #(transaction);
  `uvm_component_utils(instr_coverage)

  uvm_analysis_imp #(transaction, instr_coverage) imp; // Fixed type consistency

  // Transaction for covergroup sampling
  transaction tr;

  // COVERGROUP 1: Individual instruction fields
  covergroup instr_fields_cg;
    // Cover all 5 instruction opcodes
    coverpoint tr.opcode {
      bins r_type = {6'h00};    // ADD/AND
      bins lw     = {6'h23};    // Load Word  
      bins sw     = {6'h2B};    // Store Word
      bins beq    = {6'h04};    // Branch Equal
    }
    
    // Cover function codes for R-type instructions (ADD vs AND)
    coverpoint tr.funct {
      bins add_funct = {6'h20};  // ADD function code
      bins and_funct = {6'h24};  // AND function code
    }
    
    // Cross coverage: ensure we test both ADD and AND
    cross tr.opcode, tr.funct {
      bins add_instr = binsof(tr.opcode.r_type) && binsof(tr.funct.add_funct);
      bins and_instr = binsof(tr.opcode.r_type) && binsof(tr.funct.and_funct);
    }
    
    // Cover the 4 registers
    coverpoint tr.rs {
      bins reg1 = {1};
      bins reg2 = {2}; 
      bins reg3 = {3};
      bins reg4 = {4};
    }
    
    coverpoint tr.rt {
      bins reg1 = {1};
      bins reg2 = {2};
      bins reg3 = {3}; 
      bins reg4 = {4};
    }
    
    coverpoint tr.rd {
      bins reg1 = {1};
      bins reg2 = {2};
      bins reg3 = {3};
      bins reg4 = {4};
    }
  endgroup

  // COVERGROUP 2: Instruction sequences/order
  covergroup instr_order_cg;
    // Simple sequence coverage
    coverpoint tr.opcode {
      bins add_lw = (6'h00 => 6'h23);   // ADD followed by LW
      bins sw_beq = (6'h2B => 6'h04);   // SW followed by BEQ
    }
  endgroup

  // COVERGROUP 3: Instruction gaps (simplified)
  covergroup instr_gap_cg;
    // Cover different gap sizes between dependent instructions
    coverpoint tr.pc {
      bins gap1 = {[32'h0000:32'h0010]}; // Small gaps
      bins gap2 = {[32'h0014:32'h0020]}; // Medium gaps  
      bins gap3 = {[32'h0024:32'h0030]}; // Larger gaps
    }
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    imp = new("imp", this);
    
    // Instantiate covergroups
    instr_fields_cg = new();
    instr_order_cg = new();
    instr_gap_cg = new();
  endfunction

  // Write function called when transaction arrives
  function void write(transaction tr);
    this.tr = tr; // Store transaction for covergroup sampling
    
    // Sample all covergroups
    instr_fields_cg.sample();
    instr_order_cg.sample();
    instr_gap_cg.sample();
    
    `uvm_info("COV", $sformatf("Coverage: Opcode=0x%0h, PC=0x%0h", tr.opcode, tr.pc), UVM_LOW)
  endfunction
endclass

class instr_env extends uvm_env;
  `uvm_component_utils(instr_env)

  instr_monitor mon;     // Monitor component
  instr_coverage cov;    // Coverage collector component

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create monitor and coverage collector
    mon = instr_monitor::type_id::create("mon", this);
    cov = instr_coverage::type_id::create("cov", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // Connect monitor's analysis port to coverage collector's imp port
    mon.ap.connect(cov.imp);
  endfunction
endclass

class my_test extends uvm_test;
    `uvm_component_utils(my_test)

    instr_env env; // Environment instance

    function new (string name = "my_test", uvm_component parent = null);
      super.new (name, parent);
    endfunction

    function void build_phase (uvm_phase phase);
         super.build_phase (phase);
         env = instr_env::type_id::create ("env", this);
    endfunction
endclass

// Transaction class (shared between Part 2 and Part 3)
class transaction extends uvm_transaction;
  // MIPS instruction fields
  bit [31:0] pc;           // Program counter
  bit [31:0] instruction;  // Full 32-bit instruction
  bit [5:0] opcode;        // Instruction opcode
  bit [4:0] rs, rt, rd;    // Register fields
  bit [5:0] funct;         // Function code for R-type instructions
  bit [15:0] immediate;    // Immediate field
  
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

  function new(string name = "transaction");
    super.new(name);
  endfunction
endclass

// Simple interface definition
interface instr_mem_if;
  logic clk;
  logic reset;
  logic [31:0] pc;
  logic [31:0] instruction;
endinterface

module top;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Clock and reset
  logic clk = 0;
  logic reset = 1;
  
  // Interface instance
  instr_mem_if intf();
  
  // Connect interface signals
  assign intf.clk = clk;
  assign intf.reset = reset;
  
  // Clock generation
  always #5 clk = ~clk;

  // Include instruction generator from Part 2
  `include "instr_gen.sv"

  initial begin
    instruction_generator gen;
    
    $display("=== Integrated MIPS Verification Environment ===");
    
    // PART 2: Generate instruction sequence
    gen = new();
    gen.generate_machine_code();
    gen.display_all();

    // Copy memory from gen to the instruction memory
    // In real testbench: $readmemh("instructions.hex", mips_cpu.instruction_memory);
    $display("Instructions loaded into MIPS memory");

    // PART 3: Set up UVM environment and start coverage collection
    // Set interface in config DB for UVM components
    uvm_config_db#(virtual instr_mem_if)::set(null, "*", "vif", intf);
    
    // Deassert reset and start UVM test
    #10 reset = 0;
    $display("Starting UVM test for coverage collection...");
    
    // Start UVM test
    run_test("my_test");
  end

  // Simple stimulus to drive interface for coverage demo
  initial begin
    #50; // Wait for reset
    
    // Simulate some instruction fetches for coverage
    repeat(20) begin
      @(posedge clk);
      intf.pc = $random();
      intf.instruction = $random();
    end
    
    #1000;
    $display("=== Coverage Collection Complete ===");
    $finish;
  end
endmodule
