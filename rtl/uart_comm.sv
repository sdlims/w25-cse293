`timescale 1ns / 1ps

module uart_comm 
#(
    parameter DATA_WIDTH = 8
)
(
    input   wire                        clk,
    input   wire                        rst,

    input   wire                        ready_i,
    input   wire                        valid_i,
    
    input   wire [15:0]                 prescale,
    input   wire [DATA_WIDTH-1:0]       data_i,
    output  wire                        busy_tx_o,
    output  wire                        busy_rx_o,
    output  wire [DATA_WIDTH-1:0]       data_o
);

/* verilator lint_off WIDTHEXPAND */

wire xd_w;


uart_tx uart_tx(.clk, .rst, .s_axis_tdata(data_i), .s_axis_tvalid(valid_i),
.s_axis_tready(), .txd(xd_w), .busy(busy_tx_o), .prescale);


//wire busy_rx_w, valid_rx_w;

uart_rx uart_rx(.clk, .rst, .m_axis_tdata(data_o), .m_axis_tvalid(), 
.m_axis_tready(ready_i), .rxd(xd_w), .busy(busy_rx_o), .overrun_error(), .frame_error(), 
.prescale); // Do I even need to sink the outputs

/* verilator lint_off WIDTHEXPAND */
// assign data_o = data_w;

endmodule
