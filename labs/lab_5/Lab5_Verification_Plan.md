# Lab 5: MIPS Processor Verification Plan

## 1. Strategy and Architecture

### 1.1 Testbench Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        TESTBENCH                                │
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐                    │
│  │   Instruction   │    │     UVM Test    │                    │
│  │   Generator     │    │   Environment   │                    │
│  │ (Constrained    │    │                 │                    │
│  │   Random SV)    │    │                 │                    │
│  └─────────────────┘    └─────────────────┘                    │
│           │                       │                            │
│           │ Generated              │                            │
│           │ Instructions           │                            │
│           ▼                       │                            │
│  ┌─────────────────┐              │                            │
│  │ Instruction     │              │                            │
│  │ Memory (imem)   │              │                            │
│  └─────────────────┘              │                            │
│           │                       │                            │
│           │ Instructions           │                            │
│           ▼                       ▼                            │
│  ┌─────────────────────────────────────────────────────────────┤
│  │                    DUT (MIPS Processor)                     │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │  │ Controller  │  │  Datapath   │  │ Data Memory │        │
│  │  │             │  │             │  │   (dmem)    │        │
│  │  └─────────────┘  └─────────────┘  └─────────────┘        │
│  └─────────────────────────────────────────────────────────────┤
│           │                       ▲                            │
│           │ PC, Instr             │ Analysis                   │
│           ▼                       │ Port                       │
│  ┌─────────────────┐              │                            │
│  │   UVM Monitor   │──────────────┘                            │
│  │ (Instruction    │                                           │
│  │ Fetch Observer) │                                           │
│  └─────────────────┘                                           │
│           │                                                    │
│           │ Transaction                                        │
│           │ Objects                                            │
│           ▼                                                    │
│  ┌─────────────────┐                                           │
│  │   Coverage      │                                           │
│  │   Collector     │                                           │
│  │ (UVM Subscriber)│                                           │
│  └─────────────────┘                                           │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 Component Descriptions

- **Instruction Generator**: SystemVerilog class with constrained randomization
- **DUT**: MIPS processor from Lab 2 (top.v module)
- **UVM Monitor**: Observes instruction fetch interface (pc, instr signals)
- **Coverage Collector**: UVM subscriber collecting functional coverage
- **UVM Environment**: Connects and manages UVM components

### 1.3 Checker Model Implementation (Not Implemented in This Lab)

An ideal verification environment would include an **Instruction Set Simulator (ISS)** that:
- Maintains a golden reference model of the MIPS processor
- Executes the same instruction stream in parallel
- Compares architectural state (registers, memory) after each instruction
- Flags discrepancies between DUT and reference model

**Implementation approach would include:**
- C/C++ or SystemVerilog ISS model
- Scoreboarding for out-of-order completion
- Register file and memory state comparison
- Pipeline state tracking for proper synchronization

---

## 2. Stimulus Strategy

### 2.1 Random Valid Instruction Generation

**Instruction Set (Limited Scope):**
- ADD (R-type): `add rd, rs, rt`
- AND (R-type): `and rd, rs, rt`  
- LW (I-type): `lw rt, offset(rs)`
- SW (I-type): `sw rt, offset(rs)`
- BEQ (I-type): `beq rs, rt, offset`

**Register Set (Limited Scope):**
- 4 registers: $1, $2, $3, $4 (avoiding $0 which is hardwired to 0)

**Memory Addresses (Limited Scope):**
- 4 data memory addresses: 0x40, 0x44, 0x48, 0x4C

### 2.2 Constraint Types

#### 2.2.1 Individual Instruction Constraints
```systemverilog
// R-type constraints (ADD, AND)
constraint r_type_c {
    if (opcode == ADD || opcode == AND) {
        rd inside {1, 2, 3, 4};
        rs inside {1, 2, 3, 4};
        rt inside {1, 2, 3, 4};
        shamt == 0;
        funct == (opcode == ADD) ? 6'h20 : 6'h24;
    }
}

// Load/Store constraints
constraint mem_c {
    if (opcode == LW || opcode == SW) {
        rt inside {1, 2, 3, 4};
        rs inside {1, 2, 3, 4};
        immediate inside {16'h0040, 16'h0044, 16'h0048, 16'h004C};
    }
}

// Branch constraints
constraint branch_c {
    if (opcode == BEQ) {
        rs inside {1, 2, 3, 4};
        rt inside {1, 2, 3, 4};
        immediate inside {1, 2, 3, 4}; // Branch offsets
    }
}
```

#### 2.2.2 Instruction Sequence Constraints
```systemverilog
// Dependency constraints
constraint dependency_c {
    // Register dependency: ensure first instruction writes to register
    // that second instruction reads from
    if (create_reg_dependency) {
        seq[i].rd == seq[i+gap].rs || seq[i].rd == seq[i+gap].rt;
    }
    
    // Memory dependency: ensure store and load use same address
    if (create_mem_dependency) {
        seq[i].opcode == SW && seq[i+gap].opcode == LW;
        seq[i].immediate == seq[i+gap].immediate;
    }
}

// Gap constraints between dependent instructions
constraint gap_c {
    gap inside {1, 2, 3, 4};
}
```

#### 2.2.3 Branch Target Constraints
```systemverilog
constraint branch_target_c {
    // Ensure branch targets are within program bounds
    if (opcode == BEQ) {
        (current_pc + 4 + (immediate << 2)) >= program_start;
        (current_pc + 4 + (immediate << 2)) <= program_end;
    }
}
```

---

## 3. Functional Coverage Model

### 3.1 Coverage Strategy

**Coverage Dimensions:**
1. **Instruction-level coverage**: Individual instruction fields
2. **Sequence-level coverage**: Instruction pairs and dependencies  
3. **Timing-level coverage**: Gaps between dependent instructions
4. **Branch coverage**: Taken/not-taken scenarios

### 3.2 Specific Coverage Points

#### 3.2.1 Individual Instruction Coverage
```systemverilog
covergroup instr_cg;
    // Opcode coverage
    opcode_cp: coverpoint current_instr.opcode {
        bins add_bin = {ADD};
        bins and_bin = {AND};
        bins lw_bin = {LW};
        bins sw_bin = {SW};
        bins beq_bin = {BEQ};
    }
    
    // Register usage coverage
    src_reg_cp: coverpoint current_instr.rs {
        bins reg_bins[] = {1, 2, 3, 4};
    }
    
    dst_reg_cp: coverpoint current_instr.rd {
        bins reg_bins[] = {1, 2, 3, 4};
    }
    
    // Memory address coverage
    mem_addr_cp: coverpoint current_instr.immediate {
        bins addr_bins[] = {16'h0040, 16'h0044, 16'h0048, 16'h004C};
    }
    
    // Branch taken/not taken
    branch_taken_cp: coverpoint branch_taken iff (current_instr.opcode == BEQ) {
        bins taken = {1};
        bins not_taken = {0};
    }
endgroup
```

#### 3.2.2 Instruction Sequence Coverage
```systemverilog
covergroup seq_cg;
    // Instruction pairs
    instr_seq_cp: coverpoint {prev_instr.opcode, current_instr.opcode} {
        bins add_add = {ADD, ADD};
        bins add_and = {ADD, AND};
        bins add_lw = {ADD, LW};
        bins sw_lw = {SW, LW};
        bins lw_add = {LW, ADD};
        // ... all 25 combinations
    }
    
    // Register dependencies
    reg_dependency_cp: coverpoint reg_dependency_type {
        bins write_read = {WR_DEP};
        bins read_write = {RW_DEP};
        bins write_write = {WW_DEP};
        bins no_dependency = {NO_DEP};
    }
    
    // Memory dependencies
    mem_dependency_cp: coverpoint mem_dependency_type {
        bins store_load_same_addr = {SW_LW_SAME};
        bins store_load_diff_addr = {SW_LW_DIFF};
        bins no_mem_dependency = {NO_MEM_DEP};
    }
endgroup
```

#### 3.2.3 Timing Coverage
```systemverilog
covergroup gap_cg;
    // Gaps between dependent instructions
    dependency_gap_cp: coverpoint gap iff (has_dependency) {
        bins gap_1 = {1};
        bins gap_2 = {2};
        bins gap_3 = {3};
        bins gap_4 = {4};
    }
    
    // Cross coverage: dependency type vs gap
    dep_gap_cross: cross reg_dependency_cp, dependency_gap_cp;
endgroup
```

#### 3.2.4 Branch Offset Coverage
```systemverilog
covergroup branch_cg;
    branch_offset_cp: coverpoint current_instr.immediate iff (current_instr.opcode == BEQ) {
        bins offset_1 = {1};
        bins offset_2 = {2};
        bins offset_3 = {3};
        bins offset_4 = {4};
    }
    
    // Cross coverage: branch offset vs taken/not taken
    branch_behavior_cross: cross branch_offset_cp, branch_taken_cp;
endgroup
```

---

## 4. Checking Strategy

### 4.1 Planned Checks (Not Implemented in This Lab)

#### 4.1.1 Architectural State Checks
- **Register File Verification**: Compare register values after each instruction
- **Memory Consistency**: Verify data memory contents match expected values
- **PC Progression**: Ensure program counter advances correctly

#### 4.1.2 Instruction Execution Checks
- **ADD Instruction**: `rd = rs + rt`
- **AND Instruction**: `rd = rs & rt`  
- **LW Instruction**: `rt = memory[rs + offset]`
- **SW Instruction**: `memory[rs + offset] = rt`
- **BEQ Instruction**: `if (rs == rt) pc = pc + 4 + (offset << 2)`

#### 4.1.3 Interface Protocol Checks
- **Memory Interface**: Verify memwrite signal timing and data validity
- **Instruction Fetch**: Ensure pc increments properly and instruction data is valid
- **Reset Behavior**: Verify proper initialization after reset

#### 4.1.4 Corner Case Checks
- **Branch to Same Address**: Infinite loop detection
- **Memory Boundary**: Verify no out-of-bounds memory access
- **Register $0**: Ensure writes to $0 are ignored (always reads 0)

#### 4.1.5 Temporal Checks
- **Instruction Completion**: Verify each instruction completes within expected cycles
- **Pipeline Hazards**: Check for proper hazard handling (if applicable)
- **Reset Recovery**: Verify proper behavior after reset deassertion

---

## 5. Implementation Phases

### Phase 1: Instruction Generator (Part 2)
- Create instruction class with UVM transaction base
- Implement constraints for valid instruction generation
- Build sequence generator with dependency tracking
- Create assembler function for machine code conversion

### Phase 2: UVM Monitor (Part 3a)  
- Monitor instruction fetch interface
- Create transaction objects from observed signals
- Post transactions to analysis port

### Phase 3: Coverage Collector (Part 3b)
- Implement functional coverage model
- Subscribe to monitor transactions
- Sample coverage on each instruction

### Phase 4: Environment & Integration (Part 3c)
- Create UVM environment connecting components
- Integrate with instruction generator
- Run multiple seeds to achieve 100% coverage

---

## 6. Success Criteria

- **100% Functional Coverage**: All defined coverpoints and crosses hit
- **Valid Stimulus**: All generated instructions are architecturally correct
- **Proper Dependencies**: Register and memory dependencies correctly generated
- **Branch Coverage**: Both taken and not-taken branches exercised
- **Gap Coverage**: All dependency gaps (1,2,3,4) covered
- **Clean Simulation**: No protocol violations or invalid transactions

---

*This verification plan provides the roadmap for comprehensive MIPS processor verification using constrained random stimulus and functional coverage methodology.*