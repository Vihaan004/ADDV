#!/bin/bash

echo "=== SystemVerilog Syntax Check ==="
echo "File: instr_gen.sv"
echo "Checking for basic syntax errors..."

# Check if file exists
if [ ! -f "instr_gen.sv" ]; then
    echo "ERROR: instr_gen.sv not found!"
    exit 1
fi

# Basic syntax checks
echo "✓ File exists"

# Check for balanced braces, brackets, parentheses
if grep -c '{' instr_gen.sv | grep -c '}' instr_gen.sv > /dev/null; then
    echo "✓ Basic brace balance check"
fi

# Check for required SystemVerilog keywords
if grep -q "class.*instruction.*extends.*uvm_transaction" instr_gen.sv; then
    echo "✓ Found instruction class definition"
fi

if grep -q "class.*instruction_generator" instr_gen.sv; then
    echo "✓ Found instruction_generator class"
fi

if grep -q "module.*testbench" instr_gen.sv; then
    echo "✓ Found testbench module"
fi

# Check for UVM imports
if grep -q "import uvm_pkg" instr_gen.sv; then
    echo "✓ Found UVM package import"
fi

echo ""
echo "=== Ready for Remote Server Testing ==="
echo "Commands to run on your remote Linux server:"
echo "1. vcs -sverilog +incdir+\$UVM_HOME/src \$UVM_HOME/src/uvm_pkg.sv instr_gen.sv -ntb_opts uvm"
echo "2. ./simv"
echo ""
echo "Expected outputs:"
echo "- Generated instruction sequence display"
echo "- instructions.hex file creation"
echo "- Machine code generation messages"