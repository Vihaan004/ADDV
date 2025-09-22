// Lab 5 Simple Template-Based Solution
// Combines instruction generation and coverage collection

`include "uvm_macros.svh"
import uvm_pkg::*;

// Include both template files
`include "instr_gen_simple.sv"
`include "coverage_collector_simple.sv"

module lab5_simple_demo;
  
  // Interface for MIPS instruction simulation
  instr_mem_if mips_if();
  
  // Clock and reset generation
  initial begin
    mips_if.clk = 0;
    forever #5 mips_if.clk = ~mips_if.clk; // 10ns period
  end
  
  initial begin
    mips_if.reset = 1;
    mips_if.pc = 0;
    mips_if.instruction = 0;
    mips_if.dataadr = 0;
    mips_if.writedata = 0;
    mips_if.memwrite = 0;
    
    #20 mips_if.reset = 0; // Deassert reset after 20ns
  end

  // Main test sequence
  initial begin
    instruction_generator gen;
    instr_monitor mon;
    instr_coverage cov;
    
    $display("=== Lab 5 Simple Template Demo ===\n");
    
    // PART 1: Generate Instructions
    $display("PART 1: INSTRUCTION GENERATION");
    $display("==============================");
    gen = new();
    gen.generate_machine_code(); // This generates 16 instructions
    gen.display_all();
    
    // PART 2: Set up Coverage Collection (simplified - without full UVM)
    $display("\nPART 2: COVERAGE SIMULATION");
    $display("===========================");
    
    // Register interface for UVM components
    uvm_config_db#(virtual instr_mem_if)::set(null, "*", "vif", mips_if);
    
    // Create coverage collector manually (simplified approach)
    cov = new("cov", null);
    
    // Simulate instruction execution by feeding generated instructions
    $display("[SIM] Simulating instruction execution...");
    
    fork
      // Thread 1: Simulate instruction fetch
      begin
        wait(!mips_if.reset);
        @(posedge mips_if.clk);
        
        for (int i = 0; i < gen.instr_list.size(); i++) begin
          mips_if.pc = i * 4; // Increment PC by 4 each instruction
          mips_if.instruction = gen.machine_code_list[i];
          
          // Create transaction and send to coverage
          transaction tr = new();
          tr.pc = mips_if.pc;
          tr.instruction = mips_if.instruction;
          tr.opcode = mips_if.instruction[31:26];
          tr.rs = mips_if.instruction[25:21];
          tr.rt = mips_if.instruction[20:16];
          tr.rd = mips_if.instruction[15:11];
          tr.funct = mips_if.instruction[5:0];
          tr.immediate = mips_if.instruction[15:0];
          
          // Send to coverage collector
          cov.write(tr);
          
          @(posedge mips_if.clk);
        end
      end
      
      // Thread 2: Timeout
      begin
        #2000;
        $display("[SIM] Simulation timeout");
      end
    join_any
    
    disable fork;
    
    // PART 3: Final Results
    $display("\nPART 3: FINAL RESULTS");
    $display("=====================");
    cov.report_phase(null);
    
    $display("\n=== DEMO SUMMARY ===");
    $display("✓ Template-based solution completed");
    $display("✓ Generated %0d instructions using template generator", gen.instr_list.size());
    $display("✓ Collected coverage using template coverage collector");
    $display("✓ Instructions written to instructions.hex file");
    $display("✓ Coverage analysis completed");
    $display("====================\n");
    
    $finish;
  end
  
  // Optional: Simple MIPS processor simulation (placeholder)
  always @(posedge mips_if.clk) begin
    if (!mips_if.reset) begin
      // In a real implementation, this would be the MIPS processor
      // For demo purposes, we just increment PC and show instruction fetch
      if (mips_if.instruction != 0) begin
        // $display("[CPU] Fetched instruction 0x%08h at PC=0x%08h", 
        //          mips_if.instruction, mips_if.pc);
      end
    end
  end

endmodule

// Alternative: UVM-based test for those who want UVM
module lab5_uvm_demo;
  
  instr_mem_if mips_if();
  
  // Clock and reset
  initial begin
    mips_if.clk = 0;
    forever #5 mips_if.clk = ~mips_if.clk;
  end
  
  initial begin
    mips_if.reset = 1;
    #20 mips_if.reset = 0;
  end
  
  initial begin
    // Register interface
    uvm_config_db#(virtual instr_mem_if)::set(null, "*", "vif", mips_if);
    
    // Run UVM test
    run_test("simple_test");
  end

endmodule