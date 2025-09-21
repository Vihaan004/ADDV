//==============================================================================
// Lab 5: MIPS Instruction Generator
// This file implements constrained random instruction generation for MIPS verification
//==============================================================================

`include "uvm_macros.svh"
import uvm_pkg::*;

// MIPS Instruction opcodes and function codes
typedef enum bit [5:0] {
    R_TYPE = 6'b000000,  // ADD, AND use R-type format
    LW     = 6'b100011,  // Load Word
    SW     = 6'b101011,  // Store Word  
    BEQ    = 6'b000100   // Branch Equal
} opcode_e;

typedef enum bit [5:0] {
    ADD_FUNCT = 6'b100000,  // ADD function code
    AND_FUNCT = 6'b100100   // AND function code  
} funct_e;

typedef enum {
    INSTR_ADD,
    INSTR_AND, 
    INSTR_LW,
    INSTR_SW,
    INSTR_BEQ
} instr_type_e;

//==============================================================================
// Instruction Transaction Class
//==============================================================================
class instruction extends uvm_transaction;
    
    // Instruction fields
    rand instr_type_e instr_type;
    rand bit [4:0] rs, rt, rd;
    rand bit [15:0] immediate;
    rand bit [4:0] shamt;
    
    // Derived fields (not randomized directly)
    bit [5:0] opcode;
    bit [5:0] funct;
    bit [31:0] machine_code;
    
    // Metadata for coverage
    bit branch_taken;
    int instruction_address;
    
    `uvm_object_utils_begin(instruction)
        `uvm_field_enum(instr_type_e, instr_type, UVM_ALL_ON)
        `uvm_field_int(rs, UVM_ALL_ON)
        `uvm_field_int(rt, UVM_ALL_ON) 
        `uvm_field_int(rd, UVM_ALL_ON)
        `uvm_field_int(immediate, UVM_ALL_ON)
        `uvm_field_int(machine_code, UVM_ALL_ON)
    `uvm_object_utils_end
    
    //--------------------------------------------------------------------------
    // Constraints
    //--------------------------------------------------------------------------
    
    // Valid instruction types
    constraint valid_instr_c {
        instr_type inside {INSTR_ADD, INSTR_AND, INSTR_LW, INSTR_SW, INSTR_BEQ};
    }
    
    // Register constraints - limit to 4 registers ($1, $2, $3, $4)
    constraint reg_c {
        rs inside {1, 2, 3, 4};
        rt inside {1, 2, 3, 4};
        rd inside {1, 2, 3, 4};
    }
    
    // R-type instruction constraints (ADD, AND)
    constraint r_type_c {
        if (instr_type == INSTR_ADD || instr_type == INSTR_AND) {
            // rd can be any of our 4 registers
            rd inside {1, 2, 3, 4};
            // rs and rt are source registers
            rs inside {1, 2, 3, 4};
            rt inside {1, 2, 3, 4};
            // No shift amount for ADD/AND
            shamt == 0;
            // immediate not used in R-type
            immediate == 0;
        }
    }
    
    // Load/Store instruction constraints
    constraint ls_type_c {
        if (instr_type == INSTR_LW || instr_type == INSTR_SW) {
            // rt is target/source register
            rt inside {1, 2, 3, 4};
            // rs is base address register  
            rs inside {1, 2, 3, 4};
            // Memory addresses - limit to 4 addresses
            immediate inside {16'h0040, 16'h0044, 16'h0048, 16'h004C};
            // rd not used in I-type
            rd == 0;
            shamt == 0;
        }
    }
    
    // Branch instruction constraints
    constraint branch_c {
        if (instr_type == INSTR_BEQ) {
            // rs and rt are compared registers
            rs inside {1, 2, 3, 4};
            rt inside {1, 2, 3, 4};
            // Branch offsets - limit to 4 values
            immediate inside {1, 2, 3, 4};
            // rd not used in branch
            rd == 0;
            shamt == 0;
        }
    }
    
    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "instruction");
        super.new(name);
    endfunction
    
    //--------------------------------------------------------------------------
    // Post-randomize: Set opcode and funct based on instruction type
    //--------------------------------------------------------------------------
    function void post_randomize();
        case (instr_type)
            INSTR_ADD: begin
                opcode = R_TYPE;
                funct = ADD_FUNCT;
            end
            INSTR_AND: begin
                opcode = R_TYPE;
                funct = AND_FUNCT;
            end
            INSTR_LW: begin
                opcode = LW;
                funct = 6'b000000;
            end
            INSTR_SW: begin
                opcode = SW;
                funct = 6'b000000;
            end
            INSTR_BEQ: begin
                opcode = BEQ;
                funct = 6'b000000;
            end
        endcase
        
        // Generate machine code
        generate_machine_code();
    endfunction
    
    //--------------------------------------------------------------------------
    // Generate machine code from instruction fields
    //--------------------------------------------------------------------------
    function void generate_machine_code();
        case (instr_type)
            INSTR_ADD, INSTR_AND: begin
                // R-type: [opcode(6) | rs(5) | rt(5) | rd(5) | shamt(5) | funct(6)]
                machine_code = {opcode, rs, rt, rd, shamt, funct};
            end
            INSTR_LW, INSTR_SW, INSTR_BEQ: begin
                // I-type: [opcode(6) | rs(5) | rt(5) | immediate(16)]
                machine_code = {opcode, rs, rt, immediate};
            end
        endcase
    endfunction
    
    //--------------------------------------------------------------------------
    // Display function
    //--------------------------------------------------------------------------
    function void print_instruction();
        string instr_str;
        case (instr_type)
            INSTR_ADD: instr_str = $sformatf("ADD $%0d, $%0d, $%0d", rd, rs, rt);
            INSTR_AND: instr_str = $sformatf("AND $%0d, $%0d, $%0d", rd, rs, rt);
            INSTR_LW:  instr_str = $sformatf("LW $%0d, 0x%0h($%0d)", rt, immediate, rs);
            INSTR_SW:  instr_str = $sformatf("SW $%0d, 0x%0h($%0d)", rt, immediate, rs);
            INSTR_BEQ: instr_str = $sformatf("BEQ $%0d, $%0d, %0d", rs, rt, immediate);
        endcase
        `uvm_info("INSTRUCTION", $sformatf("%s [0x%08h]", instr_str, machine_code), UVM_LOW)
    endfunction
    
endclass: instruction


//==============================================================================
// Instruction Sequence Generator
//==============================================================================
class instruction_generator;
    
    // Dynamic array to store generated instruction sequence
    instruction instr_queue[$];
    bit [31:0] machine_code_queue[$];
    
    // Control parameters
    int num_instructions = 20;  // Default sequence length
    int num_dependencies = 5;   // Number of dependent instruction pairs
    
    // Dependency tracking
    typedef struct {
        int first_instr_idx;
        int second_instr_idx; 
        int gap;
        bit is_reg_dependency;
        bit is_mem_dependency;
        bit [4:0] dependent_reg;
        bit [15:0] dependent_addr;
    } dependency_t;
    
    dependency_t dependency_list[$];
    
    //--------------------------------------------------------------------------
    // Constructor  
    //--------------------------------------------------------------------------
    function new();
        instr_queue = {};
        machine_code_queue = {};
        dependency_list = {};
    endfunction
    
    //--------------------------------------------------------------------------
    // Generate individual random instructions
    //--------------------------------------------------------------------------
    function void generate_individual_instructions(int count = 10);
        instruction instr;
        
        `uvm_info("INSTR_GEN", $sformatf("Generating %0d individual instructions", count), UVM_LOW)
        
        for (int i = 0; i < count; i++) begin
            instr = instruction::type_id::create($sformatf("instr_%0d", i));
            
            if (!instr.randomize()) begin
                `uvm_error("INSTR_GEN", $sformatf("Failed to randomize instruction %0d", i))
                continue;
            end
            
            instr.instruction_address = i * 4;  // Word-aligned addresses
            instr.print_instruction();
            instr_queue.push_back(instr);
        end
    endfunction
    
    //--------------------------------------------------------------------------
    // Generate instruction pairs with dependencies
    //--------------------------------------------------------------------------
    function void generate_dependent_pairs(int count = 5);
        instruction instr1, instr2;
        int gap;
        int base_idx = instr_queue.size();
        
        `uvm_info("INSTR_GEN", $sformatf("Generating %0d dependent instruction pairs", count), UVM_LOW)
        
        for (int i = 0; i < count; i++) begin
            // Randomize gap between dependent instructions (1-4)
            gap = $urandom_range(1, 4);
            
            // Create first instruction
            instr1 = instruction::type_id::create($sformatf("dep_instr1_%0d", i));
            
            // Generate register dependency: first instruction writes, second reads
            if ($urandom_range(0, 1)) begin
                // Register dependency case
                bit [4:0] shared_reg = $urandom_range(1, 4);
                
                // First instruction must write to shared_reg (ADD or AND)
                if (!instr1.randomize() with {
                    instr_type inside {INSTR_ADD, INSTR_AND};
                    rd == shared_reg;
                }) begin
                    `uvm_error("INSTR_GEN", "Failed to randomize first dependent instruction")
                    continue;
                end
                
                instr1.instruction_address = (base_idx + instr_queue.size()) * 4;
                instr_queue.push_back(instr1);
                
                // Add gap instructions
                for (int j = 0; j < gap; j++) begin
                    instruction gap_instr = instruction::type_id::create($sformatf("gap_%0d_%0d", i, j));
                    if (!gap_instr.randomize()) continue;
                    gap_instr.instruction_address = (base_idx + instr_queue.size()) * 4;
                    instr_queue.push_back(gap_instr);
                end
                
                // Second instruction reads from shared_reg
                instr2 = instruction::type_id::create($sformatf("dep_instr2_%0d", i));
                if (!instr2.randomize() with {
                    (rs == shared_reg) || (rt == shared_reg);
                }) begin
                    `uvm_error("INSTR_GEN", "Failed to randomize second dependent instruction")
                    continue;
                end
                
                instr2.instruction_address = (base_idx + instr_queue.size()) * 4;
                instr_queue.push_back(instr2);
                
                // Record dependency
                dependency_t dep;
                dep.first_instr_idx = instr_queue.size() - gap - 2;
                dep.second_instr_idx = instr_queue.size() - 1;
                dep.gap = gap;
                dep.is_reg_dependency = 1;
                dep.dependent_reg = shared_reg;
                dependency_list.push_back(dep);
                
                `uvm_info("INSTR_GEN", $sformatf("Created register dependency: $%0d, gap=%0d", shared_reg, gap), UVM_LOW)
                
            end else begin
                // Memory dependency case (SW followed by LW to same address)
                bit [15:0] shared_addr = {16'h0040, 16'h0044, 16'h0048, 16'h004C}[$urandom_range(0,3)];
                
                // First instruction: SW to shared_addr
                if (!instr1.randomize() with {
                    instr_type == INSTR_SW;
                    immediate == shared_addr;
                }) begin
                    `uvm_error("INSTR_GEN", "Failed to randomize SW instruction")
                    continue;
                end
                
                instr1.instruction_address = (base_idx + instr_queue.size()) * 4;
                instr_queue.push_back(instr1);
                
                // Add gap instructions  
                for (int j = 0; j < gap; j++) begin
                    instruction gap_instr = instruction::type_id::create($sformatf("gap_%0d_%0d", i, j));
                    if (!gap_instr.randomize()) continue;
                    gap_instr.instruction_address = (base_idx + instr_queue.size()) * 4;
                    instr_queue.push_back(gap_instr);
                end
                
                // Second instruction: LW from shared_addr
                instr2 = instruction::type_id::create($sformatf("dep_instr2_%0d", i));
                if (!instr2.randomize() with {
                    instr_type == INSTR_LW;
                    immediate == shared_addr;
                }) begin
                    `uvm_error("INSTR_GEN", "Failed to randomize LW instruction")
                    continue;
                end
                
                instr2.instruction_address = (base_idx + instr_queue.size()) * 4;
                instr_queue.push_back(instr2);
                
                // Record dependency
                dependency_t dep;
                dep.first_instr_idx = instr_queue.size() - gap - 2;
                dep.second_instr_idx = instr_queue.size() - 1;
                dep.gap = gap;
                dep.is_mem_dependency = 1;
                dep.dependent_addr = shared_addr;
                dependency_list.push_back(dep);
                
                `uvm_info("INSTR_GEN", $sformatf("Created memory dependency: addr=0x%0h, gap=%0d", shared_addr, gap), UVM_LOW)
            end
        end
    endfunction
    
    //--------------------------------------------------------------------------
    // Generate complete instruction sequence
    //--------------------------------------------------------------------------
    function void generate_sequence();
        `uvm_info("INSTR_GEN", "Starting instruction sequence generation", UVM_LOW)
        
        // Clear previous sequence
        instr_queue = {};
        machine_code_queue = {};
        dependency_list = {};
        
        // Add initialization instructions (setup registers)
        add_setup_instructions();
        
        // Generate individual random instructions
        generate_individual_instructions(10);
        
        // Generate dependent instruction pairs
        generate_dependent_pairs(5);
        
        // Generate final machine code array
        generate_machine_code_sequence();
        
        `uvm_info("INSTR_GEN", $sformatf("Generated sequence with %0d instructions", instr_queue.size()), UVM_LOW)
    endfunction
    
    //--------------------------------------------------------------------------
    // Add setup instructions to initialize registers
    //--------------------------------------------------------------------------
    function void add_setup_instructions();
        instruction setup_instr;
        
        // Initialize registers $1-$4 with known values
        for (int i = 1; i <= 4; i++) begin
            setup_instr = instruction::type_id::create($sformatf("setup_%0d", i));
            
            // Create ADDI instruction to initialize register
            // For simplicity, we'll create ADD $i, $0, $0 + immediate (simulated as simple loads)
            if (!setup_instr.randomize() with {
                instr_type == INSTR_ADD;
                rd == i;
                rs == 0;  // $0 is always 0
                rt == 0;
            }) begin
                `uvm_error("INSTR_GEN", $sformatf("Failed to create setup instruction for $%0d", i))
                continue;
            end
            
            setup_instr.instruction_address = instr_queue.size() * 4;
            instr_queue.push_back(setup_instr);
        end
    endfunction
    
    //--------------------------------------------------------------------------
    // Generate machine code sequence
    //--------------------------------------------------------------------------
    function void generate_machine_code_sequence();
        machine_code_queue = {};
        
        foreach (instr_queue[i]) begin
            machine_code_queue.push_back(instr_queue[i].machine_code);
        end
        
        `uvm_info("INSTR_GEN", $sformatf("Generated %0d machine code words", machine_code_queue.size()), UVM_LOW)
    endfunction
    
    //--------------------------------------------------------------------------
    // Write machine code to memory file
    //--------------------------------------------------------------------------
    function void write_to_memfile(string filename = "generated_program.dat");
        int file_handle;
        
        file_handle = $fopen(filename, "w");
        if (file_handle == 0) begin
            `uvm_error("INSTR_GEN", $sformatf("Could not open file %s for writing", filename))
            return;
        end
        
        foreach (machine_code_queue[i]) begin
            $fdisplay(file_handle, "%08h", machine_code_queue[i]);
        end
        
        $fclose(file_handle);
        `uvm_info("INSTR_GEN", $sformatf("Wrote %0d instructions to %s", machine_code_queue.size(), filename), UVM_LOW)
    endfunction
    
    //--------------------------------------------------------------------------
    // Get instruction queue (for testbench use)
    //--------------------------------------------------------------------------
    function instruction[$] get_instruction_queue();
        return instr_queue;
    endfunction
    
    //--------------------------------------------------------------------------
    // Get machine code queue (for memory loading)
    //--------------------------------------------------------------------------
    function bit [31:0][$] get_machine_code_queue();
        return machine_code_queue;
    endfunction
    
endclass: instruction_generator