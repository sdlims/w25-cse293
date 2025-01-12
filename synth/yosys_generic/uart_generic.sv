`timescale 1ns / 1ps

module uart_generic 
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

uart_comm #() uart_comm(.*);

endmodule
