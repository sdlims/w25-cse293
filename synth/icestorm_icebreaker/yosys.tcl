
yosys -import

exec sv2v synth/icestorm_icebreaker/icebreaker.v -w synth/icestorm_icebreaker/build/synth.v

read_verilog synth/build/rtl.sv2v.v synth/icestorm_icebreaker/icebreaker.v
read_verilog third_party/alexforencich_uart/rtl/uart_rx.v
read_verilog third_party/alexforencich_uart/rtl/uart_tx.v

synth_ice40 -top icebreaker

write_verilog -noexpr -noattr -simple-lhs synth/icestorm_icebreaker/build/synth.v
write_json synth/icestorm_icebreaker/build/synth.json