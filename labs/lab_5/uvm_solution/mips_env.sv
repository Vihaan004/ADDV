// MIPS Environment - Top-level environment containing agent and coverage
// Based on serialalu_env.sv pattern

class mips_env extends uvm_env;
	`uvm_component_utils(mips_env)

	mips_agent 	mips_agent_inst;
	mips_coverage 	mips_cov;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction: new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		mips_agent_inst = mips_agent::type_id::create(.name("mips_agent_inst"), .parent(this));
		mips_cov        = mips_coverage::type_id::create(.name("mips_cov"), .parent(this));
	endfunction: build_phase

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		// Connect agent monitor output to coverage collector
		mips_agent_inst.agent_ap.connect(mips_cov.analysis_export);
	endfunction: connect_phase
endclass: mips_env