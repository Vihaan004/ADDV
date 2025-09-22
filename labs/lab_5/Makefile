# Simple Makefile for Lab 5 Template-Based Solution
# Easy to understand and demo

# Test selection
TEST_MODULE = lab5_simple_demo
UVM_VERBOSITY = UVM_MEDIUM

# VCS compilation flags (simplified)
VCS_FLAGS = -full64 -sverilog -timescale=1ns/1ns \
	-ntb_opts uvm -debug_access+all \
	-l compile.log

# Simulation flags  
SIM_FLAGS = +UVM_VERBOSITY=$(UVM_VERBOSITY) \
	+ntb_random_seed=123 \
	-l simulate.log

# Default target - simple demo
demo: compile_simple run_simple

# Compile the simple template solution
compile_simple:
	@echo "=== Compiling Lab 5 Simple Template Solution ==="
	vcs $(VCS_FLAGS) $(TEST_MODULE).sv

# Compile just the instruction generator
compile_gen:
	@echo "=== Compiling Instruction Generator ==="
	vcs $(VCS_FLAGS) instr_gen.sv
	@if [ -f simv ]; then \
		echo "=== Compilation successful ==="; \
	else \
		echo "=== Compilation failed, check compile.log ==="; \
		cat compile.log; \
	fi

# Run the simple demo
run_simple:
	@echo "=== Running Lab 5 Simple Demo ==="
	./simv $(SIM_FLAGS)

# Alternative: instruction generator only
gen_only:
	@echo "=== Running Instruction Generator Only ==="
	vcs $(VCS_FLAGS) instr_gen.sv
	@if [ -f simv ]; then \
		echo "=== Compilation successful, running simulation ==="; \
		./simv $(SIM_FLAGS); \
	else \
		echo "=== Compilation failed, check compile.log ==="; \
		cat compile.log; \
		exit 1; \
	fi

# Alternative: UVM version
uvm_demo:
	@echo "=== Running UVM-based Demo ==="
	vcs $(VCS_FLAGS) lab5_simple_demo.sv -top lab5_uvm_demo
	./simv $(SIM_FLAGS) +UVM_TESTNAME=simple_test

# Coverage analysis (if available)
coverage:
	@echo "=== Coverage Analysis ==="
	@if [ -d simv.vdb ]; then \
		echo "Coverage database found"; \
		urg -dir simv.vdb -report coverage_report; \
	else \
		echo "No coverage database found - rerun with coverage flags"; \
	fi

# Clean up
clean:
	@echo "=== Cleaning Up ==="
	rm -rf simv* csrc DVEfiles *.log *.vpd *.fsdb *.vdb
	rm -rf urgReport coverage_report instructions.hex
	rm -rf ucli.key vc_hdrs.h .vlogansetup.env .vcs.timestamp

# Help
help:
	@echo "Lab 5 Simple Template Solution - Available targets:"
	@echo "  demo          - Compile and run simple template demo (default)"
	@echo "  compile_simple- Compile only"
	@echo "  run_simple    - Run simulation only"
	@echo "  gen_only      - Run instruction generator only"
	@echo "  uvm_demo      - Run UVM-based version"
	@echo "  coverage      - Generate coverage report"
	@echo "  clean         - Remove generated files"
	@echo "  help          - Show this help"
	@echo ""
	@echo "Key files:"
	@echo "  instr_gen_simple.sv        - Instruction generator template"
	@echo "  coverage_collector_simple.sv - Coverage collector template"
	@echo "  lab5_simple_demo.sv        - Combined demo testbench"

# Show generated instructions
show_instructions:
	@echo "=== Generated Instructions ==="
	@if [ -f instructions.hex ]; then \
		echo "Machine codes from instructions.hex:"; \
		cat instructions.hex; \
	else \
		echo "No instructions.hex found - run demo first"; \
	fi

.PHONY: demo compile_simple run_simple gen_only uvm_demo coverage clean help show_instructions