//==============================================================================
// Lab 5: MIPS Coverage Collector
// This subscriber collects functional coverage for MIPS verification
//==============================================================================

`include "uvm_macros.svh"
import uvm_pkg::*;

// Include required files
`include "mips_instruction_generator.sv"

//==============================================================================
// Coverage Collector Class
//==============================================================================
class mips_coverage_collector extends uvm_subscriber #(instruction);
    `uvm_component_utils(mips_coverage_collector)
    
    // Analysis implementation port
    uvm_analysis_imp #(instruction, mips_coverage_collector) analysis_export;
    
    // Coverage tracking variables
    instruction current_instr;
    instruction prev_instr;
    instruction instr_history[$];
    
    // Dependency tracking
    typedef enum {
        NO_DEP,
        REG_WR_DEP,   // Write-Read register dependency
        REG_WW_DEP,   // Write-Write register dependency  
        MEM_SW_LW_DEP // Store-Load memory dependency
    } dependency_type_e;
    
    dependency_type_e current_dependency;
    int dependency_gap;
    bit [4:0] dependent_reg;
    bit [15:0] dependent_addr;
    
    //--------------------------------------------------------------------------
    // Individual Instruction Coverage
    //--------------------------------------------------------------------------
    covergroup instr_fields_cg;
        option.per_instance = 1;
        option.name = "instruction_fields";
        
        // Instruction type coverage
        instr_type_cp: coverpoint current_instr.instr_type {
            bins add_bin = {INSTR_ADD};
            bins and_bin = {INSTR_AND};
            bins lw_bin = {INSTR_LW};
            bins sw_bin = {INSTR_SW};
            bins beq_bin = {INSTR_BEQ};
        }
        
        // Source register coverage (rs)
        src_reg_cp: coverpoint current_instr.rs {
            bins reg1 = {1};
            bins reg2 = {2};
            bins reg3 = {3};
            bins reg4 = {4};
            bins reg0 = {0}; // For cases where rs might be $0
        }
        
        // Target register coverage (rt)
        target_reg_cp: coverpoint current_instr.rt {
            bins reg1 = {1};
            bins reg2 = {2};
            bins reg3 = {3};
            bins reg4 = {4};
            bins reg0 = {0};
        }
        
        // Destination register coverage (rd) - only for R-type
        dest_reg_cp: coverpoint current_instr.rd iff (current_instr.instr_type inside {INSTR_ADD, INSTR_AND}) {
            bins reg1 = {1};
            bins reg2 = {2};
            bins reg3 = {3};
            bins reg4 = {4};
        }
        
        // Memory address coverage - only for LW/SW
        mem_addr_cp: coverpoint current_instr.immediate iff (current_instr.instr_type inside {INSTR_LW, INSTR_SW}) {
            bins addr1 = {16'h0040};
            bins addr2 = {16'h0044};
            bins addr3 = {16'h0048};
            bins addr4 = {16'h004C};
        }
        
        // Branch offset coverage - only for BEQ
        branch_offset_cp: coverpoint current_instr.immediate iff (current_instr.instr_type == INSTR_BEQ) {
            bins offset1 = {1};
            bins offset2 = {2};
            bins offset3 = {3};
            bins offset4 = {4};
        }
        
        // Branch taken/not taken coverage
        branch_taken_cp: coverpoint current_instr.branch_taken iff (current_instr.instr_type == INSTR_BEQ) {
            bins taken = {1};
            bins not_taken = {0};
        }
        
        // Cross coverage: Instruction type with registers
        instr_reg_cross: cross instr_type_cp, src_reg_cp {
            // Focus on our limited instruction and register set
            ignore_bins ignore_invalid = binsof(src_reg_cp.reg0) && binsof(instr_type_cp) intersect {INSTR_ADD, INSTR_AND, INSTR_LW, INSTR_SW, INSTR_BEQ};
        }
        
        // Cross coverage: Branch offset with taken/not taken
        branch_behavior_cross: cross branch_offset_cp, branch_taken_cp;
        
    endgroup: instr_fields_cg
    
    //--------------------------------------------------------------------------
    // Instruction Sequence Coverage
    //--------------------------------------------------------------------------
    covergroup instr_sequence_cg;
        option.per_instance = 1;
        option.name = "instruction_sequences";
        
        // Instruction pairs (current and previous)
        instr_pair_cp: coverpoint {prev_instr.instr_type, current_instr.instr_type} {
            // All combinations of our 5 instruction types (25 total)
            bins add_add = {{INSTR_ADD, INSTR_ADD}};
            bins add_and = {{INSTR_ADD, INSTR_AND}};
            bins add_lw = {{INSTR_ADD, INSTR_LW}};
            bins add_sw = {{INSTR_ADD, INSTR_SW}};
            bins add_beq = {{INSTR_ADD, INSTR_BEQ}};
            
            bins and_add = {{INSTR_AND, INSTR_ADD}};
            bins and_and = {{INSTR_AND, INSTR_AND}};
            bins and_lw = {{INSTR_AND, INSTR_LW}};
            bins and_sw = {{INSTR_AND, INSTR_SW}};
            bins and_beq = {{INSTR_AND, INSTR_BEQ}};
            
            bins lw_add = {{INSTR_LW, INSTR_ADD}};
            bins lw_and = {{INSTR_LW, INSTR_AND}};
            bins lw_lw = {{INSTR_LW, INSTR_LW}};
            bins lw_sw = {{INSTR_LW, INSTR_SW}};
            bins lw_beq = {{INSTR_LW, INSTR_BEQ}};
            
            bins sw_add = {{INSTR_SW, INSTR_ADD}};
            bins sw_and = {{INSTR_SW, INSTR_AND}};
            bins sw_lw = {{INSTR_SW, INSTR_LW}};
            bins sw_sw = {{INSTR_SW, INSTR_SW}};
            bins sw_beq = {{INSTR_SW, INSTR_BEQ}};
            
            bins beq_add = {{INSTR_BEQ, INSTR_ADD}};
            bins beq_and = {{INSTR_BEQ, INSTR_AND}};
            bins beq_lw = {{INSTR_BEQ, INSTR_LW}};
            bins beq_sw = {{INSTR_BEQ, INSTR_SW}};
            bins beq_beq = {{INSTR_BEQ, INSTR_BEQ}};
        }
        
    endgroup: instr_sequence_cg
    
    //--------------------------------------------------------------------------
    // Dependency Coverage
    //--------------------------------------------------------------------------
    covergroup dependency_cg;
        option.per_instance = 1;
        option.name = "dependencies";
        
        // Type of dependency
        dependency_type_cp: coverpoint current_dependency {
            bins no_dependency = {NO_DEP};
            bins reg_wr_dependency = {REG_WR_DEP};
            bins reg_ww_dependency = {REG_WW_DEP};
            bins mem_dependency = {MEM_SW_LW_DEP};
        }
        
        // Gap between dependent instructions
        dependency_gap_cp: coverpoint dependency_gap iff (current_dependency != NO_DEP) {
            bins gap1 = {1};
            bins gap2 = {2};
            bins gap3 = {3};
            bins gap4 = {4};
        }
        
        // Register involved in dependency
        dependent_reg_cp: coverpoint dependent_reg iff (current_dependency inside {REG_WR_DEP, REG_WW_DEP}) {
            bins reg1 = {1};
            bins reg2 = {2};
            bins reg3 = {3};
            bins reg4 = {4};
        }
        
        // Memory address involved in dependency
        dependent_addr_cp: coverpoint dependent_addr iff (current_dependency == MEM_SW_LW_DEP) {
            bins addr1 = {16'h0040};
            bins addr2 = {16'h0044};
            bins addr3 = {16'h0048};
            bins addr4 = {16'h004C};
        }
        
        // Cross coverage: dependency type with gap
        dep_gap_cross: cross dependency_type_cp, dependency_gap_cp;
        
        // Cross coverage: dependency type with register
        dep_reg_cross: cross dependency_type_cp, dependent_reg_cp;
        
    endgroup: dependency_cg
    
    //--------------------------------------------------------------------------
    // Gap Coverage (simplified - tracks consecutive instruction gaps)
    //--------------------------------------------------------------------------
    covergroup gap_cg;
        option.per_instance = 1;
        option.name = "instruction_gaps";
        
        // Simple gap coverage based on instruction addresses
        gap_cp: coverpoint (current_instr.instruction_address - prev_instr.instruction_address) / 4 
                iff (prev_instr != null && current_instr.instruction_address > prev_instr.instruction_address) {
            bins gap1 = {1};
            bins gap2 = {2};
            bins gap3 = {3};
            bins gap4 = {4};
            bins large_gap = {[5:$]};
        }
        
    endgroup: gap_cg
    
    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "mips_coverage_collector", uvm_component parent = null);
        super.new(name, parent);
        
        // Create covergroups
        instr_fields_cg = new();
        instr_sequence_cg = new();
        dependency_cg = new();
        gap_cg = new();
        
        // Initialize tracking variables
        current_instr = null;
        prev_instr = null;
        current_dependency = NO_DEP;
        dependency_gap = 0;
        
    endfunction: new
    
    //--------------------------------------------------------------------------
    // Build Phase
    //--------------------------------------------------------------------------
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        analysis_export = new("analysis_export", this);
        `uvm_info("COVERAGE", "Coverage collector build phase completed", UVM_LOW)
    endfunction: build_phase
    
    //--------------------------------------------------------------------------
    // Write method - called when monitor sends transactions
    //--------------------------------------------------------------------------
    virtual function void write(instruction t);
        // Update current instruction
        current_instr = t;
        
        // Add to history
        instr_history.push_back(t);
        if (instr_history.size() > 10) begin
            instr_history.pop_front(); // Keep only recent history
        end
        
        // Analyze dependencies
        analyze_dependencies();
        
        // Sample all covergroups
        sample_coverage();
        
        // Update previous instruction for next cycle
        prev_instr = current_instr;
        
        // Log coverage sampling
        `uvm_info("COVERAGE", $sformatf("Sampled coverage for instruction: %s", 
            get_instr_string(current_instr)), UVM_HIGH)
        
    endfunction: write
    
    //--------------------------------------------------------------------------
    // Analyze dependencies between instructions
    //--------------------------------------------------------------------------
    virtual function void analyze_dependencies();
        current_dependency = NO_DEP;
        dependency_gap = 0;
        dependent_reg = 0;
        dependent_addr = 0;
        
        if (prev_instr == null) return;
        
        // Check for register dependencies
        if (check_register_dependency()) return;
        
        // Check for memory dependencies
        if (check_memory_dependency()) return;
        
    endfunction: analyze_dependencies
    
    //--------------------------------------------------------------------------
    // Check for register dependencies
    //--------------------------------------------------------------------------
    virtual function bit check_register_dependency();
        // Write-Read dependency: previous instruction writes to register that current reads
        if (prev_instr.instr_type inside {INSTR_ADD, INSTR_AND}) begin
            if ((current_instr.rs == prev_instr.rd) || (current_instr.rt == prev_instr.rd)) begin
                current_dependency = REG_WR_DEP;
                dependency_gap = calculate_gap();
                dependent_reg = prev_instr.rd;
                return 1;
            end
        end
        
        // Write-Write dependency: both instructions write to same register
        if (prev_instr.instr_type inside {INSTR_ADD, INSTR_AND} && 
            current_instr.instr_type inside {INSTR_ADD, INSTR_AND}) begin
            if (current_instr.rd == prev_instr.rd) begin
                current_dependency = REG_WW_DEP;
                dependency_gap = calculate_gap();
                dependent_reg = prev_instr.rd;
                return 1;
            end
        end
        
        return 0;
    endfunction: check_register_dependency
    
    //--------------------------------------------------------------------------
    // Check for memory dependencies
    //--------------------------------------------------------------------------
    virtual function bit check_memory_dependency();
        // Store-Load dependency: SW followed by LW to same address
        if (prev_instr.instr_type == INSTR_SW && current_instr.instr_type == INSTR_LW) begin
            if (current_instr.immediate == prev_instr.immediate) begin
                current_dependency = MEM_SW_LW_DEP;
                dependency_gap = calculate_gap();
                dependent_addr = prev_instr.immediate;
                return 1;
            end
        end
        
        return 0;
    endfunction: check_memory_dependency
    
    //--------------------------------------------------------------------------
    // Calculate gap between instructions
    //--------------------------------------------------------------------------
    virtual function int calculate_gap();
        int addr_diff = current_instr.instruction_address - prev_instr.instruction_address;
        return (addr_diff / 4) - 1; // Convert byte difference to instruction gap
    endfunction: calculate_gap
    
    //--------------------------------------------------------------------------
    // Sample all coverage groups
    //--------------------------------------------------------------------------
    virtual function void sample_coverage();
        if (current_instr != null) begin
            instr_fields_cg.sample();
            gap_cg.sample();
            dependency_cg.sample();
            
            if (prev_instr != null) begin
                instr_sequence_cg.sample();
            end
        end
    endfunction: sample_coverage
    
    //--------------------------------------------------------------------------
    // Get coverage statistics
    //--------------------------------------------------------------------------
    virtual function void report_coverage();
        real coverage_percent;
        
        `uvm_info("COVERAGE", "=== Coverage Report ===", UVM_LOW)
        
        coverage_percent = instr_fields_cg.get_inst_coverage();
        `uvm_info("COVERAGE", $sformatf("Instruction Fields Coverage: %0.2f%%", coverage_percent), UVM_LOW)
        
        coverage_percent = instr_sequence_cg.get_inst_coverage();
        `uvm_info("COVERAGE", $sformatf("Instruction Sequence Coverage: %0.2f%%", coverage_percent), UVM_LOW)
        
        coverage_percent = dependency_cg.get_inst_coverage();
        `uvm_info("COVERAGE", $sformatf("Dependency Coverage: %0.2f%%", coverage_percent), UVM_LOW)
        
        coverage_percent = gap_cg.get_inst_coverage();
        `uvm_info("COVERAGE", $sformatf("Gap Coverage: %0.2f%%", coverage_percent), UVM_LOW)
        
        `uvm_info("COVERAGE", "========================", UVM_LOW)
    endfunction: report_coverage
    
    //--------------------------------------------------------------------------
    // Extract phase - report final coverage
    //--------------------------------------------------------------------------
    virtual function void extract_phase(uvm_phase phase);
        super.extract_phase(phase);
        report_coverage();
    endfunction: extract_phase
    
    //--------------------------------------------------------------------------
    // Helper function to get instruction string
    //--------------------------------------------------------------------------
    virtual function string get_instr_string(instruction instr);
        case (instr.instr_type)
            INSTR_ADD: return $sformatf("ADD $%0d, $%0d, $%0d", instr.rd, instr.rs, instr.rt);
            INSTR_AND: return $sformatf("AND $%0d, $%0d, $%0d", instr.rd, instr.rs, instr.rt);
            INSTR_LW:  return $sformatf("LW $%0d, 0x%0h($%0d)", instr.rt, instr.immediate, instr.rs);
            INSTR_SW:  return $sformatf("SW $%0d, 0x%0h($%0d)", instr.rt, instr.immediate, instr.rs);
            INSTR_BEQ: return $sformatf("BEQ $%0d, $%0d, %0d", instr.rs, instr.rt, instr.immediate);
            default:   return "UNKNOWN";
        endcase
    endfunction: get_instr_string
    
endclass: mips_coverage_collector