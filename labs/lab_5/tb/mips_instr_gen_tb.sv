//==============================================================================
// Lab 5: MIPS Instruction Generator Testbench
// This testbench demonstrates the instruction generator with the MIPS processor
//==============================================================================

`include "uvm_macros.svh"
import uvm_pkg::*;

// Include our instruction generator
`include "mips_instruction_generator.sv"

module mips_instr_gen_tb;

    // Clock and reset
    reg clk;
    reg reset;
    
    // MIPS processor signals
    wire [31:0] writedata, dataadr;
    wire memwrite;
    
    // Instruction generator
    instruction_generator instr_gen;
    
    // Generated instruction sequence
    bit [31:0] generated_program[$];
    
    //--------------------------------------------------------------------------
    // Clock generation
    //--------------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns period = 100MHz
    end
    
    //--------------------------------------------------------------------------
    // DUT instantiation - MIPS processor from Lab 2
    //--------------------------------------------------------------------------
    top dut (
        .clk(clk),
        .reset(reset),
        .writedata(writedata),
        .dataadr(dataadr),
        .memwrite(memwrite)
    );
    
    //--------------------------------------------------------------------------
    // Test stimulus
    //--------------------------------------------------------------------------
    initial begin
        // Initialize UVM
        run_test();
    end
    
    //--------------------------------------------------------------------------
    // Main test sequence
    //--------------------------------------------------------------------------
    initial begin
        `uvm_info("TB", "Starting MIPS Instruction Generator Test", UVM_LOW)
        
        // Initialize signals
        reset = 1;
        
        // Create instruction generator
        instr_gen = new();
        
        // Wait for a few clock cycles
        repeat(5) @(posedge clk);
        
        // Generate instruction sequence
        `uvm_info("TB", "Generating instruction sequence...", UVM_LOW)
        instr_gen.generate_sequence();
        
        // Get generated machine code
        generated_program = instr_gen.get_machine_code_queue();
        
        // Load generated program into instruction memory
        load_program_to_imem();
        
        // Write program to file for inspection
        instr_gen.write_to_memfile("lab5_generated_program.dat");
        
        // Release reset and start execution
        `uvm_info("TB", "Starting MIPS processor execution...", UVM_LOW)
        reset = 0;
        
        // Monitor execution for some time
        monitor_execution();
        
        // End simulation
        `uvm_info("TB", "Test completed", UVM_LOW)
        $finish;
    end
    
    //--------------------------------------------------------------------------
    // Load generated program into instruction memory
    //--------------------------------------------------------------------------
    task load_program_to_imem();
        `uvm_info("TB", $sformatf("Loading %0d instructions into IMEM", generated_program.size()), UVM_LOW)
        
        // Access the instruction memory inside the DUT
        // The path is: dut.imem.RAM
        for (int i = 0; i < generated_program.size() && i < 64; i++) begin
            dut.imem.RAM[i] = generated_program[i];
            `uvm_info("TB", $sformatf("IMEM[%02d] = 0x%08h", i, generated_program[i]), UVM_DEBUG)
        end
        
        // Clear remaining memory locations
        for (int i = generated_program.size(); i < 64; i++) begin
            dut.imem.RAM[i] = 32'h00000000;  // NOP or invalid
        end
    endtask
    
    //--------------------------------------------------------------------------
    // Monitor MIPS execution
    //--------------------------------------------------------------------------
    task monitor_execution();
        int instruction_count = 0;
        int max_instructions = generated_program.size() + 10;  // Safety limit
        
        `uvm_info("TB", "Monitoring MIPS processor execution...", UVM_LOW)
        
        // Monitor for several instruction executions
        while (instruction_count < max_instructions) begin
            @(posedge clk);
            
            // Check if we're fetching a valid instruction
            if (!reset) begin
                `uvm_info("TB", $sformatf("PC=0x%08h, Instr=0x%08h", dut.mips.pc, dut.mips.instr), UVM_HIGH)
                
                // Monitor data memory writes
                if (memwrite) begin
                    `uvm_info("TB", $sformatf("Memory Write: Addr=0x%08h, Data=0x%08h", dataadr, writedata), UVM_LOW)
                end
                
                instruction_count++;
                
                // Simple termination condition
                if (dut.mips.pc >= (generated_program.size() * 4)) begin
                    `uvm_info("TB", "Reached end of program", UVM_LOW)
                    break;
                end
            end
        end
        
        // Wait a bit more to see final effects
        repeat(10) @(posedge clk);
    endtask
    
    //--------------------------------------------------------------------------
    // Monitor specific signals for debugging
    //--------------------------------------------------------------------------
    initial begin
        // Wait for reset deassertion
        wait(!reset);
        
        // Monitor key signals
        forever begin
            @(posedge clk);
            if (!reset) begin
                // Log key processor state
                `uvm_info("MONITOR", $sformatf("Cycle: PC=0x%02h, Instr=0x%08h, MemWr=%b", 
                    dut.mips.pc[7:2], dut.mips.instr, memwrite), UVM_HIGH)
            end
        end
    end
    
    //--------------------------------------------------------------------------
    // Timeout protection
    //--------------------------------------------------------------------------
    initial begin
        #100000; // 100us timeout
        `uvm_error("TB", "Simulation timeout")
        $finish;
    end
    
endmodule


//==============================================================================
// UVM Test Class (minimal for this part)
//==============================================================================
class mips_instr_test extends uvm_test;
    `uvm_component_utils(mips_instr_test)
    
    function new(string name = "mips_instr_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("TEST", "MIPS Instruction Generator Test Build Phase", UVM_LOW)
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        `uvm_info("TEST", "MIPS Instruction Generator Test Run Phase", UVM_LOW)
        phase.raise_objection(this);
        
        // The actual test logic is in the testbench module above
        // This UVM test is minimal for Part 2
        #1000;
        
        phase.drop_objection(this);
    endtask
    
endclass