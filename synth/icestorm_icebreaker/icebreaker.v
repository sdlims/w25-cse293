module icebreaker
#(
    parameter DATA_WIDTH = 8
)
(
    input   wire                clk_i,
    input wire                  rst_i,
    input wire                  ready_i,
    input wire                  valid_i,
    input wire [15:0]           prescale,
    input wire [DATA_WIDTH-1:0] data_i
);

wire clk_12 = clk_i;
wire clk_50;

SB_PLL40_PAD #(
    .FEEDBACK_PATH("SIMPLE"),
    .DIVR(4'd0),
    .DIVF(7'd66),
    .DIVQ(3'd4),
    .FILTER_RANGE(3'd1)
) pll (
    .LOCK(),
    .RESETB(1'b1),
    .BYPASS(1'b0),
    .PACKAGEPIN(clk_12),
    .PLLOUTCORE(clk_50)
);

uart_comm #(.DATA_WIDTH(8)) uart_comm(.clk(clk_50), .rst(rst_i), .ready_i, .valid_i, .prescale, .data_i, .busy_tx_o(), .busy_rx_o(), .data_o());

endmodule
