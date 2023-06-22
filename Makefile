# Makefile for students level 5 VHDL laboratory work
# using ghdl for vhdl simulation, gtkwave to view waveforms and vivado
# to synthesise and generate bit files for an FPGA
# Copyright 2017-2023 Aston University

# The conventions assumed by this makefile are given below in help definition
# below - just type `make` to see them. 

# Add a separate line here for each top level unit that is to be synthesised
# defining all the sources that are to be included.
# The rules assume the top level entity name matches it's vhdl filename
# and that the xdc constraints filename

# define the sources to be used here for bitfile or testbench targets
# it is important for simulations that the sources are in reverse heirarchical
# order i.e. later files have entities that depend on earlier ones.

and_gate_testbench: and_gate.vhd and_gate_testbench.vhd
and_gate.bit: and_gate.vhd
full_adder_testbench: full_adder.vhd full_adder_testbench.vhd
full_adder.bit: full_adder.vhd
clk_prescaler_testbench: clk_prescaler.vhd clk_prescaler_testbench.vhd
debounce_testbench: debounce.vhd clk_prescaler.vhd debounce_testbench.vhd
counter_testbench: counter.vhd counter_testbench.vhd
fourcounter.bit: EE2IDD.vhd debounce.vhd clk_prescaler.vhd counter.vhd fourcounter.vhd
fourcounter_testbench: clk_prescaler.vhd debounce.vhd counter.vhd fourcounter.vhd fourcounter_testbench.vhd

include casestudy.mk

#################################################################
# Do not change anything below this line
#################################################################

export TMPDIR=tmp
export LOGDIR=log

# Path to Xilinx Vivado binary
VIVADO = $(shell (find /opt/Xilinx/ -name vivado -type f -executable || find /usr/local/Xilinx/ -name vivado -type f -executable) | grep 'bin/vivado')

# FPGA partnumber for Basys 3 board
PARTNUMBER=xc7a35tcpg236-1 
GHDLFLAGS=--std=08 --workdir=$(TMPDIR)/
USERID=$(shell echo -n $$USER | md5sum | cut -c1-8)

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
	ghdl -a $(GHDLFLAGS) $<

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
	@rm -fr $(TMPDIR) $(LOGDIR) tmp *~ *.o *_testbench *webtalk.* .Xil *.ghw submission.tar *.sav 

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
set_property BITSTREAM.CONFIG.USERID $(USERID) [current_design]
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

#tcl instructions to create bin file for flash
define BIN_TCL
$(patsubst %.vhd,read_vhdl %.vhd;,$^)
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property BITSTREAM.STARTUP.STARTUPCLK CCLK [current_design]
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true
set_property config_mode SPIx4 [current_design]
synth_design -top $* -part $(PARTNUMBER)
read_xdc $*.xdc
place_design
route_design
set_property BITSTREAM.CONFIG.USERID $(USERID) [current_design]
write_bitstream -bin_file -force $*.bit
endef
export BIN_TCL

%.bin: 
	@mkdir -p $(TMPDIR) $(LOGDIR)
	@echo "$$BIN_TCL" | $(VIVADO) -log $(LOGDIR)/$*_synth.log -nojournal -tempDir $(TMPDIR) -mode tcl
	@rm -fr *.jou *webtalk.* .Xil

#tcl instructions to program flash  - derived from using GUI
define FLASH_TCL
open_hw
connect_hw_server
open_hw_target
current_hw_device [lindex [get_hw_devices] 0]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices] 0]
create_hw_cfgmem -hw_device [lindex [get_hw_devices xc7a35t_0] 0] [lindex [get_cfgmem_parts {s25fl032p-spi-x1_x2_x4}] 0]
set_property PROGRAM.BLANK_CHECK  0 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a35t_0] 0]]
set_property PROGRAM.ERASE  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a35t_0] 0]]
set_property PROGRAM.CFG_PROGRAM  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a35t_0] 0]]
set_property PROGRAM.VERIFY  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a35t_0] 0]]
set_property PROGRAM.CHECKSUM  0 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a35t_0] 0]]
set_property PROGRAM.ADDRESS_RANGE  {use_file} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a35t_0] 0]]
set_property PROGRAM.FILES [list {$*.bin}] [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a35t_0] 0]]
set_property PROGRAM.PRM_FILE {} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a35t_0] 0]]
set_property PROGRAM.ADDRESS_RANGE  {use_file} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a35t_0] 0]]
set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-none} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a35t_0] 0]]
create_hw_bitstream -hw_device [lindex [get_hw_devices xc7a35t_0] 0] [get_property PROGRAM.HW_CFGMEM_BITFILE [ lindex [get_hw_devices xc7a35t_0] 0]]; program_hw_devices [lindex [get_hw_devices xc7a35t_0] 0]; refresh_hw_device [lindex [get_hw_devices xc7a35t_0] 0];
program_hw_cfgmem -hw_cfgmem [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a35t_0] 0]]
close_hw_target
disconnect_hw_server
close_hw
quit
endef
export FLASH_TCL

.PHONY: %.flash
%.flash: %.bin
	@mkdir -p $(TMPDIR) $(LOGDIR)
	@echo "$$FLASH_TCL" | $(VIVADO) -log $(LOGDIR)/$*_prog.log -nojournal -tempDir $(TMPDIR) -mode tcl
	@rm -fr *.jou *webtalk.* .Xil

.PHONY: submission.tar
submission.tar:
	@echo `date` $$USER `hostname` > submission.txt
	@tar -cf --exclude submission.tar $@ *
	@rm submission.txt
	@echo "File $@ created. Upload this file to Blackboard assignment."
