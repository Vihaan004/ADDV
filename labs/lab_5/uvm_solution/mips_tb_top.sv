// MIPS Testbench Top - Top-level module that instantiates MIPS processor and runs UVM test
// Based on serialalu_tb_top.sv pattern

`include "mips_pkg.sv"
`include "mips_if.sv"

module mips_tb_top;
	import uvm_pkg::*;
	import mips_pkg::*;

	// Interface declaration
	mips_if vif();
	
	// Clock generation
	initial begin
		vif.clk = 0;
		forever #5 vif.clk = ~vif.clk; // 10ns period = 100MHz
	end

	// Connect interface to DUT (MIPS processor)
	// Note: In a real environment, you would instantiate your MIPS processor here
	// For Lab 5, we focus on instruction generation and coverage
	
	// Example DUT instantiation (commented for standalone testing):
	// mips_processor dut(
	//     .clk(vif.clk),
	//     .reset(vif.reset),
	//     .pc(vif.pc),
	//     .instruction(vif.instruction),
	//     .memwrite(vif.memwrite),
	//     .writedata(vif.writedata),
	//     .dataadr(vif.dataadr)
	// );

	initial begin
		// Register the interface in the configuration database
		uvm_resource_db#(virtual mips_if)::set
			(.scope("ifs"), .name("mips_if"), .val(vif));

		// Initialize signals at time 0 (no delays)
		vif.reset = 1;
		vif.pc = 0;
		vif.instruction = 32'h00000000;
		vif.memwrite = 0;
		vif.writedata = 32'h00000000;
		vif.dataadr = 32'h00000000;
		
		// Execute the test at time 0
		run_test("mips_test");
	end
	
	// Separate initial block for reset sequence (after run_test starts)
	initial begin
		// Wait for simulation to start, then perform reset sequence
		#20 vif.reset = 0;
	end

	// Optional: Generate some instruction fetch simulation for monitor testing
	initial begin
		// Wait for reset deassertion
		@(negedge vif.reset);
		
		// Simulate some instruction fetches for monitor demonstration
		repeat(20) begin
			@(posedge vif.clk);
			vif.pc <= vif.pc + 4; // Increment PC
			// In real scenario, instruction would come from instruction memory
			// For demo, we'll use the generated instructions
		end
	end
endmodule: mips_tb_top