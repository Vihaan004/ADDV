// MIPS Instruction Sequencer and Transaction Classes
// Based on Lab 5 requirements and serialalu_sequencer.sv pattern

class mips_transaction extends uvm_sequence_item;
	// MIPS instruction fields - using proper bit widths
	rand bit [4:0] reg_a, reg_b, reg_c;  // Register fields (5 bits for 32 registers)
	rand bit [5:0] opcode;               // MIPS opcode (6 bits)
	rand bit [5:0] funct;                // Function code for R-type instructions
	rand bit [15:0] mem_addr;            // Memory address/immediate (16 bits)
	
	// Generated machine code output
	bit [31:0] machine_code;
	
	function new(string name = "");
		super.new(name);
	endfunction: new

	`uvm_object_utils_begin(mips_transaction)
		`uvm_field_int(reg_a, UVM_ALL_ON)
		`uvm_field_int(reg_b, UVM_ALL_ON)
		`uvm_field_int(reg_c, UVM_ALL_ON)
		`uvm_field_int(opcode, UVM_ALL_ON)
		`uvm_field_int(funct, UVM_ALL_ON)
		`uvm_field_int(mem_addr, UVM_ALL_ON)
		`uvm_field_int(machine_code, UVM_ALL_ON)
	`uvm_object_utils_end

	// CONSTRAINT 1: Limit to 4 registers as per lab requirements
	constraint valid_regs {
		reg_a inside {1, 2, 3, 4};
		reg_b inside {1, 2, 3, 4};
		reg_c inside {1, 2, 3, 4};
	}

	// CONSTRAINT 2: Only allow the 5 instruction types
	constraint valid_opcode {
		opcode inside {6'h00, 6'h23, 6'h2B, 6'h04}; // R-type(ADD/AND), LW, SW, BEQ
	}

	// CONSTRAINT 3: Function code constraint for R-type instructions
	constraint valid_funct {
		if (opcode == 6'h00) funct inside {6'h20, 6'h24}; // ADD=0x20, AND=0x24
		else funct == 6'h00; // Don't care for non-R-type
	}

	// CONSTRAINT 4: Valid memory addresses and branch offsets
	constraint valid_addresses {
		if (opcode == 6'h23 || opcode == 6'h2B) { // LW or SW
			mem_addr inside {16'h0040, 16'h0044, 16'h0048, 16'h004C}; // 4 memory addresses
		}
		if (opcode == 6'h04) { // BEQ
			mem_addr inside {1, 2, 3, 4}; // 4 branch offsets
		}
	}

	// Convert to machine code after randomization
	function void post_randomize();
		if (opcode == 6'h00) begin // R-type (ADD or AND instruction)
			machine_code = {opcode, reg_b, reg_c, reg_a, 5'h0, funct}; // Use randomized funct
		end else begin // I-type (LW, SW, BEQ)
			machine_code = {opcode, reg_b, reg_a, mem_addr};
		end
	endfunction: post_randomize

	// Display instruction in assembly format
	function void print_instruction();
		case (opcode)
			6'h00: begin
				if (funct == 6'h20) $display("ADD $%0d, $%0d, $%0d", reg_a, reg_b, reg_c);
				else if (funct == 6'h24) $display("AND $%0d, $%0d, $%0d", reg_a, reg_b, reg_c);
				else $display("Unknown R-type instruction");
			end
			6'h23: $display("LW $%0d, 0x%0h($%0d)", reg_a, mem_addr, reg_b);
			6'h2B: $display("SW $%0d, 0x%0h($%0d)", reg_a, mem_addr, reg_b);
			6'h04: $display("BEQ $%0d, $%0d, %0d", reg_b, reg_a, mem_addr);
			default: $display("Unknown instruction");
		endcase
	endfunction: print_instruction
endclass: mips_transaction

// Individual instruction sequence (10 random instructions)
class mips_individual_sequence extends uvm_sequence#(mips_transaction);
	`uvm_object_utils(mips_individual_sequence)

	function new(string name = "");
		super.new(name);
	endfunction: new

	virtual task body();
		mips_transaction mips_tx;
		repeat(10) begin
			mips_tx = mips_transaction::type_id::create(.name("mips_tx"), .contxt(get_full_name()));
			start_item(mips_tx);
			assert(mips_tx.randomize());
			finish_item(mips_tx);
		end
	endtask: body
endclass: mips_individual_sequence

// Dependent pairs sequence (2 pairs = 4 instructions)
class mips_pairs_sequence extends uvm_sequence#(mips_transaction);
	`uvm_object_utils(mips_pairs_sequence)

	function new(string name = "");
		super.new(name);
	endfunction: new

	virtual task body();
		mips_transaction mips_tx1, mips_tx2;
		
		// Pair 1: Both instructions use register 1 (RAW dependency)
		mips_tx1 = mips_transaction::type_id::create(.name("mips_tx1"), .contxt(get_full_name()));
		start_item(mips_tx1);
		assert(mips_tx1.randomize() with { reg_a == 1; }); // First writes to $1
		finish_item(mips_tx1);
		
		mips_tx2 = mips_transaction::type_id::create(.name("mips_tx2"), .contxt(get_full_name()));
		start_item(mips_tx2);
		assert(mips_tx2.randomize() with { reg_b == 1; }); // Second reads from $1
		finish_item(mips_tx2);
		
		// Pair 2: Both instructions use register 2 (RAW dependency)
		mips_tx1 = mips_transaction::type_id::create(.name("mips_tx1"), .contxt(get_full_name()));
		start_item(mips_tx1);
		assert(mips_tx1.randomize() with { reg_a == 2; }); // First writes to $2
		finish_item(mips_tx1);
		
		mips_tx2 = mips_transaction::type_id::create(.name("mips_tx2"), .contxt(get_full_name()));
		start_item(mips_tx2);
		assert(mips_tx2.randomize() with { reg_b == 2; }); // Second reads from $2
		finish_item(mips_tx2);
	endtask: body
endclass: mips_pairs_sequence

// Gap sequence (2 NOP-like instructions)
class mips_gap_sequence extends uvm_sequence#(mips_transaction);
	`uvm_object_utils(mips_gap_sequence)

	function new(string name = "");
		super.new(name);
	endfunction: new

	virtual task body();
		mips_transaction mips_tx;
		repeat(2) begin
			mips_tx = mips_transaction::type_id::create(.name("mips_tx"), .contxt(get_full_name()));
			start_item(mips_tx);
			// Force NOP-like instruction: ADD $1, $1, $1
			mips_tx.opcode = 6'h00;
			mips_tx.reg_a = 1;
			mips_tx.reg_b = 1;
			mips_tx.reg_c = 1;
			mips_tx.funct = 6'h20; // ADD
			mips_tx.post_randomize(); // Generate machine code
			finish_item(mips_tx);
		end
	endtask: body
endclass: mips_gap_sequence

// Main sequence that combines all sequence types
class mips_main_sequence extends uvm_sequence#(mips_transaction);
	`uvm_object_utils(mips_main_sequence)

	function new(string name = "");
		super.new(name);
	endfunction: new

	virtual task body();
		mips_individual_sequence individual_seq;
		mips_pairs_sequence pairs_seq;
		mips_gap_sequence gap_seq;

		// Generate individual instructions
		individual_seq = mips_individual_sequence::type_id::create(.name("individual_seq"), .contxt(get_full_name()));
		individual_seq.start(m_sequencer);

		// Generate dependent pairs
		pairs_seq = mips_pairs_sequence::type_id::create(.name("pairs_seq"), .contxt(get_full_name()));
		pairs_seq.start(m_sequencer);

		// Generate gap instructions
		gap_seq = mips_gap_sequence::type_id::create(.name("gap_seq"), .contxt(get_full_name()));
		gap_seq.start(m_sequencer);
	endtask: body
endclass: mips_main_sequence

// Sequencer (same pattern as serialalu)
class mips_sequencer extends uvm_sequencer#(mips_transaction);
	`uvm_component_utils(mips_sequencer)

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction: new
endclass: mips_sequencer