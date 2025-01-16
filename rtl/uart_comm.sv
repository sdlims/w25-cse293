`timescale 1ns / 1ps

module uart_comm 
#(
    parameter DATA_WIDTH = 8
)
(
    input   wire                        clk,
    input   wire                        rst,

    input   wire                        rx_i,
    output  wire                        tx_o
);

logic [7:0] data;

/* verilator lint_off WIDTHEXPAND */

logic tx_ready;


uart_tx uart_tx(.clk, .rst, .s_axis_tdata(data), .s_axis_tvalid(rx_valid),
.s_axis_tready(tx_ready), .txd(tx_o), .busy(), .prescale(1));


//wire busy_rx_w, valid_rx_w;
logic rx_valid;

uart_rx uart_rx(.clk, .rst, .m_axis_tdata(data), .m_axis_tvalid(rx_valid), 
.m_axis_tready(tx_ready), .rxd(rx_i), .busy(), .overrun_error(), .frame_error(), 
.prescale(1));

/* verilator lint_off WIDTHEXPAND */

endmodule
