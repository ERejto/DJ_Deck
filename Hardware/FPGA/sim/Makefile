codec_control    := $(wildcard ../src/codec/control/*.sv)
codec_control_tb := $(wildcard ../tb/codec/control/*.sv)

.PHONY: compile_codec_control clean


test_codec_control: $(codec_control)
	xvlog -sv $(codec_control)
	xvlog -sv $(codec_control_tb)
	xelab --timescale 1ns/1ps -debug all codec_control_tb
	xsim  codec_control_tb -gui

clean:
	rm -r xsim.dir *.log *.pb *.jou
