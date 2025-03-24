// nextpnr-ice40 --json synth/icestorm_icebreaker/build/synth.json --pcf synth/icestorm_icebreaker/icebreaker.pcf --asc synth/icestorm_icebreaker/build/synth.asc --package sg48 --up5k
// sudo openFPGALoader -b ice40_generic -f synth/icestorm_icebreaker/build/icebreaker.bit


module icebreaker
(
    input   wire                    clk_i,
    input   wire                    rst_ni,
    output  wire                    tx_o,
    input   wire                    rx_i,

    output  wire                    LEDR_N,
    output  wire                    LEDG_N
);

wire clk_12 = clk_i;
wire clk_32_256;

// For debugging
always @(posedge clk_32_256) begin
    if (!rst_ni) begin
        LEDR_N <= 1;
        LEDG_N <= 1;
    end else begin
        if (rx_i==0) LEDR_N <= 0;
        if (tx_o==0) LEDG_N <= 0;
    end
end

// icepll -i 12 -o 32.256
SB_PLL40_PAD #(
    .FEEDBACK_PATH("SIMPLE"),
    .DIVR(4'd0),
    .DIVF(7'd85),
    .DIVQ(3'd5),
    .FILTER_RANGE(3'd1)
) pll (
    .LOCK(),
    .RESETB(1'b1),
    .BYPASS(1'b0),
    .PACKAGEPIN(clk_12),
    .PLLOUTGLOBAL(clk_32_256)
);

uart_comm #(
    .DATA_WIDTH(8),
    .prescale_lp(35)
) uart_comm(
    .clk(clk_32_256),
    .rst(!rst_ni),
    .rx_i(rx_i),
    .tx_o(tx_o)
);

endmodule
