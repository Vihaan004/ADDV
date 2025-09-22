// MIPS Instruction Monitor
// Based on serialalu_monitor.sv pattern

class mips_monitor extends uvm_monitor;
	`uvm_component_utils(mips_monitor)

	virtual mips_if vif;              // Virtual interface to MIPS instruction memory
	uvm_analysis_port #(mips_transaction) ap;   // Analysis port to broadcast transactions

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction: new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		
		// Get virtual interface from resource database
		void'(uvm_resource_db#(virtual mips_if)::read_by_name
			(.scope("ifs"), .name("mips_if"), .val(vif)));
		ap = new(.name("ap"), .parent(this));
	endfunction: build_phase

	task run_phase(uvm_phase phase);
		mips_transaction mips_tx;
		
		// Wait for reset to be deasserted
		@(negedge vif.reset);
		
		forever begin
			// Wait for instruction fetch (positive clock edge)
			@(posedge vif.clk);
			
			// Create transaction and capture instruction data
			mips_tx = mips_transaction::type_id::create
				(.name("mips_tx"), .contxt(get_full_name()));
			
			// Capture instruction fields from the interface
			mips_tx.machine_code = vif.instruction;  // Full 32-bit instruction
			
			// Decode instruction fields
			mips_tx.opcode = vif.instruction[31:26];
			mips_tx.reg_b = vif.instruction[25:21];   // rs field
			mips_tx.reg_c = vif.instruction[20:16];   // rt field  
			mips_tx.reg_a = vif.instruction[15:11];   // rd field (for R-type)
			mips_tx.funct = vif.instruction[5:0];     // Function code for R-type
			mips_tx.mem_addr = vif.instruction[15:0]; // Immediate field
			
			// Broadcast transaction to coverage collector
			ap.write(mips_tx);
		end
	endtask: run_phase
endclass: mips_monitor