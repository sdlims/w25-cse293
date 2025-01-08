TOP := tb

export YOSYS_DATDIR := $(shell yosys-config --datdir)
export BASEJUMP_STL_DIR = $(abspath third_party/basejump_stl)
export ALEX_UART_DIR = $(abspath third_party/alexforencich_uart)

RTL := $(shell \
 YOSYS_DATDIR=$(YOSYS_DATDIR) \
 BASEJUMP_STL_DIR=$(BASEJUMP_STL_DIR) \
 python3 misc/convert_filelist.py Makefile rtl/rtl.f \
)


.PHONY: lint sim synth gls gls_xc7 xc7 vivado clean

lint: 
	verilator lint.vlt -f rtl/rtl.f -f dv/dv.f --lint-only --top uart_comm

sim: 
	verilator lint.vlt --Mdir ${TOP}_$@_dir -f rtl/rtl.f -f dv/dv.f --binary --top ${TOP}
	./${TOP}_$@_dir/V${TOP} +verilator+rand+reset+2

gls: synth/yosys_generic/build/synth.v
	verilator lint.vlt --Mdir ${TOP}_$@_dir -f synth/yosys_generic/gls.f -f dv/dv.f --binary --top ${TOP}
	./${TOP}_$@_dir/V${TOP} +verilator+rand+reset+2

gls_xc7: synth/yosys_xc7/build/xc7.v
	verilator lint.vlt --Mdir ${TOP}_$@_dir -f synth/yosys_xc7/gls_xc7.f -f dv/dv.f --binary --top ${TOP}
	./${TOP}_$@_dir/V${TOP} +verilator+rand+reset+2