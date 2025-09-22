// MIPS Package - Contains all UVM components for MIPS verification
// Based on serialalu_pkg.sv pattern

package mips_pkg;
	import uvm_pkg::*;

	`include "mips_sequencer.sv"
	`include "mips_monitor.sv"  
	`include "mips_driver.sv"
	`include "mips_agent.sv"
	`include "mips_coverage.sv"
	`include "mips_env.sv"
	`include "mips_test.sv"
endpackage: mips_pkg