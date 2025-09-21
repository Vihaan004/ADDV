# MIPS Instruction Generator - Testing Instructions

## Setup (On Remote Linux Server)

1. **Copy files to remote server**:
   ```bash
   scp instr_gen.sv Makefile env.cshrc username@your-server:~/lab5/
   ```

2. **Setup environment**:
   ```bash
   # Switch to tcsh shell (required for env.cshrc)
   tcsh
   
   # Source environment variables
   source env.cshrc
   ```

## Testing Commands

### Method 1: Using Makefile (Recommended)

```bash
# Compile and run (default target)
make

# Or step by step:
make comp    # Compile only
make run     # Run simulation only

# Clean up generated files
make clean

# View help
make help
```

### Method 2: Manual Commands

```bash
# Compile with VCS
$VCS_HOME/bin/vcs -full64 -sverilog -timescale=1ns/1ns -ntb_opts uvm +incdir+. instr_gen.sv

# Run simulation
./simv +UVM_VERBOSITY=UVM_MEDIUM +UVM_TESTNAME=testbench
```

## Expected Output

The test should generate:

1. **Console output** showing:
   - 16 total instructions generated
   - Breakdown by type (RANDOM/DEPEND/GAP)
   - Assembly code for each instruction

2. **Generated file**: `instructions.hex`
   - Contains 16 lines of 32-bit hex machine codes
   - Can be loaded into MIPS processor instruction memory

## Example Output
```
=== MIPS Instruction Generator Test ===
=== Generated Instruction Sequence ===
Total instructions: 16
Breakdown:
  - Individual random: 10 instructions
  - Dependent pairs: 4 instructions (2 pairs)
  - Gap instructions: 2 instructions
=====================================
Instruction  1: [RANDOM] ADD $3, $2, $4
Instruction  2: [RANDOM] LW $1, 0x40($2)
...
Generated 16 machine codes written to instructions.hex
```

## Troubleshooting

- **License issues**: Check `LM_LICENSE_FILE` in env.cshrc
- **UVM not found**: Verify `UVM_HOME` path in environment
- **Compilation errors**: Check SystemVerilog syntax in instr_gen.sv
- **Shell issues**: Make sure you're using tcsh shell, not bash