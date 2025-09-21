#==============================================================================
# Lab 5: Complete MIPS UVM Verification Makefile
#==============================================================================

# Tools
VCS = vcs
VERDI = verdi
URG = urg

# Directories
LAB2_DIR = ../lab_2
LAB5_DIR = .

# Source files
MIPS_RTL = $(LAB2_DIR)/top.v $(LAB2_DIR)/controller.v $(LAB2_DIR)/datapath.v
UVM_SRC = mips_instruction_generator.sv mips_monitor.sv mips_coverage_collector.sv mips_uvm_env.sv

# VCS compilation flags
VCS_FLAGS = -sverilog -ntb_opts uvm -debug_access+all -kdb -lca
VCS_FLAGS += +incdir+$(VCS_HOME)/etc/uvm-1.2/src
VCS_FLAGS += $(VCS_HOME)/etc/uvm-1.2/src/dpi/uvm_dpi.cc

# Coverage flags
COV_FLAGS = -cm line+cond+fsm+tgl+branch
COV_FLAGS += -cm_name simv_cov -cm_dir coverage.vdb

# Simulation flags  
SIM_FLAGS = +UVM_TESTNAME=mips_test +UVM_VERBOSITY=UVM_LOW
SIM_FLAGS += -cm line+cond+fsm+tgl+branch -cm_name run1 -cm_dir coverage.vdb

# Build executable name
SIMV = simv_mips_uvm

#==============================================================================
# Default target
#==============================================================================
all: compile

#==============================================================================
# Compilation targets
#==============================================================================
compile: $(SIMV)

$(SIMV): $(MIPS_RTL) $(UVM_SRC)
	@echo "=== Compiling MIPS UVM Testbench ==="
	$(VCS) $(VCS_FLAGS) $(COV_FLAGS) $(MIPS_RTL) $(UVM_SRC) -o $(SIMV)
	@echo "=== Compilation completed ==="

compile_no_cov:
	@echo "=== Compiling without coverage ==="
	$(VCS) $(VCS_FLAGS) $(MIPS_RTL) $(UVM_SRC) -o $(SIMV)

#==============================================================================
# Simulation targets  
#==============================================================================
sim: $(SIMV)
	@echo "=== Running MIPS UVM Simulation ==="
	./$(SIMV) $(SIM_FLAGS)

# Run with specific seed
sim_seed_%: $(SIMV)
	@echo "=== Running simulation with seed $* ==="
	./$(SIMV) $(SIM_FLAGS) +ntb_random_seed=$* -cm_name run_$*

# Run multiple seeds for coverage
sim_multi: $(SIMV)
	@echo "=== Running multiple simulations for coverage ==="
	./$(SIMV) $(SIM_FLAGS) +ntb_random_seed=1 -cm_name run1 &
	./$(SIMV) $(SIM_FLAGS) +ntb_random_seed=2 -cm_name run2 &
	./$(SIMV) $(SIM_FLAGS) +ntb_random_seed=3 -cm_name run3 &
	./$(SIMV) $(SIM_FLAGS) +ntb_random_seed=4 -cm_name run4 &
	./$(SIMV) $(SIM_FLAGS) +ntb_random_seed=5 -cm_name run5 &
	wait
	@echo "=== All simulations completed ==="

# Run with GUI debug
debug: $(SIMV)
	@echo "=== Running with VCS GUI ==="
	./$(SIMV) $(SIM_FLAGS) -gui &

#==============================================================================
# Coverage targets
#==============================================================================
# Merge coverage from multiple runs
merge_cov:
	@echo "=== Merging coverage databases ==="
	$(URG) -dir coverage.vdb/*.vdb -dbname merged_coverage.vdb

# Generate coverage report
cov_report:
	@echo "=== Generating coverage report ==="
	$(URG) -dir coverage.vdb -report both -format both

# View coverage in Verdi
verdi_cov: 
	@echo "=== Opening Verdi with coverage ==="
	$(VERDI) -cov -covdir coverage.vdb &

#==============================================================================
# Waveform targets
#==============================================================================
# View waveforms
verdi:
	@echo "=== Opening Verdi for waveform viewing ==="
	$(VERDI) -ssf mips_uvm.fsdb &

# Interactive debug
verdi_debug: $(SIMV)
	@echo "=== Running interactive debug session ==="
	$(VERDI) -simBin $(SIMV) $(SIM_FLAGS) &

#==============================================================================
# Utility targets
#==============================================================================
# Check syntax only
syntax_check:
	@echo "=== Checking syntax ==="
	$(VCS) -sverilog $(MIPS_RTL) $(UVM_SRC) -fsyn -q

# Create necessary directories
setup:
	@echo "=== Setting up directories ==="
	mkdir -p coverage logs waveforms

# Generate instruction sequence only
gen_instr:
	@echo "=== Testing instruction generator ==="
	$(VCS) -sverilog simple_instr_test.sv -o simv_gen
	./simv_gen

#==============================================================================
# Lab deliverable targets
#==============================================================================
# Run for Part 3 deliverables
part3: compile
	@echo "=== Running Part 3 verification ==="
	./$(SIMV) $(SIM_FLAGS) +ntb_random_seed=12345 -cm_name part3_run
	$(URG) -dir coverage.vdb -report both

# Package deliverables
package:
	@echo "=== Packaging Lab 5 deliverables ==="
	mkdir -p lab5_deliverables
	cp *.sv lab5_deliverables/
	cp *.md lab5_deliverables/
	cp Makefile* lab5_deliverables/
	cp *.dat lab5_deliverables/ 2>/dev/null || true
	tar -czf lab5_submission.tar.gz lab5_deliverables/
	@echo "=== Deliverables packaged in lab5_submission.tar.gz ==="

#==============================================================================
# Clean targets
#==============================================================================
clean:
	@echo "=== Cleaning up generated files ==="
	rm -rf $(SIMV)* simv* csrc *.daidir
	rm -rf *.fsdb *.vpd *.vdb DVE* *.key *.log
	rm -rf urgReport transcript vdCovLog
	rm -rf coverage.vdb *.dat

clean_all: clean
	rm -rf lab5_deliverables lab5_submission.tar.gz
	rm -rf logs waveforms

#==============================================================================
# Help target
#==============================================================================
help:
	@echo "Available targets:"
	@echo ""
	@echo "Compilation:"
	@echo "  compile      - Compile with coverage enabled"
	@echo "  compile_no_cov - Compile without coverage"
	@echo "  syntax_check - Check syntax only"
	@echo ""
	@echo "Simulation:"
	@echo "  sim          - Run single simulation"
	@echo "  sim_seed_N   - Run with specific seed N"
	@echo "  sim_multi    - Run multiple seeds in parallel"
	@echo "  debug        - Run with VCS GUI"
	@echo ""
	@echo "Coverage:"
	@echo "  merge_cov    - Merge coverage from multiple runs"
	@echo "  cov_report   - Generate coverage report"
	@echo "  verdi_cov    - View coverage in Verdi"
	@echo ""
	@echo "Waveforms:"
	@echo "  verdi        - View waveforms in Verdi"
	@echo "  verdi_debug  - Interactive debug with Verdi"
	@echo ""
	@echo "Utilities:"
	@echo "  setup        - Create required directories"
	@echo "  gen_instr    - Test instruction generator only"
	@echo "  part3        - Run Part 3 verification"
	@echo "  package      - Package deliverables"
	@echo ""
	@echo "Cleanup:"
	@echo "  clean        - Remove generated files"
	@echo "  clean_all    - Remove all generated content"
	@echo "  help         - Show this help"

#==============================================================================
# Phony targets
#==============================================================================
.PHONY: all compile compile_no_cov sim debug verdi verdi_cov verdi_debug
.PHONY: merge_cov cov_report syntax_check setup gen_instr part3 package
.PHONY: clean clean_all help sim_multi