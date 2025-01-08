create_clock -name clk -period 8.103 [get_ports clk_i]

set_output_delay -clock clk -min 0.0 [get_ports {*_o *_o[*}]
set_output_delay -clock clk -max 0.0 [get_ports {*_o *_o[*}]

set_input_delay -clock clk -min 0.0 [get_ports {*_i *_ni *_i[*}]
set_input_delay -clock clk -max 0.0 [get_ports {*_i *_ni *_i[*}]
