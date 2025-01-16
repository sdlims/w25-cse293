module icebreaker
(
    input   wire                    clk_i,
    input   wire                    rst_i,
    output  wire                    tx_o,
    input   wire                    rx_i
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
    .PLLOUTGLOBAL(clk_50)
);

uart_comm #(.DATA_WIDTH(8)) uart_comm(.clk(clk_50), .rst(rst_i), .rx_i(rx_i), .tx_o(tx_o));

endmodule
