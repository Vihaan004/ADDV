# Makefile for FIFO DPI Verification
# Lab 4 - Part 2

# File lists
SV_FILES = async_fifo_top.sv fifomem_module.sv sync_modules.sv rptr_empty_module.sv wptr_full_module.sv fifo_dpi_testbench.sv
C_FILES = dpi.c

# Default target
.PHONY: all clean run_normal run_with_bug compile

all: run_normal

# Compile the design and testbench with DPI
compile:
	${VCS_HOME}/bin/vcs -full64 -sverilog $(SV_FILES) $(C_FILES) -debug_access+all -kdb -lca |& tee compile.log

# Compile and run normal simulation (no bugs)
run_normal: compile
	@echo "=== Running FIFO DPI Verification (Normal) ==="
	./simv +vcd |& tee run_normal.log

# Compile and run with bug injection (drops every 3rd write)
run_with_bug: compile
	@echo "=== Running FIFO DPI Verification (With Bug - Drop Every 3rd) ==="
	./simv +inject_bug +drop_every=3 +vcd |& tee run_with_bug.log

# Compile and run with bug injection (drops every 5th write)
run_with_bug5: compile
	@echo "=== Running FIFO DPI Verification (With Bug - Drop Every 5th) ==="
	./simv +inject_bug +drop_every=5 +vcd |& tee run_with_bug5.log

# Run with waveform dump (for Verdi)
run_waves: compile
	@echo "=== Running with Waveform Dump ==="
	./simv +vcd |& tee run_waves.log

# Launch Verdi for waveform viewing
waves_verdi:
	$(VERDI_HOME)/bin/verdi -dbdir ./simv.daidir -ssf novas.fsdb -nologo

# Clean generated files
clean:
	rm -rf simv* csrc *.daidir *.log *.vcd *.fsdb *.vpd DVEfiles
	rm -rf ucli.key vc_hdrs.h .vlogansetup.env .vlogansetup.args
	rm -rf novas.conf novas.rc verdi_config_file verdiLog novas.log novas_dump.log

# Help
help:
	@echo "Available targets:"
	@echo "  compile       - Compile the design and testbench"
	@echo "  run_normal    - Run simulation without bugs"
	@echo "  run_with_bug  - Run simulation with bug injection (drop every 3rd)"
	@echo "  run_with_bug5 - Run simulation with bug injection (drop every 5th)"
	@echo "  run_waves     - Run with waveform generation"
	@echo "  waves_verdi   - Launch Verdi for waveform viewing"
	@echo "  clean         - Remove generated files"
	@echo "  help          - Show this help message"
