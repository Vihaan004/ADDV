// MIPS Driver - Generates instruction sequences and loads them into instruction memory
// Based on serialalu_driver.sv pattern

class mips_driver extends uvm_driver#(mips_transaction);
	`uvm_component_utils(mips_driver)

	virtual mips_if vif;
	
	// Array to store generated machine codes
	bit [31:0] instruction_memory[1024]; // Instruction memory
	int instruction_count = 0;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction: new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		void'(uvm_resource_db#(virtual mips_if)::read_by_name
			(.scope("ifs"), .name("mips_if"), .val(vif)));
	endfunction: build_phase

	task run_phase(uvm_phase phase);
		drive();
	endtask: run_phase

	virtual task drive();
		mips_transaction mips_tx;
		
		// Initialize instruction memory
		for (int i = 0; i < 1024; i++) begin
			instruction_memory[i] = 32'h00000000; // Initialize with NOPs
		end
		
		forever begin
			// Get next instruction from sequencer
			seq_item_port.get_next_item(mips_tx);
			
			// Store machine code in instruction memory
			instruction_memory[instruction_count] = mips_tx.machine_code;
			
			$display("[DRIVER] Generated Instruction %0d: 0x%08h", 
			         instruction_count, mips_tx.machine_code);
			mips_tx.print_instruction();
			
			instruction_count++;
			
			// Signal completion
			seq_item_port.item_done();
		end
	endtask: drive
	
	// Function to write instruction memory to file (for MIPS processor loading)
	function void write_instruction_file();
		int file;
		file = $fopen("instructions.hex", "w");
		if (file) begin
			for (int i = 0; i < instruction_count; i++) begin
				$fwrite(file, "%08h\n", instruction_memory[i]);
			end
			$fclose(file);
			$display("[DRIVER] Wrote %0d instructions to instructions.hex", instruction_count);
		end else begin
			$error("[DRIVER] Could not open instructions.hex for writing");
		end
	endfunction: write_instruction_file
endclass: mips_driver