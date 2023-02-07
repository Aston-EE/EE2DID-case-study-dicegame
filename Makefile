# Makefile for students level 5 VHDL laboratory work
# using ghdl for vhdl simulation, gtkwave to view waveforms and vivado
# to syntesise and generate bit files for an FPGA
# (c) Dr. John A.R. Williams <j.a.r.williams@aston.ac.uk> 2018

# The conventions assumed by this makefile are given below in help definition
# below - just type `make` to see them. 

# Add a separate line here for each top level unit that is to be synthesised
# defining all the sources that are to be included.
# The rules assume the top level entity name matches it's vhdl filename
# and that the xdc constraints filename

# define the sources to be used here for bitfiloe or testbench targets
# it is important for simulations that the testbench
# sources in reverse heirarchical order

clk_prescaler_testbench: clk_prescaler.vhd clk_prescaler_testbench.vhd
dice_testbench: counter.vhd dice.vhd dice_testbench.vhd
compare_testbench: compare.vhd compare_testbench.vhd
control_testbench: compare.vhd control.vhd control_testbench.vhd
debounce_testbench: debounce.vhd debounce_testbench.vhd
counter_testbench: counter.vhd counter_testbench.vhd
display_testbench: display.vhd display_testbench.vhd
dice_testbench: counter.vhd dice.vhd dice_testbench.vhd

counter_demo.bit: clk_prescaler.vhd counter.vhd counter_demo.vhd
counter2_demo.bit: counter.vhd counter2_demo.vhd
debounce_demo.bit: debounce.vhd clk_prescaler.vhd debounce_demo.vhd
btn_push_testbench: clk_prescaler.vhd btn_push.vhd btn_push_testbench.vhd
btn_push_demo.bit: btn_push_demo.vhd clk_prescaler.vhd btn_push.vhd
display_demo.bit: display.vhd clk_prescaler.vhd display_demo.vhd

craps.bit: clk_prescaler.vhd display.vhd debounce.vhd counter.vhd compare.vhd control.vhd dice.vhd craps.vhd


#################################################################
# Do not change anything below this line
#################################################################

export TMPDIR=tmp
export LOGDIR=log

# Path to Xilinx Vivado binary
VIVADO = `(find /opt/Xilinx/ -name vivado -type f -executable || find /usr/local/Xilinx/ -name vivado -type f -executable) | grep 'bin/vivado'`

# FPGA partnumber for Basys 3 board
PARTNUMBER=xc7a35tcpg236-1 
GHDLFLAGS=--workdir=$(TMPDIR)/

TESTBENCHES=$(wildcard *_testbench.vhd)

define help
This makefile assumes the convention that testbenches are of the form
<[uut]_testbench.vhd> where [uut] is the name of the unit under test and
that vhdl entity names match the filenames in which they are defined.

The available commands are:
make <[uut]_testbench>       - run simulation
make <[uut]_testbench.view>  - view simulation waveform
make <[uut].check>           - syntax check [uut]
make <[top].bit>             - generate bitstream for toplevel [top].vhdl
make <[top].program>         - programe board using [top].bit
make sim-all                 - run all testbench simulations
make clean                   - delete all temporary generated files

Example:
make and_gate_testbench.view
will go through all the steps to analyse, elabroate and simulate the
and_gate_testbench.vhd and then run the viewer on the output waveform.
endef
export help

help:
	@echo "$$help"

sim-all: $(patsubst %.vhd,%.sim,$(TESTBENCHES))

testbenches: $(patsubst %.vhd,%.sim,$(TESTBENCHES))

$(TMPDIR)/%.o: %.vhd
	@mkdir -p $(TMPDIR)
	@ghdl -a $(GHDLFLAGS) $<

%.check:%.vhd
	@mkdir -p $(TMPDIR)
	ghdl -s $(GHDLFLAGS) $<

%_testbench:
	@mkdir -p $(TMPDIR)
	@for f in $?; do ghdl -a $(GHDLFLAGS) "$$f" ; done
	@ghdl -m $(GHDLFLAGS) $@
	@ghdl -r $(GHDLFLAGS) $@ --wave=$@.ghw

%_testbench.ghw: %_testbench
	@./$*_testbench --wave=$@

%.view: %
	@gtkwave $*.ghw --output=/dev/null&

.PHONY: clean
clean:
	@rm -fr $(TMPDIR) $(LOGDIR) tmp *~ *.o *_testbench *.bit *webtalk.* .Xil *.ghw submission.tar *.sav 

# Xilinx vivado synthesis rules

define SYNTHESIS_TCL
#step 1 read in source and constraint files
$(patsubst %.vhd,read_vhdl %.vhd;,$^)
read_xdc $*.xdc
#step 2 synthesise design
synth_design -top $* -part $(PARTNUMBER)
#step 3 run placement and logic optimisation
opt_design
power_opt_design
place_design
phys_opt_design
#step 4 run router, report actual utilisation and timing and drcs
route_design
report_utilization -file $(LOGDIR)/$*_utilisation.rpt
report_drc -file $(LOGDIR)/$*_drc.rpt
report_power -file $(LOGDIR)/$*_power.rpt
report_datasheet -file $(LOGDIR)/$*_datasheet.rpt
report_timing -file $(LOGDIR)/$*_timing.rpt
report_timing_summary -file $(LOGDIR)/$*_timing_summary.rpt
#step 5 output bitstream
write_bitstream -force $*.bit
endef
export SYNTHESIS_TCL

%.bit: 
	@mkdir -p $(TMPDIR) $(LOGDIR)
	@echo "$$SYNTHESIS_TCL" | $(VIVADO) -log $(LOGDIR)/$*_synth.log -nojournal -tempDir $(TMPDIR) -mode tcl
	@rm -fr *.jou *webtalk.* .Xil

define PROGRAM_TCL
open_hw
connect_hw_server
open_hw_target
current_hw_device [lindex [get_hw_devices] 0]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices] 0]
set_property PROGRAM.FILE {$*.bit} [lindex [get_hw_devices] 0]
program_hw_devices [lindex [get_hw_devices] 0]
close_hw_target
disconnect_hw_server
close_hw
quit
endef
export PROGRAM_TCL

.PHONY: %.program
%.program: %.bit
	@mkdir -p $(TMPDIR) $(LOGDIR)
	@echo "$$PROGRAM_TCL" | $(VIVADO) -log $(LOGDIR)/$*_prog.log -nojournal -tempDir $(TMPDIR) -mode tcl
	@rm -fr *.jou *webtalk.* .Xil

# submission recording rules
%.tar:
	@echo `date` $$USER `hostname` > submission.txt
	@tar -cf $@ *.vhd *.xdc Makefile $(LOGDIR) submission.txt
	@rm submission.txt
	@(if ls *.bit ; then tar -rf $@ *.bit; fi)
	@(if ls *.ghw ; then tar -rf $@ *.ghw; fi)
	@echo "File $@ created. Upload this file to Blackboard assignment."
