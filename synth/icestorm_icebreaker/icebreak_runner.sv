// sv2v synth/icestorm_icebreaker/icebreaker.v third_party/alexforencich_uart/rtl/uart_rx.v third_party/alexforencich_uart/rtl/uart_tx.v rtl/uart_comm.sv -w synth/icestorm_icebreaker/build/rtl.sv2v.v 

module icebreak_runner;

localparam DATA_WIDTH = 8;
localparam int prescale_lp = 35;

// Variable Declaration

logic                   clk_i;
logic                   rst_i = 1;

logic tx_valid, rx_ready;
logic tb_tx, tb_rx;

logic [7:0] data_tb_i, data_tb_o;

logic busy_tx, busy_rx;

logic tx_ready_o, rx_valid_o;

uart_tx uart_tx(.clk(pll_out), .rst(~rst_i), .s_axis_tdata(data_tb_i), .s_axis_tvalid(tx_valid),
.s_axis_tready(tx_ready_o), .txd(tb_tx), .busy(busy_tx), .prescale(prescale_lp));


uart_rx uart_rx(.clk(pll_out), .rst(~rst_i), .m_axis_tdata(data_tb_o), .m_axis_tvalid(rx_valid_o), 
.m_axis_tready(rx_ready), .rxd(tb_rx), .busy(busy_rx), .overrun_error(), .frame_error(), 
.prescale(prescale_lp));



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

initial begin;
    rst_i <= 0;
    @(posedge pll_out);
    @(posedge pll_out);
    rst_i <= 1;
end



icebreaker icebreaker (.clk_i, .rst_i(rst_i), .rx_i(tb_tx), .tx_o(tb_rx));

assign icebreaker.pll.PLLOUTGLOBAL = pll_out;
// assign icebreaker.clk_32_256 = pll_out;

task automatic run_single_UART(); // Will include packages l8r
    //Set Input Data
    if (busy_tx | busy_rx) @(negedge busy_rx);
    tx_valid <= 1'b1;
    rx_ready <= 1'b1;
    data_tb_i <= 8'd1;
    @(posedge pll_out);
    @(posedge pll_out);
    tx_valid <= 1'b0;
    rx_ready <= 1'b0;
    data_tb_i <= 8'd0;
endtask

task automatic run_UART(); // Will include packages l8r
    tx_valid <= 1'b1;
    rx_ready <= 1'b1;
    data_tb_i <= {8'hEC}; // EC, AD, FF, DE 
    @(posedge pll_out);
    @(posedge pll_out);
    tx_valid <= 1'b0;
    rx_ready <= 1'b0;
    while (busy_tx) @(negedge pll_out);

    tx_valid <= 1'b1;
    rx_ready <= 1'b1;
    data_tb_i <= 8'h00;
    @(posedge pll_out);
    @(posedge pll_out);
    tx_valid <= 1'b0;
    rx_ready <= 1'b0;
    while (busy_tx) @(negedge pll_out);

    tx_valid <= 1'b1;
    rx_ready <= 1'b1;
    data_tb_i <= 8'h06;
    @(posedge pll_out);
    @(posedge pll_out);
    tx_valid <= 1'b0;
    rx_ready <= 1'b0;
    while (busy_tx) @(negedge pll_out);

    tx_valid <= 1'b1;
    rx_ready <= 1'b1;
    data_tb_i <= 8'h00;
    @(posedge pll_out);
    @(posedge pll_out);
    tx_valid <= 1'b0;
    rx_ready <= 1'b0;
    while (busy_tx) @(negedge pll_out);

    tx_valid <= 1'b1;
    rx_ready <= 1'b1;
    data_tb_i <= 8'h02;
    @(posedge pll_out);
    @(posedge pll_out);
    tx_valid <= 1'b0;
    rx_ready <= 1'b0;
    while (busy_tx) @(negedge pll_out);

    tx_valid <= 1'b1;
    rx_ready <= 1'b1;
    data_tb_i <= 8'h01;
    @(posedge pll_out);
    @(posedge pll_out);
    tx_valid <= 1'b0;
    rx_ready <= 1'b0;
    while (busy_tx) @(negedge pll_out);
endtask

task automatic delay();
    #50;
endtask

endmodule