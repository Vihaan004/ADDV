## Lab 5 Makefile: simple targets for generator and coverage flows

# Generator (stimulus) files
FILES_PART2=./instr_gen.sv ./top.sv ./datapath.sv ./controller.sv

# Coverage (monitor + subscriber) files
FILES_PART3=./instr_mem_if.sv ./coverage_collector.sv ./top.sv ./datapath.sv ./controller.sv

COVDIR ?= simv.vdb

all: compile_and_run

# Compile and run with VCS
###### Generator (no coverage) ######
compile_and_run:
	${VCS_HOME}/bin/vcs -R -full64 -sverilog ${FILES_PART2} -debug_access+all -ntb_opts uvm -timescale=1ns/1ps |& tee compile_and_run.log

# Compile only
compile:
	${VCS_HOME}/bin/vcs -full64 -sverilog ${FILES_PART2} -debug_access+all -ntb_opts uvm -timescale=1ns/1ps |& tee compile.log

compile_verdi:
	${VCS_HOME}/bin/vcs -full64 -sverilog ${FILES_PART2} -debug_access+all -kdb -lca -ntb_opts uvm -timescale=1ns/1ps |& tee compile_verdi.log

run:
	./simv +ntb_random_seed=automatic +UVM_VERBOSITY=UVM_MEDIUM -l simv.log

# Run simulation if already compiled
sim:
	./simv +ntb_random_seed=automatic +UVM_VERBOSITY=UVM_MEDIUM -l simv.log

waves:
	$(VERDI_HOME)/bin/verdi -dbdir ./simv.daidir -ssf novas.fsdb -nologo

###### Coverage (UVM monitor/subscriber) ######
coverage:
	${VCS_HOME}/bin/vcs -R -full64 -sverilog ${FILES_PART3} -cm line+cond+tgl+fsm -cm_dir $(COVDIR) -debug_access+all -ntb_opts uvm -kdb -timescale=1ns/1ps |& tee coverage.log

coverage_compile:
	${VCS_HOME}/bin/vcs -full64 -sverilog ${FILES_PART3} -cm line+cond+tgl+fsm -cm_dir $(COVDIR) -debug_access+all -ntb_opts uvm -kdb -timescale=1ns/1ps |& tee coverage_compile.log

coverage_run:
	./simv +ntb_random_seed=automatic +UVM_VERBOSITY=UVM_MEDIUM +UVM_TESTNAME=my_test -cm line+cond+tgl+fsm -cm_dir $(COVDIR) -l coverage_run.log

merge_cov:
	$(VCS_HOME)/bin/urg -dir *.vdb -dbname merged.vdb

waves_cov:
	$(VERDI_HOME)/bin/verdi -cov -covdir merged.vdb

clean:
	\rm -rf *.log *.h csrc DVEFiles simv.daidir simv ucli.key vcdplus.vpd *.syn *.pvl *.mr *.svf command.log *.txt novas.conf novas.rc verdi_config_file verdiLog novas.fsdb novas.log novas_dump.log instruction_file.memh simv.vdb merged.vdb
