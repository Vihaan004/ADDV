// MIPS Agent - Contains sequencer, driver, and monitor
// Based on serialalu_agent.sv pattern

class mips_agent extends uvm_agent;
	`uvm_component_utils(mips_agent)

	uvm_analysis_port#(mips_transaction) agent_ap;

	mips_sequencer	mips_seqr;
	mips_driver	mips_drvr;
	mips_monitor	mips_mon;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction: new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		agent_ap = new(.name("agent_ap"), .parent(this));

		mips_seqr = mips_sequencer::type_id::create(.name("mips_seqr"), .parent(this));
		mips_drvr = mips_driver::type_id::create(.name("mips_drvr"), .parent(this));
		mips_mon  = mips_monitor::type_id::create(.name("mips_mon"), .parent(this));
	endfunction: build_phase

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		
		// Connect driver to sequencer
		mips_drvr.seq_item_port.connect(mips_seqr.seq_item_export);
		
		// Connect monitor to agent analysis port
		mips_mon.ap.connect(agent_ap);
	endfunction: connect_phase
endclass: mips_agent