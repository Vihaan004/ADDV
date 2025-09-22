// MIPS Coverage Collector
// Based on serialalu_scoreboard.sv and Lab 5 requirements

class mips_coverage extends uvm_subscriber #(mips_transaction);
	`uvm_component_utils(mips_coverage)

	// Analysis port for receiving transactions
	uvm_analysis_imp #(mips_transaction, mips_coverage) analysis_export;
	
	// Transaction for covergroup sampling
	mips_transaction mips_tx;
	
	// Queue to track instruction sequence for order coverage
	mips_transaction instruction_queue[$];
	
	// COVERGROUP 1: Individual instruction fields
	covergroup instr_fields_cg;
		// Cover all 5 instruction opcodes
		coverpoint mips_tx.opcode {
			bins r_type = {6'h00};    // ADD/AND
			bins lw     = {6'h23};    // Load Word  
			bins sw     = {6'h2B};    // Store Word
			bins beq    = {6'h04};    // Branch Equal
		}
		
		// Cover function codes for R-type instructions (ADD vs AND)
		coverpoint mips_tx.funct {
			bins add_funct = {6'h20};  // ADD function code
			bins and_funct = {6'h24};  // AND function code
		}
		
		// Cross coverage: ensure we test both ADD and AND
		cross mips_tx.opcode, mips_tx.funct {
			bins add_instr = binsof(mips_tx.opcode.r_type) && binsof(mips_tx.funct.add_funct);
			bins and_instr = binsof(mips_tx.opcode.r_type) && binsof(mips_tx.funct.and_funct);
		}
		
		// Cover the 4 registers
		coverpoint mips_tx.reg_a {
			bins reg1 = {1};
			bins reg2 = {2}; 
			bins reg3 = {3};
			bins reg4 = {4};
		}
		
		coverpoint mips_tx.reg_b {
			bins reg1 = {1};
			bins reg2 = {2};
			bins reg3 = {3}; 
			bins reg4 = {4};
		}
		
		coverpoint mips_tx.reg_c {
			bins reg1 = {1};
			bins reg2 = {2};
			bins reg3 = {3};
			bins reg4 = {4};
		}
		
		// Cover memory addresses for LW/SW
		coverpoint mips_tx.mem_addr {
			bins addr1 = {16'h0040};
			bins addr2 = {16'h0044};
			bins addr3 = {16'h0048};
			bins addr4 = {16'h004C};
		}
	endgroup: instr_fields_cg
	
	// COVERGROUP 2: Instruction sequences/order
	covergroup instr_order_cg;
		// Track consecutive instruction types
		coverpoint mips_tx.opcode {
			bins r_type = {6'h00};
			bins lw     = {6'h23};
			bins sw     = {6'h2B};
			bins beq    = {6'h04};
		}
		
		// Sequence coverage (2 consecutive instructions)
		sequence_bins: coverpoint mips_tx.opcode {
			bins r_to_lw   = (6'h00 => 6'h23);
			bins lw_to_sw  = (6'h23 => 6'h2B);
			bins sw_to_beq = (6'h2B => 6'h04);
			bins beq_to_r  = (6'h04 => 6'h00);
		}
	endgroup: instr_order_cg
	
	// COVERGROUP 3: Data dependencies (hazards)
	covergroup instr_dependencies_cg;
		// Track register dependencies between consecutive instructions
		option.per_instance = 1;
		
		// Current instruction destination register
		curr_dest: coverpoint mips_tx.reg_a {
			bins reg1 = {1};
			bins reg2 = {2};
			bins reg3 = {3};
			bins reg4 = {4};
		}
		
		// Current instruction source registers
		curr_src1: coverpoint mips_tx.reg_b {
			bins reg1 = {1};
			bins reg2 = {2};
			bins reg3 = {3};
			bins reg4 = {4};
		}
		
		curr_src2: coverpoint mips_tx.reg_c {
			bins reg1 = {1};
			bins reg2 = {2};
			bins reg3 = {3};
			bins reg4 = {4};
		}
	endgroup: instr_dependencies_cg
	
	// COVERGROUP 4: Gap instruction detection
	covergroup instr_gaps_cg;
		// Detect NOP-like instructions (ADD $1, $1, $1)
		coverpoint mips_tx.opcode {
			bins nop_add = {6'h00};
		}
		
		// Cross coverage for NOP detection
		cross mips_tx.opcode, mips_tx.reg_a, mips_tx.reg_b, mips_tx.reg_c {
			bins nop_pattern = binsof(mips_tx.opcode.nop_add) && 
			                   binsof(mips_tx.reg_a) intersect {1} &&
			                   binsof(mips_tx.reg_b) intersect {1} &&
			                   binsof(mips_tx.reg_c) intersect {1};
		}
	endgroup: instr_gaps_cg

	function new(string name, uvm_component parent);
		super.new(name, parent);
		
		// Create covergroups
		instr_fields_cg = new();
		instr_order_cg = new();
		instr_dependencies_cg = new();
		instr_gaps_cg = new();
	endfunction: new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		analysis_export = new("analysis_export", this);
	endfunction: build_phase

	// Write function called when transaction arrives from monitor
	function void write(mips_transaction t);
		mips_tx = t; // Store transaction for covergroup sampling
		
		// Add to instruction queue for sequence analysis
		instruction_queue.push_back(t);
		if (instruction_queue.size() > 5) begin
			instruction_queue.pop_front(); // Keep queue manageable
		end
		
		// Sample all covergroups
		instr_fields_cg.sample();
		instr_order_cg.sample();
		instr_dependencies_cg.sample();
		instr_gaps_cg.sample();
		
		// Display instruction for debug
		$display("[COVERAGE] Sampled instruction: ");
		mips_tx.print_instruction();
		
		// Display coverage statistics periodically
		if (instruction_queue.size() % 5 == 0) begin
			$display("[COVERAGE] Fields coverage: %0.2f%%", instr_fields_cg.get_coverage());
			$display("[COVERAGE] Order coverage: %0.2f%%", instr_order_cg.get_coverage());
			$display("[COVERAGE] Dependencies coverage: %0.2f%%", instr_dependencies_cg.get_coverage());
			$display("[COVERAGE] Gaps coverage: %0.2f%%", instr_gaps_cg.get_coverage());
		end
	endfunction: write
	
	// Final report
	function void report_phase(uvm_phase phase);
		super.report_phase(phase);
		
		$display("\n=== MIPS VERIFICATION COVERAGE REPORT ===");
		$display("Total instructions processed: %0d", instruction_queue.size());
		$display("Instruction Fields Coverage: %0.2f%%", instr_fields_cg.get_coverage());
		$display("Instruction Order Coverage: %0.2f%%", instr_order_cg.get_coverage());
		$display("Dependencies Coverage: %0.2f%%", instr_dependencies_cg.get_coverage());
		$display("Gap Instructions Coverage: %0.2f%%", instr_gaps_cg.get_coverage());
		$display("==========================================\n");
	endfunction: report_phase
endclass: mips_coverage