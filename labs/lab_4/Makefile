# Makefile for FIFO DPI Verification
# Lab 4 - Part 2

# Simulator settings
VCS = vcs
VCS_FLAGS = -sverilog -debug_access+all -kdb -lca -timescale=1ns/1ns

# File lists
SV_FILES = async_fifo_top.sv fifomem_module.sv sync_modules.sv rptr_empty_module.sv wptr_full_module.sv fifo_dpi_testbench.sv
C_FILES = dpi.c

# Simulation executable
SIM_EXE = fifo_dpi_sim

# Default target - run without bugs
.PHONY: all clean run_normal run_with_bug

all: run_normal

# Compile and run normal simulation (no bugs)
run_normal: $(SIM_EXE)
	@echo "=== Running FIFO DPI Verification (Normal) ==="
	./$(SIM_EXE) +no_bug

# Compile and run with bug injection
run_with_bug: $(SIM_EXE)
	@echo "=== Running FIFO DPI Verification (With Bug) ==="
	./$(SIM_EXE) +inject_bug +bug_drop_every=3

# Compile the simulation
$(SIM_EXE): $(SV_FILES) $(C_FILES)
	@echo "=== Compiling FIFO DPI Testbench ==="
	$(VCS) $(VCS_FLAGS) $(SV_FILES) $(C_FILES) -o $(SIM_EXE)

# Run with waveform dump
run_waves: $(SIM_EXE)
	@echo "=== Running with Waveform Dump ==="
	./$(SIM_EXE) +no_bug +vcd

# Clean generated files
clean:
	rm -rf $(SIM_EXE) simv* csrc *.daidir *.log *.vcd *.fsdb *.vpd DVEfiles
	rm -rf ucli.key vc_hdrs.h .vlogansetup.env .vlogansetup.args

# Help
help:
	@echo "Available targets:"
	@echo "  run_normal    - Run simulation without bugs"
	@echo "  run_with_bug  - Run simulation with bug injection"
	@echo "  run_waves     - Run with waveform generation"
	@echo "  clean         - Remove generated files"
	@echo "  help          - Show this help message"
