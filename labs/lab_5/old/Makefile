# Simple Makefile for Lab 5 Template-Based Solution
# Based on working uvm_solution/Makefile

# VCS compilation flags (from working solution)
VCS = $(VCS_HOME)/bin/vcs -full64 -sverilog -timescale=1ns/1ns \
	-ntb_opts uvm -debug_access+all -kdb -lca

# Simulation flags  
SIMV = ./simv +UVM_VERBOSITY=UVM_MEDIUM +ntb_random_seed=123

# Instruction generator only (simple)
gen_only:
	$(VCS) instr_gen.sv
	$(SIMV)

# Compile only
compile_gen:
	$(VCS) instr_gen.sv

# Run only (if already compiled)
run_gen:
	$(SIMV)

# Clean up
clean:
	rm -rf simv* csrc DVEfiles *.log *.vpd *.fsdb *.vdb
	rm -rf urgReport coverage_report instructions.hex
	rm -rf ucli.key vc_hdrs.h

# Show generated instructions
show:
	cat instructions.hex

# Help
help:
	@echo "Simple targets:"
	@echo "  gen_only   - Compile and run instruction generator"
	@echo "  compile_gen- Compile only"  
	@echo "  run_gen    - Run only"
	@echo "  clean      - Clean up"
	@echo "  show       - Show generated instructions.hex"
	@echo "  help       - This help"

.PHONY: gen_only compile_gen run_gen clean show help