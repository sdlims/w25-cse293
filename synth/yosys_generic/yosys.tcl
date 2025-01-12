
yosys -import

read_verilog synth/build/rtl.sv2v.v
read_verilog -sv synth/yosys_generic/uart_generic.sv
read_verilog -sv third_party/alexforencich_uart/rtl/uart_rx.v
read_verilog -sv third_party/alexforencich_uart/rtl/uart_tx.v

prep
opt -full
stat

write_verilog -noexpr -noattr -simple-lhs synth/yosys_generic/build/synth.v