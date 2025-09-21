//==============================================================================
// Lab 5: Simple Instruction Generator Test (without UVM)
// This is a standalone test to verify the instruction generator works
//==============================================================================

`include "mips_instruction_generator.sv"

module simple_instr_test;

    // Test the instruction generator
    instruction_generator gen;
    instruction instr_list[$];
    bit [31:0] machine_code_list[$];
    
    initial begin
        $display("=== MIPS Instruction Generator Test ===");
        
        // Create generator
        gen = new();
        
        // Test 1: Generate simple sequence
        $display("\n--- Test 1: Generating instruction sequence ---");
        gen.generate_sequence();
        
        // Get results
        instr_list = gen.get_instruction_queue();
        machine_code_list = gen.get_machine_code_queue();
        
        // Display results
        $display("Generated %0d instructions:", instr_list.size());
        for (int i = 0; i < instr_list.size(); i++) begin
            $display("  [%02d] 0x%08h - %s", i, machine_code_list[i], get_instr_string(instr_list[i]));
        end
        
        // Test 2: Test individual instruction randomization
        $display("\n--- Test 2: Individual instruction randomization ---");
        for (int i = 0; i < 10; i++) begin
            instruction test_instr = new($sformatf("test_%0d", i));
            if (test_instr.randomize()) begin
                $display("  Random instruction: %s [0x%08h]", get_instr_string(test_instr), test_instr.machine_code);
            end else begin
                $display("  ERROR: Failed to randomize instruction %0d", i);
            end
        end
        
        // Test 3: Test specific constraints
        $display("\n--- Test 3: Testing specific constraints ---");
        test_add_constraints();
        test_lw_constraints();
        test_beq_constraints();
        
        // Write output file
        gen.write_to_memfile("test_program.dat");
        $display("\n--- Test completed successfully ---");
        $finish;
    end
    
    // Helper function to convert instruction to string
    function string get_instr_string(instruction instr);
        case (instr.instr_type)
            INSTR_ADD: return $sformatf("ADD $%0d, $%0d, $%0d", instr.rd, instr.rs, instr.rt);
            INSTR_AND: return $sformatf("AND $%0d, $%0d, $%0d", instr.rd, instr.rs, instr.rt);
            INSTR_LW:  return $sformatf("LW $%0d, 0x%0h($%0d)", instr.rt, instr.immediate, instr.rs);
            INSTR_SW:  return $sformatf("SW $%0d, 0x%0h($%0d)", instr.rt, instr.immediate, instr.rs);
            INSTR_BEQ: return $sformatf("BEQ $%0d, $%0d, %0d", instr.rs, instr.rt, instr.immediate);
            default:   return "UNKNOWN";
        endcase
    endfunction
    
    // Test ADD instruction constraints
    task test_add_constraints();
        instruction add_instr = new("test_add");
        $display("Testing ADD constraints:");
        for (int i = 0; i < 5; i++) begin
            if (add_instr.randomize() with { instr_type == INSTR_ADD; }) begin
                $display("  ADD: rd=$%0d, rs=$%0d, rt=$%0d [0x%08h]", 
                    add_instr.rd, add_instr.rs, add_instr.rt, add_instr.machine_code);
            end
        end
    endtask
    
    // Test LW instruction constraints  
    task test_lw_constraints();
        instruction lw_instr = new("test_lw");
        $display("Testing LW constraints:");
        for (int i = 0; i < 5; i++) begin
            if (lw_instr.randomize() with { instr_type == INSTR_LW; }) begin
                $display("  LW: rt=$%0d, addr=0x%0h, rs=$%0d [0x%08h]", 
                    lw_instr.rt, lw_instr.immediate, lw_instr.rs, lw_instr.machine_code);
            end
        end
    endtask
    
    // Test BEQ instruction constraints
    task test_beq_constraints();
        instruction beq_instr = new("test_beq");
        $display("Testing BEQ constraints:");
        for (int i = 0; i < 5; i++) begin
            if (beq_instr.randomize() with { instr_type == INSTR_BEQ; }) begin
                $display("  BEQ: rs=$%0d, rt=$%0d, offset=%0d [0x%08h]", 
                    beq_instr.rs, beq_instr.rt, beq_instr.immediate, beq_instr.machine_code);
            end
        end
    endtask

endmodule