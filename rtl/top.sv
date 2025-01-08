module top(
    input   [0:0]   clk_i,
    output          clk_o
);

  (* blackbox *)
// This is a PLL! You'll learn about these later...
SB_PLL40_PAD 
#(.FEEDBACK_PATH("SIMPLE")
    ,.PLLOUT_SELECT("GENCLK")
    ,.DIVR(4'b0000)
    ,.DIVF(7'b1000011)
    ,.DIVQ(3'b101)
    ,.FILTER_RANGE(3'b001)
    )
pll_inst
    (.PACKAGEPIN(clk_i)
    ,.PLLOUTCORE(clk_o)
    ,.RESETB(1'b1)
    ,.BYPASS(1'b0)
    );

endmodule
