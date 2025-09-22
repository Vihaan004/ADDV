# Makefile for MIPS Verification (Lab 5)
# Based on serialalu_uvm/Makefile

# Test and verbosity settings
UVM_VERBOSITY = UVM_MEDIUM
TEST = mips_test

# VCS compilation command with UVM support
VCS = $(VCS_HOME)/bin/vcs -full64 -sverilog -timescale=1ns/1ns \
	-ntb_opts uvm -debug_access+all -kdb -lca \
	-cm line+cond+fsm+branch+tgl -l comp.log

# Simulation command
SIMV = ./simv +UVM_VERBOSITY=$(UVM_VERBOSITY) \
	+UVM_TESTNAME=$(TEST) +UVM_TR_RECORD +UVM_LOG_RECORD \
	+verbose=1 +ntb_random_seed=244 -l vcs.log -cm line+cond+fsm+branch+tgl

# Default target - matches serialalu pattern
x: comp run

# Compilation target
comp:
	$(VCS) +incdir+. mips_tb_top.sv

# Simulation target  
run:
	$(SIMV)

# Alternative: compile and run in one step
compile_and_run: comp run

# Coverage viewing (if Verdi is available)
cov:
	$(VERDI_HOME)/bin/verdi -cov -covdir simv.vdb

# GUI simulation with Verdi
gui:
	$(SIMV) -gui=verdi

# Clean up generated files
clean:
	rm -rf *.vdb csrc DVEfiles *.vpd *.fsdb simv simv.daidir ucli.key vc_hdrs.h vcs.log comp.log instructions.hex mips_verification.vcd

# Help target
help:
	@echo "Available targets:"
	@echo "  x             - Compile and run (default, matches serialalu)"
	@echo "  comp          - Compile only"
	@echo "  run           - Run simulation only"
	@echo "  compile_and_run - Compile and run in sequence"
	@echo "  gui           - Run with Verdi GUI"
	@echo "  cov           - View coverage"
	@echo "  clean         - Remove generated files"
	@echo "  help          - Show this help"

.PHONY: x comp run compile_and_run gui cov clean help