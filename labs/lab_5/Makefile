FILES=./instr_gen.sv ./top.sv ./datapath.sv ./controller.sv

all: compile_and_sim

# Compile and run with VCS
compile_and_sim:
	${VCS_HOME}/bin/vcs -R -full64 -sverilog ${FILES} -debug_access+all -ntb_opts uvm -timescale=1ns/1ps |& tee compile_and_sim.log

# Compile only
compile:
	${VCS_HOME}/bin/vcs -full64 -sverilog ${FILES} -debug_access+all -ntb_opts uvm -timescale=1ns/1ps |& tee compile.log

# Compile with Verdi DB (no run)
compile_verdi:
	${VCS_HOME}/bin/vcs -full64 -sverilog ${FILES} -debug_access+all -kdb -lca -ntb_opts uvm -timescale=1ns/1ps |& tee compile_verdi.log

# Run simulation (after compile or compile_verdi)
run:
	./simv +ntb_random_seed=automatic +UVM_VERBOSITY=UVM_MEDIUM -l simv.log

# Run simulation if already compiled
sim:
	./simv +ntb_random_seed=automatic +UVM_VERBOSITY=UVM_MEDIUM -l simv.log

# Launch Verdi if available
waves_verdi:
	$(VERDI_HOME)/bin/verdi -dbdir ./simv.daidir -ssf novas.fsdb -nologo

clean:
	\rm -rf *.log *.h csrc DVEFiles simv.daidir simv ucli.key vcdplus.vpd *.syn *.pvl *.mr *.svf command.log *.txt novas.conf novas.rc verdi_config_file verdiLog novas.fsdb novas.log novas_dump.log instruction_file.memh
