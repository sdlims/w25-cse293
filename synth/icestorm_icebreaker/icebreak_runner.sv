module icebreak_runner;

localparam ClockPeriod = 21.0526316ns;
localparam prescale_lp = 35;

// Variable Declaration

logic                   clk_i;
logic                   rst_i = 1;


logic tb_tx_valid = 0, tb_rx_ready = 0;
logic tb_tx, tb_rx;

logic [7:0] tb_tx_data, tb_rx_data;

logic tb_tx_ready, tb_rx_valid;

uart_tx uart_tx(
    .clk(pll_out),
    .rst(rst_i),
    .s_axis_tdata(tb_tx_data),
    .s_axis_tvalid(tb_tx_valid),
    .s_axis_tready(tb_tx_ready),
    .txd(tb_tx),
    .busy(),
    .prescale(prescale_lp)
);

uart_rx uart_rx(
    .clk(pll_out),
    .rst(rst_i),
    .m_axis_tdata(tb_rx_data),
    .m_axis_tvalid(tb_rx_valid),
    .m_axis_tready(tb_rx_ready),
    .rxd(tb_rx),
    .busy(),
    .overrun_error(),
    .frame_error(),
    .prescale(prescale_lp)
);

initial begin
    clk_i = 0;
    forever begin
        #41.666ns; // 12MHz // 41.666
        clk_i = !clk_i;
    end
end

logic pll_out;
initial begin
    pll_out = 0;
    forever begin
        #15.503875969ns; // 32.256MHz // 15.503875969
        pll_out = !pll_out;
    end
end

icebreaker icebreaker (
    .clk_i,
    .rst_ni(!rst_i),
    .rx_i(tb_tx),
    .tx_o(tb_rx)
);

assign icebreaker.pll.PLLOUTGLOBAL = pll_out;

// Simulation

task automatic reset;
    rst_i <= 1;
    @(posedge clk_i);
    @(posedge pll_out);
    @(posedge clk_i);
    @(posedge pll_out);
    rst_i <= 0;
endtask

task automatic send_byte(logic [7:0] d);
    tb_tx_valid <= 1'b1;
    tb_rx_ready <= 1'b1;
    tb_tx_data <= d;
    while (!tb_tx_ready) @(posedge pll_out);
    @(posedge pll_out); #1ps;
    tb_tx_valid <= 1'b0;
    tb_rx_ready <= 1'b0;
endtask

task automatic delay();
    int cycles = $urandom_range(10, 20);
    for (int i = 0; i < cycles; i++) begin
        @(posedge pll_out); #1ps;
    end
endtask

endmodule
