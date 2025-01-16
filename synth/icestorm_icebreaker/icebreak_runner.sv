module icebreak_runner;

localparam DATA_WIDTH = 8;

// Variable Declaration

reg                   clk_i;
reg                   rst_i = 1;

logic tx_valid, rx_ready;
logic tb_tx, tb_rx;

logic [7:0] data_tb_i, data_tb_o;

logic busy_tx, busy_rx;

uart_tx uart_tx(.clk(clk_i), .rst(rst_i), .s_axis_tdata(data_tb_i), .s_axis_tvalid(tx_valid),
.s_axis_tready(), .txd(tb_tx), .busy(busy_tx), .prescale(1));


uart_rx uart_rx(.clk(clk_i), .rst(rst_i), .m_axis_tdata(data_tb_o), .m_axis_tvalid(), 
.m_axis_tready(rx_ready), .rxd(tb_rx), .busy(busy_rx), .overrun_error(), .frame_error(), 
.prescale(1));


initial begin
    clk_i = 0;
    forever begin
        #41.666ns; // 12MHz
        clk_i = !clk_i;
    end
end

logic pll_out;
initial begin
    pll_out = 0;
    forever begin
        #25.000ns; // 20MHz
        pll_out = !pll_out;
    end
end

initial begin;
    rst_i <= 1;
    @(posedge clk_i);
    @(posedge clk_i);
    rst_i <= 0;
end



icebreaker icebreaker (.clk_i, .rst_i, .rx_i(tb_tx), .tx_o(tb_rx));

assign icebreaker.pll.PLLOUTGLOBAL = pll_out;

task automatic run_single_UART(); // Will include packages l8r
    //Set Input Data
    if (busy_tx | busy_rx) @(negedge busy_rx);
    tx_valid <= 1'b1;
    rx_ready <= 1'b1;
    data_tb_i <= 8'd1;
    @(posedge clk_i);
    tx_valid <= 1'b0;
    rx_ready <= 1'b0;
    data_tb_i <= 8'd0;
    @(posedge clk_i);
endtask

task automatic run_UART(); // Will include packages l8r
    if (busy_tx | busy_rx) @(negedge busy_rx); //
    tx_valid <= 1'b1;
    rx_ready <= 1'b1;
    data_tb_i <= $urandom_range(0, 255); 
    @(posedge clk_i);
    tx_valid <= 1'b0;
    rx_ready <= 1'b0;
    data_tb_i <= 8'd0;
    @(posedge clk_i);
endtask

task automatic delay();
    int cycles = $urandom_range(20, 30);
    for (int i = 0; i < cycles; i++) begin
        @(posedge clk_i); #1;
    end
endtask

endmodule