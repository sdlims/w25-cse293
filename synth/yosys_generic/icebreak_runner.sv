module icebreak_runner;

localparam ClockPeriod = 21.0526316ns;
localparam prescale_lp = 35;

// Variable Declaration

logic                   clk_i;
logic                   rst_i = 1;


logic tb_tx_valid, tb_rx_ready;
logic tb_tx, tb_rx;

logic [7:0] tb_tx_data, tb_rx_data;

logic tb_tx_ready, tb_rx_valid;

uart_tx uart_tx(
    .clk(clk_i),
    .rst(rst_i),
    .s_axis_tdata(tb_tx_data),
    .s_axis_tvalid(tb_tx_valid),
    .s_axis_tready(tb_tx_ready),
    .txd(tb_tx),
    .busy(),
    .prescale(prescale_lp)
);

uart_rx uart_rx(
    .clk(clk_i),
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

uart_comm
    #()
dut
    (
      .clk(clk_i),
      .rst(rst_i),
      .rx_i(tb_tx),
      .tx_o(tb_rx)
    );

// Simulation

initial begin
    clk_i = 0;
    forever begin
        #(ClockPeriod/2);
        clk_i = !clk_i;
    end
end

task automatic reset;
    rst_i <= 1;
    @(posedge clk_i);
    @(posedge clk_i);
    rst_i <= 0;
endtask

task automatic send_byte(logic [7:0] d);
    tb_tx_valid <= 1'b1;
    tb_rx_ready <= 1'b1;
    tb_tx_data <= d;
    while (!tb_tx_ready) @(posedge clk_i);
    @(posedge clk_i); #1ps;
    tb_tx_valid <= 1'b0;
    tb_rx_ready <= 1'b0;
endtask

task automatic delay();
    int cycles = $urandom_range(10, 20);
    for (int i = 0; i < cycles; i++) begin
        @(posedge clk_i); #1;
    end
endtask

endmodule
