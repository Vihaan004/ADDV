// MIPS Test - Main UVM test that runs instruction generation and coverage
// Based on serialalu_test.sv pattern

class mips_test extends uvm_test;
	`uvm_component_utils(mips_test)

	mips_env mips_env_inst;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction: new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		mips_env_inst = mips_env::type_id::create(.name("mips_env_inst"), .parent(this));
	endfunction: build_phase

	task run_phase(uvm_phase phase);
		mips_main_sequence mips_seq;

		phase.raise_objection(.obj(this));
		
		$display("\n=== MIPS Verification Test Started ===");
		
		// Create and run the main sequence
		mips_seq = mips_main_sequence::type_id::create(.name("mips_seq"), .contxt(get_full_name()));
		assert(mips_seq.randomize());
		mips_seq.start(mips_env_inst.mips_agent_inst.mips_seqr);
		
		// Wait for sequence completion
		#1000;
		
		// Write instruction file for MIPS processor
		mips_env_inst.mips_agent_inst.mips_drvr.write_instruction_file();
		
		$display("=== MIPS Verification Test Completed ===\n");
		
		phase.drop_objection(.obj(this));
	endtask: run_phase
endclass: mips_test