//==============================================================================
// Lab 5: MIPS UVM Environment
// This environment connects the monitor and coverage collector components
//==============================================================================

`include "uvm_macros.svh"
import uvm_pkg::*;

// Include required components
`include "mips_instruction_generator.sv"
`include "mips_monitor.sv"
`include "mips_coverage_collector.sv"

//==============================================================================
// MIPS UVM Environment
//==============================================================================
class mips_env extends uvm_env;
    `uvm_component_utils(mips_env)
    
    // Environment components
    mips_monitor monitor;
    mips_coverage_collector coverage_collector;
    
    // Virtual interface
    virtual mips_if vif;
    
    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "mips_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction: new
    
    //--------------------------------------------------------------------------
    // Build Phase - Create and configure components
    //--------------------------------------------------------------------------
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        `uvm_info("ENV", "Building MIPS Environment...", UVM_LOW)
        
        // Get virtual interface from config database
        if (!uvm_config_db#(virtual mips_if)::get(this, "", "mips_vif", vif)) begin
            `uvm_fatal("ENV", "Could not get virtual interface from config DB")
        end
        
        // Create monitor
        monitor = mips_monitor::type_id::create("monitor", this);
        if (monitor == null) begin
            `uvm_fatal("ENV", "Failed to create monitor")
        end
        
        // Create coverage collector
        coverage_collector = mips_coverage_collector::type_id::create("coverage_collector", this);
        if (coverage_collector == null) begin
            `uvm_fatal("ENV", "Failed to create coverage collector")
        end
        
        // Set virtual interface for monitor
        uvm_config_db#(virtual mips_if)::set(this, "monitor", "mips_vif", vif);
        
        `uvm_info("ENV", "MIPS Environment build phase completed", UVM_LOW)
    endfunction: build_phase
    
    //--------------------------------------------------------------------------
    // Connect Phase - Connect monitor to coverage collector
    //--------------------------------------------------------------------------
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        `uvm_info("ENV", "Connecting MIPS Environment components...", UVM_LOW)
        
        // Connect monitor's analysis port to coverage collector's analysis export
        monitor.ap.connect(coverage_collector.analysis_export);
        
        `uvm_info("ENV", "MIPS Environment connect phase completed", UVM_LOW)
    endfunction: connect_phase
    
    //--------------------------------------------------------------------------
    // End of elaboration phase - Print environment topology
    //--------------------------------------------------------------------------
    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        
        `uvm_info("ENV", "=== MIPS Environment Topology ===", UVM_LOW)
        `uvm_info("ENV", "Components created:", UVM_LOW)
        `uvm_info("ENV", $sformatf("  Monitor: %s", monitor.get_full_name()), UVM_LOW)
        `uvm_info("ENV", $sformatf("  Coverage Collector: %s", coverage_collector.get_full_name()), UVM_LOW)
        `uvm_info("ENV", "Connections established:", UVM_LOW)
        `uvm_info("ENV", "  Monitor.ap -> Coverage_Collector.analysis_export", UVM_LOW)
        `uvm_info("ENV", "==================================", UVM_LOW)
    endfunction: end_of_elaboration_phase
    
    //--------------------------------------------------------------------------
    // Run Phase - Start monitoring
    //--------------------------------------------------------------------------
    virtual task run_phase(uvm_phase phase);
        `uvm_info("ENV", "MIPS Environment run phase started", UVM_LOW)
        
        // The monitor and coverage collector run automatically
        // We just need to wait for completion
        
    endtask: run_phase
    
    //--------------------------------------------------------------------------
    // Check Phase - Validate environment state
    //--------------------------------------------------------------------------
    virtual function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        
        int instr_count = monitor.get_instruction_count();
        `uvm_info("ENV", $sformatf("Environment processed %0d instructions", instr_count), UVM_LOW)
        
        if (instr_count == 0) begin
            `uvm_warning("ENV", "No instructions were monitored during simulation")
        end
    endfunction: check_phase
    
    //--------------------------------------------------------------------------
    // Report Phase - Final coverage report
    //--------------------------------------------------------------------------
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        
        `uvm_info("ENV", "=== Final Environment Report ===", UVM_LOW)
        `uvm_info("ENV", $sformatf("Total instructions monitored: %0d", monitor.get_instruction_count()), UVM_LOW)
        
        // Coverage collector will report its own coverage in extract_phase
        
        `uvm_info("ENV", "=================================", UVM_LOW)
    endfunction: report_phase
    
endclass: mips_env


//==============================================================================
// MIPS UVM Test
//==============================================================================
class mips_test extends uvm_test;
    `uvm_component_utils(mips_test)
    
    // Test components
    mips_env env;
    instruction_generator instr_gen;
    
    // Virtual interface
    virtual mips_if vif;
    
    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "mips_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction: new
    
    //--------------------------------------------------------------------------
    // Build Phase
    //--------------------------------------------------------------------------
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        `uvm_info("TEST", "Building MIPS Test...", UVM_LOW)
        
        // Get virtual interface
        if (!uvm_config_db#(virtual mips_if)::get(this, "", "mips_vif", vif)) begin
            `uvm_fatal("TEST", "Could not get virtual interface from config DB")
        end
        
        // Create environment
        env = mips_env::type_id::create("env", this);
        if (env == null) begin
            `uvm_fatal("TEST", "Failed to create environment")
        end
        
        // Set virtual interface for environment
        uvm_config_db#(virtual mips_if)::set(this, "env", "mips_vif", vif);
        
        // Create instruction generator
        instr_gen = new();
        
        `uvm_info("TEST", "MIPS Test build phase completed", UVM_LOW)
    endfunction: build_phase
    
    //--------------------------------------------------------------------------
    // Run Phase - Main test execution
    //--------------------------------------------------------------------------
    virtual task run_phase(uvm_phase phase);
        `uvm_info("TEST", "MIPS Test run phase started", UVM_LOW)
        
        phase.raise_objection(this);
        
        // Execute the main test sequence
        main_test_sequence();
        
        phase.drop_objection(this);
        
        `uvm_info("TEST", "MIPS Test run phase completed", UVM_LOW)
    endtask: run_phase
    
    //--------------------------------------------------------------------------
    // Main test sequence
    //--------------------------------------------------------------------------
    virtual task main_test_sequence();
        bit [31:0] generated_program[$];
        int simulation_cycles = 1000; // Default simulation length
        
        `uvm_info("TEST", "Starting main test sequence...", UVM_LOW)
        
        // Wait for reset deassertion
        wait(!vif.reset);
        
        // Generate instruction sequence
        `uvm_info("TEST", "Generating instruction sequence...", UVM_LOW)
        instr_gen.generate_sequence();
        generated_program = instr_gen.get_machine_code_queue();
        
        `uvm_info("TEST", $sformatf("Generated %0d instructions", generated_program.size()), UVM_LOW)
        
        // Write program to file for reference
        instr_gen.write_to_memfile("lab5_test_program.dat");
        
        // Run simulation for specified cycles
        `uvm_info("TEST", $sformatf("Running simulation for %0d cycles...", simulation_cycles), UVM_LOW)
        repeat(simulation_cycles) @(posedge vif.clk_i);
        
        `uvm_info("TEST", "Main test sequence completed", UVM_LOW)
    endtask: main_test_sequence
    
    //--------------------------------------------------------------------------
    // Report Phase
    //--------------------------------------------------------------------------
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        
        `uvm_info("TEST", "=== Test Summary ===", UVM_LOW)
        `uvm_info("TEST", "MIPS Verification Test completed successfully", UVM_LOW)
        `uvm_info("TEST", "Check coverage reports for detailed results", UVM_LOW)
        `uvm_info("TEST", "====================", UVM_LOW)
    endfunction: report_phase
    
endclass: mips_test


//==============================================================================
// Top-level testbench with UVM integration
//==============================================================================
module mips_uvm_tb;
    
    // Clock and reset
    bit clk;
    bit reset;
    
    // Generate clock
    always #5 clk = ~clk; // 10ns period
    
    // MIPS interface
    mips_if mips_vif(clk);
    
    // DUT connections
    wire [31:0] writedata, dataadr;
    wire memwrite;
    
    // Connect interface to DUT signals
    assign mips_vif.pc = dut.mips.pc;
    assign mips_vif.instr = dut.mips.instr;
    assign mips_vif.reset = reset;
    assign mips_vif.dataadr = dataadr;
    assign mips_vif.writedata = writedata;
    assign mips_vif.readdata = dut.dmem.rd;
    assign mips_vif.memwrite = memwrite;
    
    // DUT instantiation
    top dut (
        .clk(clk),
        .reset(reset),
        .writedata(writedata),
        .dataadr(dataadr),
        .memwrite(memwrite)
    );
    
    // Initial block
    initial begin
        // Initialize
        reset = 1;
        
        // Set virtual interface in config database
        uvm_config_db#(virtual mips_if)::set(uvm_root::get(), "*", "mips_vif", mips_vif);
        
        // Wait a few cycles then release reset
        repeat(5) @(posedge clk);
        reset = 0;
        
        // Start UVM test
        run_test("mips_test");
    end
    
    // Timeout protection
    initial begin
        #50000; // 50us timeout
        `uvm_error("TB", "Simulation timeout")
        $finish;
    end
    
    // Waveform dumping
    initial begin
        $fsdbDumpfile("mips_uvm.fsdb");
        $fsdbDumpvars(0, mips_uvm_tb);
    end
    
endmodule: mips_uvm_tb