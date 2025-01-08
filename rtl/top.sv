`timescale 1ns / 1ps

module top 
#(
    parameter DATA_WIDTH = 8
)
(
    input   wire                        clk,
    input   wire                        rst,
    
    input   wire [15:0]                 prescale,
    //input   wire [DATA_WIDTH-1:0]       data_i,
    output  wire [DATA_WIDTH-1:0]       data_o
);

/* verilator lint_off WIDTHEXPAND */

wire xd_w;
//wire busy_tx_w, ready_tx_w;

uart_tx uart_tx_inst(.clk, .rst, .s_axis_tdata(data_o), .s_axis_tvalid(1'b1),
.s_axis_tready(), .txd(xd_w), .busy(), .prescale);


//wire busy_rx_w, valid_rx_w;

uart_rx uart_rx_inst(.clk, .rst, .m_axis_tdata(data_o), .m_axis_tvalid(), 
.m_axis_tready(1'b1), .rxd(xd_w), .busy(), .overrun_error(), .frame_error(), 
.prescale); // Do I even need to sink the outputs

/* verilator lint_off WIDTHEXPAND */

endmodule