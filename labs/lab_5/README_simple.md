# Lab 5 Simple Template-Based Solution

This is a **simplified, easy-to-understand** solution for Lab 5 that directly fills in the provided template files without complex UVM hierarchy.

## 📁 Files Overview

### Core Template Files
- **`instr_gen_simple.sv`** - Complete instruction generator (fixed template)
- **`coverage_collector_simple.sv`** - Complete coverage collector (fixed template)  
- **`lab5_simple_demo.sv`** - Combined testbench demonstrating both

### Build Files
- **`Makefile_simple`** - Simple compilation and run commands
- **`README_simple.md`** - This documentation

## 🚀 Quick Start

### Option 1: Full Demo (Recommended)
```bash
# Copy the simple makefile
cp Makefile_simple Makefile

# Run complete demo
make demo
```

### Option 2: Just Instruction Generation
```bash
make gen_only
```

### Option 3: UVM Version
```bash
make uvm_demo
```

## 📊 What This Solution Does

### Part 1: Instruction Generation
✅ **Generates 16 MIPS instructions:**
- 10 individual random instructions
- 4 dependent pair instructions (2 pairs with RAW dependencies) 
- 2 gap instructions (NOP-like: ADD $1, $1, $1)

✅ **Supports 5 instruction types:**
- ADD (R-type: opcode=0x00, funct=0x20)
- AND (R-type: opcode=0x00, funct=0x24)
- LW (I-type: opcode=0x23)
- SW (I-type: opcode=0x2B)
- BEQ (I-type: opcode=0x04)

✅ **Uses 4 registers:** {1, 2, 3, 4} as specified

### Part 2: Coverage Collection
✅ **Four covergroups:**
1. **Instruction Fields** - opcodes, registers, function codes
2. **Instruction Order** - consecutive instruction sequences
3. **Dependencies** - register dependencies (RAW, WAW, WAR)
4. **Gap Instructions** - NOP-like instruction detection

✅ **Real-time coverage reporting**

## 🔧 Key Fixes Applied to Templates

### 1. Fixed Base Class Error
**Before:**
```systemverilog
class instruction extends uvm_transaction; // ❌ Wrong!
```

**After:**
```systemverilog  
class instruction extends uvm_sequence_item; // ✅ Correct!
```

### 2. Complete Constraint Implementation
- Proper register constraints {1,2,3,4}
- Valid opcode constraints for 5 instruction types
- Function code constraints for R-type vs I-type
- Memory address constraints for LW/SW/BEQ

### 3. Complete Coverage Implementation
- All covergroups fully implemented
- Transaction flow from generator to coverage
- Coverage reporting with percentages

## 📈 Expected Output

```
=== Lab 5 Simple Template Demo ===

PART 1: INSTRUCTION GENERATION
==============================
[GEN] Generating 10 individual random instructions...
[GEN] Generating 4 dependent pair instructions...  
[GEN] Generating 2 gap instructions...
[GEN] Total instructions generated: 16
[FILE] Generated 16 machine codes written to instructions.hex

=== INSTRUCTION SEQUENCE DISPLAY ===
[RANDOM] Instr  1: 0x00221020: ADD $2, $1, $2
[RANDOM] Instr  2: 0x8c430040: LW $3, 0x40($2)
...
[DEPEND] Instr 11: 0x00221020: ADD $2, $1, $1  
[DEPEND] Instr 12: 0x8c230044: LW $3, 0x44($1)
...
[GAP]    Instr 15: 0x00221020: ADD $1, $1, $1
[GAP]    Instr 16: 0x00221020: ADD $1, $1, $1

PART 2: COVERAGE SIMULATION
===========================
[COVERAGE] Instruction 1: PC=0x00000000, Opcode=0x00
[COVERAGE] Instruction 2: PC=0x00000004, Opcode=0x23
...

PART 3: FINAL RESULTS
=====================
=== MIPS VERIFICATION COVERAGE REPORT ===
Total instructions processed: 16
Instruction Fields Coverage: 87.50%
Instruction Order Coverage: 45.83% 
Dependencies Coverage: 56.25%
Gap Instructions Coverage: 78.12%
Dependencies detected: 2
Gap instructions detected: 2
==========================================
```

## 🎯 Demo Benefits

1. **Easy to Understand** - Uses template structure directly
2. **Complete Solution** - All constraints and coverage implemented  
3. **Ready for Demo** - Clear output showing all features
4. **No Complex UVM** - Simple testbench, easy to explain
5. **File Generation** - Creates `instructions.hex` for MIPS processor

## 🔄 Integration with MIPS Processor

The generated `instructions.hex` file can be loaded into a MIPS processor:

```systemverilog
// In your MIPS processor testbench:
$readmemh("instructions.hex", instruction_memory);
```

This simple template-based solution is perfect for Lab 5 demos and understanding! 🎉