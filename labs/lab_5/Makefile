# Simple Makefile for Lab 5 Template-Based Solution
# Easy to understand and demo

# VCS compilation flags (simplified)
VCS_FLAGS = -full64 -sverilog -timescale=1ns/1ns -ntb_opts uvm

# Simulation flags  
SIM_FLAGS = +UVM_VERBOSITY=UVM_MEDIUM +ntb_random_seed=123

# Instruction generator only (simple)
gen_only:
	vcs $(VCS_FLAGS) instr_gen.sv
	./simv $(SIM_FLAGS)

# Compile only
compile_gen:
	vcs $(VCS_FLAGS) instr_gen.sv

# Run only (if already compiled)
run_gen:
	./simv $(SIM_FLAGS)

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