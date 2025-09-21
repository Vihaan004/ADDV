# Lab 5: MIPS Verification - Complete Implementation Summary

## Project Overview
This lab implements a comprehensive verification environment for the MIPS processor from Lab 2 using SystemVerilog and UVM (Universal Verification Methodology). The verification covers 5 key instructions: ADD, AND, LW, SW, and BEQ.

## Implementation Structure

### Part 1: Verification Plan ✅ COMPLETED
**File:** `Lab5_Verification_Plan.md`

- **Testbench Architecture**: Complete block diagram showing DUT, instruction generator, monitor, and coverage collector
- **Stimulus Strategy**: Constrained randomization for 5 instructions, 4 registers, 4 memory addresses, 4 dependency gaps
- **Coverage Model**: Individual instruction coverage, sequence coverage, dependency coverage, and gap coverage
- **Checking Strategy**: List of architectural state checks (not implemented in this lab scope)

### Part 2: Instruction Generator ✅ COMPLETED
**Files:** `mips_instruction_generator.sv`, `simple_instr_test.sv`, test infrastructure

#### Key Features:
- **`instruction` class**: Extends `uvm_transaction` with full MIPS instruction support
- **Constrained randomization**: Valid instructions for ADD, AND, LW, SW, BEQ
- **Register constraints**: Limited to $1, $2, $3, $4 (4 registers)
- **Memory constraints**: 4 addresses (0x40, 0x44, 0x48, 0x4C)
- **Dependency generation**: Register and memory dependencies with 1-4 instruction gaps
- **Machine code conversion**: Built-in assembler function
- **Memory file output**: Generated programs written to `.dat` files

#### Constraint Examples:
```systemverilog
// R-type constraints (ADD, AND)
constraint r_type_c {
    if (instr_type == ADD || instr_type == AND) {
        rd inside {1, 2, 3, 4};
        rs inside {1, 2, 3, 4};
        rt inside {1, 2, 3, 4};
    }
}

// Dependency constraints
constraint dependency_c {
    if (create_reg_dependency) {
        seq[i].rd == seq[i+gap].rs || seq[i].rd == seq[i+gap].rt;
    }
}
```

### Part 3: UVM Monitor ✅ COMPLETED
**File:** `mips_monitor.sv`

#### Key Features:
- **Interface monitoring**: Observes PC, instruction, and data memory signals
- **Instruction decoding**: Converts machine code back to instruction transactions
- **Analysis port**: Sends decoded transactions to coverage collector
- **Edge detection**: Identifies new instruction fetches
- **Error handling**: Graceful handling of unknown instructions

#### Monitored Signals:
- `pc` - Program counter for instruction addresses
- `instr` - Current instruction machine code
- `dataadr`, `writedata`, `memwrite` - Data memory interface
- `clk`, `reset` - Clock and reset

### Part 3: Coverage Collector ✅ COMPLETED
**File:** `mips_coverage_collector.sv`

#### Coverage Groups:
1. **Individual Instruction Coverage** (`instr_fields_cg`)
   - Instruction types (ADD, AND, LW, SW, BEQ)
   - Register usage (rs, rt, rd)
   - Memory addresses
   - Branch taken/not taken

2. **Instruction Sequence Coverage** (`instr_sequence_cg`)
   - All 25 instruction pair combinations
   - Cross coverage of instruction types

3. **Dependency Coverage** (`dependency_cg`)
   - Register write-read dependencies
   - Memory store-load dependencies
   - Dependency gaps (1, 2, 3, 4 instructions)

4. **Gap Coverage** (`gap_cg`)
   - Instruction spacing analysis

#### Sample Coverpoints:
```systemverilog
instr_type_cp: coverpoint current_instr.instr_type {
    bins add_bin = {INSTR_ADD};
    bins and_bin = {INSTR_AND};
    bins lw_bin = {INSTR_LW};
    bins sw_bin = {INSTR_SW};
    bins beq_bin = {INSTR_BEQ};
}

dep_gap_cross: cross dependency_type_cp, dependency_gap_cp;
```

### Part 3: UVM Environment ✅ COMPLETED
**File:** `mips_uvm_env.sv`

#### Components:
- **`mips_env`**: Main environment class connecting monitor and coverage collector
- **`mips_test`**: UVM test class with instruction generation integration
- **`mips_uvm_tb`**: Top-level testbench module with DUT connections
- **Interface definition**: `mips_if` for clean signal organization

#### UVM Hierarchy:
```
mips_test
└── mips_env
    ├── mips_monitor
    └── mips_coverage_collector
```

### Integration and Testing ✅ COMPLETED
**Files:** `Makefile`, test infrastructure

#### Build and Run Commands:
```bash
# Compile
make compile

# Run single simulation
make sim

# Run multiple seeds for coverage
make sim_multi

# Generate coverage report
make cov_report

# View in Verdi
make verdi_cov
```

## File Structure
```
lab_5/
├── Lab5_Verification_Plan.md          # Part 1: Verification plan
├── mips_instruction_generator.sv      # Part 2: Instruction generator
├── mips_monitor.sv                    # Part 3: UVM monitor
├── mips_coverage_collector.sv         # Part 3: Coverage collector
├── mips_uvm_env.sv                    # Part 3: Environment & test
├── simple_instr_test.sv              # Simple test without UVM
├── Makefile                           # Complete build system
├── Makefile_part2                     # Part 2 specific build
├── Makefile_simple                    # Simple test build
└── README.md                          # This summary
```

## Key Achievements

### Functional Coverage Model
- **4 Coverage Groups** with comprehensive coverage points
- **Cross Coverage** between instruction types, registers, dependencies
- **Dependency Tracking** for register and memory hazards
- **Gap Analysis** for instruction spacing

### Constrained Random Stimulus
- **Valid MIPS Instructions** generated with proper constraints
- **Dependency Creation** between instruction pairs
- **Randomized Gaps** between dependent instructions
- **Machine Code Generation** for direct memory loading

### UVM Testbench Architecture
- **Standard UVM Hierarchy** with env, monitor, and subscriber
- **Analysis Port Connections** for transaction flow
- **Phase Management** for proper component lifecycle
- **Configuration Database** for interface sharing

## Usage Instructions

### Running the Complete Verification:
1. **Compile**: `make compile`
2. **Run Test**: `make sim`
3. **View Coverage**: `make verdi_cov`
4. **Multiple Seeds**: `make sim_multi`

### For Part 2 Only (Instruction Generator):
1. **Simple Test**: `make -f Makefile_simple simple_test`
2. **UVM Test**: `make -f Makefile_part2 sim`

### Coverage Achievement:
- Run multiple simulations with different seeds
- Use `make sim_multi` for parallel execution
- Merge coverage databases with `make merge_cov`
- Iterate until 100% functional coverage achieved

## Lab Deliverables Completed

### Part 1 (20 points): ✅
- Comprehensive verification plan with architecture diagram
- Stimulus, coverage, and checking strategies documented

### Part 2 (40 points): ✅
- Working instruction generator with constraints
- Testbench integration with MIPS processor
- Waveform verification capability

### Part 3 (40 points): ✅
- UVM monitor observing instruction fetch
- Functional coverage collector with detailed covergroups
- Complete UVM environment with connections
- Coverage reports and analysis

## Technical Highlights

1. **Constraint Sophistication**: Complex constraints ensuring valid MIPS instructions while creating meaningful dependencies

2. **Coverage Completeness**: Comprehensive coverage model covering individual instructions, sequences, dependencies, and timing

3. **UVM Best Practices**: Proper use of UVM methodology with standard components and phase management

4. **Integration Quality**: Seamless integration between SystemVerilog constraints and UVM verification components

5. **Scalability**: Architecture designed to easily extend to more instructions, registers, or coverage points

This implementation provides a solid foundation for MIPS processor verification and demonstrates advanced verification methodologies used in industry.