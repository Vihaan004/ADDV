# Makefile for FIFO DPI Verification
# Lab 4 - Part 2
# Based on Lab 0 Makefile template

# File lists
SV_FILES = async_fifo_top.sv fifomem_module.sv sync_modules.sv rptr_empty_module.sv wptr_full_module.sv fifo_dpi_testbench.sv
C_FILES = dpi.c

# Default target
.PHONY: all clean run_normal run_with_bug compile

all: compile

# Compile the design and testbench with DPI for simulation only
compile:
	${VCS_HOME}/bin/vcs -full64 -sverilog $(SV_FILES) $(C_FILES) -debug_access+all |& tee compile.log

# Compile the design and testbench with DPI and generate database for Verdi
compile_verdi:
	${VCS_HOME}/bin/vcs -full64 -sverilog $(SV_FILES) $(C_FILES) -debug_access+all -kdb -lca |& tee compile_verdi.log

# Run simulation (normal operation)
sim:
	./simv

# Compile and run normal simulation (no bugs)
compile_and_sim_normal:
	${VCS_HOME}/bin/vcs -R -full64 -sverilog $(SV_FILES) $(C_FILES) -debug_access+all |& tee compile_and_sim_normal.log

# Compile and run with bug injection (drops every 3rd write)
compile_and_sim_bug:
	${VCS_HOME}/bin/vcs -R -full64 -sverilog $(SV_FILES) $(C_FILES) -debug_access+all +inject_bug +drop_every=3 |& tee compile_and_sim_bug.log

# Compile and run with bug injection (drops every 5th write)  
compile_and_sim_bug5:
	${VCS_HOME}/bin/vcs -R -full64 -sverilog $(SV_FILES) $(C_FILES) -debug_access+all +inject_bug +drop_every=5 |& tee compile_and_sim_bug5.log

# Run normal simulation after compiling with Verdi support (generates FSDB)
run_normal_verdi: compile_verdi
	./simv |& tee run_normal_verdi.log

# Run bug injection simulation after compiling with Verdi support (generates FSDB)
run_bug_verdi: compile_verdi
	./simv +inject_bug +drop_every=3 |& tee run_bug_verdi.log

# Compile with Verdi support and run normal simulation in one step
verdi_normal: compile_verdi run_normal_verdi

# Compile with Verdi support and run bug injection in one step  
verdi_bug: compile_verdi run_bug_verdi

# Launch Verdi for waveform viewing
waves_verdi:
	$(VERDI_HOME)/bin/verdi -dbdir ./simv.daidir -ssf novas.fsdb -nologo

# Clean generated files (following Lab 0 style)
clean:
	\rm -rf *.log *.h csrc DVEFiles simv.daidir simv ucli.key vcdplus.vpd *.syn *.pvl *.mr *.svf command.log *.txt novas.conf novas.rc verdi_config_file verdiLog novas.fsdb novas.log novas_dump.log

# Simple FIFO test targets
SIMPLE_SV_FILES = async_fifo_top.sv fifomem_module.sv sync_modules.sv rptr_empty_module.sv wptr_full_module.sv simple_fifo_test.sv
MINIMAL_SV_FILES = async_fifo_top.sv fifomem_module.sv sync_modules.sv rptr_empty_module.sv wptr_full_module.sv minimal_fifo_test.sv

# Compile and run simple FIFO test
simple_test: 
	${VCS_HOME}/bin/vcs -R -full64 -sverilog $(SIMPLE_SV_FILES) $(C_FILES) -debug_access+all |& tee simple_test.log

# Compile simple test with Verdi support
simple_verdi:
	${VCS_HOME}/bin/vcs -full64 -sverilog $(SIMPLE_SV_FILES) $(C_FILES) -debug_access+all -kdb -lca |& tee simple_verdi.log
	./simv |& tee simple_run.log

# Minimal FIFO test - just basic functionality for waveform viewing
minimal_test:
	${VCS_HOME}/bin/vcs -R -full64 -sverilog $(MINIMAL_SV_FILES) -debug_access+all |& tee minimal_test.log

# Minimal test with Verdi support for waveforms
minimal_verdi:
	${VCS_HOME}/bin/vcs -full64 -sverilog $(MINIMAL_SV_FILES) -debug_access+all -kdb -lca |& tee minimal_verdi.log
	./simv |& tee minimal_run.log

# Help
help:
	@echo "Available targets (following Lab 0 Makefile style):"
	@echo "  compile                - Compile design and testbench"
	@echo "  compile_verdi          - Compile with Verdi database generation"
	@echo "  sim                    - Run simulation (after compile)"
	@echo "  compile_and_sim_normal - Compile and run normal simulation (no bugs)"
	@echo "  compile_and_sim_bug    - Compile and run with bug injection (every 3rd)"
	@echo "  compile_and_sim_bug5   - Compile and run with bug injection (every 5th)"
	@echo "  run_normal_verdi       - Run normal after compile_verdi"
	@echo "  run_bug_verdi          - Run with bugs after compile_verdi"
	@echo "  simple_test            - Simple FIFO functionality test"
	@echo "  simple_verdi           - Simple test with Verdi waveforms"
	@echo "  minimal_test           - Minimal FIFO test (basic write/read)"
	@echo "  minimal_verdi          - Minimal test with Verdi waveforms"
	@echo "  waves_verdi            - Launch Verdi for waveform viewing"
	@echo "  clean                  - Remove generated files"
	@echo "  help                   - Show this help message"
