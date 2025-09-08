# Makefile for FIFO DPI Verification
# Lab 4 - Part 2
# Based on Lab 0 Makefile template

# File lists
C_FILES = dpi.c
DPI_TB_FILES = async_fifo_top.sv fifomem_module.sv sync_modules.sv rptr_empty_module.sv wptr_full_module.sv fifo_dpi_tb.sv

# New DPI testbench - Normal mode
dpi_tb_normal:
	${VCS_HOME}/bin/vcs -R -full64 -sverilog $(DPI_TB_FILES) $(C_FILES) -debug_access+all |& tee dpi_tb_normal.log

# New DPI testbench - With bug injection
dpi_tb_bug:
	${VCS_HOME}/bin/vcs -R -full64 -sverilog $(DPI_TB_FILES) $(C_FILES) -debug_access+all +inject_bug +drop_every=3 |& tee dpi_tb_bug.log

# New DPI testbench - Normal mode with Verdi
dpi_tb_normal_verdi:
	${VCS_HOME}/bin/vcs -full64 -sverilog $(DPI_TB_FILES) $(C_FILES) -debug_access+all -kdb -lca |& tee dpi_tb_normal_verdi.log
	./simv |& tee dpi_tb_normal_run.log

# New DPI testbench - Bug injection with Verdi
dpi_tb_bug_verdi:
	${VCS_HOME}/bin/vcs -full64 -sverilog $(DPI_TB_FILES) $(C_FILES) -debug_access+all -kdb -lca |& tee dpi_tb_bug_verdi.log
	./simv +inject_bug +drop_every=3 |& tee dpi_tb_bug_run.log

# Launch Verdi for waveform viewing
waves_verdi:
	$(VERDI_HOME)/bin/verdi -dbdir ./simv.daidir -ssf novas.fsdb -nologo

# Clean generated files (following Lab 0 style)
clean:
	\rm -rf *.log *.h csrc DVEFiles simv.daidir simv ucli.key vcdplus.vpd *.syn *.pvl *.mr *.svf command.log *.txt novas.conf novas.rc verdi_config_file verdiLog novas.fsdb novas.log novas_dump.log

