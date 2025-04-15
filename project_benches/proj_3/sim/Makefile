export ECE745_PROJECT_HOME ?= $(PWD)/../../..

include $(ECE745_PROJECT_HOME)/verification_ip/ncsu_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/wb_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/i2c_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/environment_packages/i2cmb_env_pkg/Makefile

GEN_TRANS_TYPE ?= i2cmb_generator
TEST_SEED ?= random
VLOG_OPT = -cover bcesf

CLI_DO_COMMANDS = -do " \
                    set NoQuitOnFinish 1; \
                    run -all; \
	 	            do save_coverage.do $(GEN_TRANS_TYPE); \
                    quit -f;" 

BATCH_DO_COMMANDS = -do " \
			set NoQuitOnFinish 1; \
			add wave -r *; \
			log -r *; \
			run -all; \
            exit; "

DEBUG_DO_COMMANDS = -do " \
                    set NoQuitOnFinish 1; \
                    do wave.do;\
                    run -a;"\

clean: 
	rm -rf work *.wlf transcript qrun.out
	rm -rf *.ucdb

comp_I2C_MB:
	vcom -cover sbceft ../rtl/iicmb_int_pkg.vhd
	vcom -cover sbceft ../rtl/iicmb_pkg.vhd
	vcom -cover sbceft ../rtl/mbyte.vhd
	vcom -cover sbceft ../rtl/mbit.vhd
	vcom -cover sbceft ../rtl/bus_state.vhd
	vcom -cover sbceft ../rtl/filter.vhd
	vcom -cover sbceft ../rtl/conditioner.vhd
	vcom -cover sbceft ../rtl/conditioner_mux.vhd
	vcom -cover sbceft ../rtl/iicmb_m.vhd
	vcom -cover sbceft ../rtl/regblock.vhd
	vcom -cover sbceft ../rtl/wishbone.vhd
	vcom -cover sbceft ../rtl/iicmb_m_wb.vhd

comp_bench: comp_ncsu_pkg comp_defines_pkg comp_wb_pkg comp_i2c_pkg comp_i2cmb_env_pkg 
	vlog ../testbench/top.sv

optimize:
	vopt +acc top -o optimized_debug_top_tb

compile: comp_I2C_MB comp_bench optimize

simulate:
	vsim  -i -classdebug -msgmode both -do "set NoQuitOnFinish 1; do wave.do" optimized_debug_top_tb

debug_3step: clean compile simulate

#debug:
#	qrun -64 -gui -visualizer -onfinish stop -classdebug -uvmcontrol=all -msgmode both -permit_unmatched_virtual_intf -l run.log -f filelist.f -sv_seed 123456 -msglimit error -msglimitcount 20 -do "set IterationLimit 140000; set NoQuitOnFinish 1; coverage attribute -name TESTNAME -value test_top; coverage save -onexit test_top.ucdb; do wave.do" -debug,livesim -qwavedb=+signal+memory=1024+report+parameter+class+assertion+uvm_schematic+msg+classmemory=1024+statictaskfunc -top top -covermultiuserenv -designfile design.bin 
run: clean compile
	vsim  -batch $(VSIM_OPT) $(BATCH_DO_COMMANDS) +GEN_TRANS_TYPE=$(GEN_TRANS_TYPE) optimized_debug_top_tb

run_cli:
	vsim -c -coverage -sv_seed $(TEST_SEED) $(CLI_DO_COMMANDS) +GEN_TRANS_TYPE=$(GEN_TRANS_TYPE) optimized_debug_top_tb

run_gui:
	vsim -coverage -sv_seed $(TEST_SEED) $(DEBUG_DO_COMMANDS) +GEN_TRANS_TYPE=$(GEN_TRANS_TYPE) optimized_debug_top_tb

cli: clean compile optimize run_cli

debug: clean compile optimize run_cli #merge_coverage view_coverage

convert_testplan:
	xml2ucdb -format Excel ./test_plan_layered_testbench.xml ./test_plan_layered_testbench.ucdb
#	add testbrowser ./*.ucdb

merge_coverage:
	vcover merge -stats=none -strip 0 -totals sim_and_testplan_merged.ucdb ./*.ucdb 
#	coverage open ./sim_and_testplan_merged.ucdb

report_coverage:
	vcover report -details -html -htmldir covhtmlreport -assert -directive -cvg -code bcefst -threshL 50 -threshH 90 ./sim_and_testplan_merged.ucdb

regress:
	./regress.sh

view_coverage:
	vsim -viewcov ./sim_and_testplan_merged.ucdb