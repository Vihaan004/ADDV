//==============================================================================
// Lab 5: MIPS UVM Monitor
// This monitor observes the instruction fetch interface and creates transactions
//==============================================================================

`include "uvm_macros.svh"
import uvm_pkg::*;

// Include our instruction transaction class
`include "mips_instruction_generator.sv"

//==============================================================================
// MIPS Interface Definition
//==============================================================================
interface mips_if (input bit clk);
    // Instruction fetch interface signals
    logic [31:0] pc;            // Program counter
    logic [31:0] instr;         // Current instruction
    logic        reset;         // Reset signal
    
    // Data memory interface signals  
    logic [31:0] dataadr;       // Data memory address
    logic [31:0] writedata;     // Data to write to memory
    logic [31:0] readdata;      // Data read from memory
    logic        memwrite;      // Memory write enable
    
    // Clock and reset
    logic        clk_i;
    assign clk_i = clk;
    
    // Modports for different components
    modport monitor (
        input clk_i, reset, pc, instr, dataadr, writedata, readdata, memwrite
    );
    
    modport dut (
        input clk_i, reset,
        output pc, instr, dataadr, writedata, memwrite,
        input readdata
    );
    
endinterface: mips_if


//==============================================================================
// MIPS Monitor Class
//==============================================================================
class mips_monitor extends uvm_monitor;
    `uvm_component_utils(mips_monitor)
    
    // Virtual interface
    virtual mips_if vif;
    
    // Analysis port to send transactions
    uvm_analysis_port #(instruction) ap;
    
    // Configuration and state tracking
    bit monitor_enabled = 1;
    int instruction_count = 0;
    
    // Previous state for edge detection
    bit [31:0] prev_pc = 0;
    bit [31:0] prev_instr = 0;
    
    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "mips_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction: new
    
    //--------------------------------------------------------------------------
    // Build Phase
    //--------------------------------------------------------------------------
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Create analysis port
        ap = new("ap", this);
        
        // Get virtual interface from resource database
        if (!uvm_config_db#(virtual mips_if)::get(this, "", "mips_vif", vif)) begin
            `uvm_fatal("MONITOR", "Could not get virtual interface from config DB")
        end
        
        `uvm_info("MONITOR", "MIPS Monitor build phase completed", UVM_LOW)
    endfunction: build_phase
    
    //--------------------------------------------------------------------------
    // Run Phase - Main monitoring task
    //--------------------------------------------------------------------------
    virtual task run_phase(uvm_phase phase);
        `uvm_info("MONITOR", "MIPS Monitor run phase started", UVM_LOW)
        
        // Wait for reset deassertion
        wait_for_reset();
        
        // Start monitoring
        fork
            monitor_instruction_fetch();
            monitor_data_memory();
        join_none
        
    endtask: run_phase
    
    //--------------------------------------------------------------------------
    // Wait for reset to be deasserted
    //--------------------------------------------------------------------------
    virtual task wait_for_reset();
        `uvm_info("MONITOR", "Waiting for reset deassertion...", UVM_LOW)
        wait(!vif.reset);
        @(posedge vif.clk_i);
        `uvm_info("MONITOR", "Reset deasserted, starting monitoring", UVM_LOW)
    endtask: wait_for_reset
    
    //--------------------------------------------------------------------------
    // Monitor instruction fetch interface
    //--------------------------------------------------------------------------
    virtual task monitor_instruction_fetch();
        instruction instr_txn;
        bit new_instruction_detected;
        
        `uvm_info("MONITOR", "Starting instruction fetch monitoring", UVM_LOW)
        
        forever begin
            @(posedge vif.clk_i);
            
            if (vif.reset) begin
                // Reset detected, reinitialize
                prev_pc = 0;
                prev_instr = 0;
                instruction_count = 0;
                wait_for_reset();
                continue;
            end
            
            // Detect new instruction fetch (PC change or instruction change)
            new_instruction_detected = (vif.pc != prev_pc) || (vif.instr != prev_instr);
            
            if (new_instruction_detected && monitor_enabled) begin
                // Create and populate transaction
                instr_txn = instruction::type_id::create($sformatf("instr_%0d", instruction_count));
                
                if (decode_instruction(vif.instr, instr_txn)) begin
                    // Set transaction metadata
                    instr_txn.instruction_address = vif.pc;
                    instr_txn.machine_code = vif.instr;
                    
                    // Send transaction to coverage collector
                    ap.write(instr_txn);
                    
                    // Log the instruction
                    `uvm_info("MONITOR", $sformatf("Instruction %0d: PC=0x%08h, %s [0x%08h]", 
                        instruction_count, vif.pc, get_instruction_string(instr_txn), vif.instr), UVM_MEDIUM)
                    
                    instruction_count++;
                end else begin
                    `uvm_warning("MONITOR", $sformatf("Could not decode instruction 0x%08h at PC=0x%08h", 
                        vif.instr, vif.pc))
                end
                
                // Update previous state
                prev_pc = vif.pc;
                prev_instr = vif.instr;
            end
        end
    endtask: monitor_instruction_fetch
    
    //--------------------------------------------------------------------------
    // Monitor data memory interface for branch taken/not taken
    //--------------------------------------------------------------------------
    virtual task monitor_data_memory();
        `uvm_info("MONITOR", "Starting data memory monitoring", UVM_LOW)
        
        forever begin
            @(posedge vif.clk_i);
            
            if (vif.reset) continue;
            
            // Monitor memory writes
            if (vif.memwrite) begin
                `uvm_info("MONITOR", $sformatf("Memory Write: Addr=0x%08h, Data=0x%08h", 
                    vif.dataadr, vif.writedata), UVM_HIGH)
            end
        end
    endtask: monitor_data_memory
    
    //--------------------------------------------------------------------------
    // Decode MIPS instruction into transaction object
    //--------------------------------------------------------------------------
    virtual function bit decode_instruction(bit [31:0] machine_code, instruction instr_txn);
        bit [5:0] opcode;
        bit [4:0] rs, rt, rd, shamt;
        bit [5:0] funct;
        bit [15:0] immediate;
        
        // Extract fields
        opcode = machine_code[31:26];
        rs = machine_code[25:21];
        rt = machine_code[20:16];
        rd = machine_code[15:11];
        shamt = machine_code[10:6];
        funct = machine_code[5:0];
        immediate = machine_code[15:0];
        
        // Decode based on opcode
        case (opcode)
            6'b000000: begin // R-type instructions
                case (funct)
                    6'b100000: begin // ADD
                        instr_txn.instr_type = INSTR_ADD;
                        instr_txn.rs = rs;
                        instr_txn.rt = rt;
                        instr_txn.rd = rd;
                        instr_txn.shamt = shamt;
                        instr_txn.immediate = 0;
                        return 1;
                    end
                    6'b100100: begin // AND
                        instr_txn.instr_type = INSTR_AND;
                        instr_txn.rs = rs;
                        instr_txn.rt = rt;
                        instr_txn.rd = rd;
                        instr_txn.shamt = shamt;
                        instr_txn.immediate = 0;
                        return 1;
                    end
                    default: begin
                        `uvm_warning("MONITOR", $sformatf("Unknown R-type function: 0x%02h", funct))
                        return 0;
                    end
                endcase
            end
            
            6'b100011: begin // LW (Load Word)
                instr_txn.instr_type = INSTR_LW;
                instr_txn.rs = rs;
                instr_txn.rt = rt;
                instr_txn.rd = 0;
                instr_txn.shamt = 0;
                instr_txn.immediate = immediate;
                return 1;
            end
            
            6'b101011: begin // SW (Store Word)
                instr_txn.instr_type = INSTR_SW;
                instr_txn.rs = rs;
                instr_txn.rt = rt;
                instr_txn.rd = 0;
                instr_txn.shamt = 0;
                instr_txn.immediate = immediate;
                return 1;
            end
            
            6'b000100: begin // BEQ (Branch Equal)
                instr_txn.instr_type = INSTR_BEQ;
                instr_txn.rs = rs;
                instr_txn.rt = rt;
                instr_txn.rd = 0;
                instr_txn.shamt = 0;
                instr_txn.immediate = immediate;
                
                // Determine if branch was taken by checking PC progression
                // This would need additional logic to track PC changes
                instr_txn.branch_taken = 0; // Simplified for now
                return 1;
            end
            
            default: begin
                `uvm_warning("MONITOR", $sformatf("Unknown opcode: 0x%02h", opcode))
                return 0;
            end
        endcase
        
        return 0;
    endfunction: decode_instruction
    
    //--------------------------------------------------------------------------
    // Convert instruction transaction to readable string
    //--------------------------------------------------------------------------
    virtual function string get_instruction_string(instruction instr_txn);
        case (instr_txn.instr_type)
            INSTR_ADD: return $sformatf("ADD $%0d, $%0d, $%0d", instr_txn.rd, instr_txn.rs, instr_txn.rt);
            INSTR_AND: return $sformatf("AND $%0d, $%0d, $%0d", instr_txn.rd, instr_txn.rs, instr_txn.rt);
            INSTR_LW:  return $sformatf("LW $%0d, 0x%0h($%0d)", instr_txn.rt, instr_txn.immediate, instr_txn.rs);
            INSTR_SW:  return $sformatf("SW $%0d, 0x%0h($%0d)", instr_txn.rt, instr_txn.immediate, instr_txn.rs);
            INSTR_BEQ: return $sformatf("BEQ $%0d, $%0d, %0d%s", instr_txn.rs, instr_txn.rt, 
                                       instr_txn.immediate, instr_txn.branch_taken ? " (taken)" : " (not taken)");
            default:   return "UNKNOWN";
        endcase
    endfunction: get_instruction_string
    
    //--------------------------------------------------------------------------
    // Enable/disable monitoring
    //--------------------------------------------------------------------------
    virtual function void set_monitoring(bit enable);
        monitor_enabled = enable;
        `uvm_info("MONITOR", $sformatf("Monitoring %s", enable ? "enabled" : "disabled"), UVM_LOW)
    endfunction: set_monitoring
    
    //--------------------------------------------------------------------------
    // Get statistics
    //--------------------------------------------------------------------------
    virtual function int get_instruction_count();
        return instruction_count;
    endfunction: get_instruction_count
    
endclass: mips_monitor