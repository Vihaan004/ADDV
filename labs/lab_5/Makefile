VCS = $(VCS_HOME)/bin/vcs -full64 -sverilog -timescale=1ns/1ns \
	-ntb_opts uvm -debug_access+all -kdb -lca 
SIMV = ./simv +UVM_VERBOSITY=UVM_MEDIUM +ntb_random_seed=123

gen_only:
	$(VCS) instr_gen.sv
	$(SIMV)

# Compile only
compile_gen:
	$(VCS) instr_gen.sv

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
