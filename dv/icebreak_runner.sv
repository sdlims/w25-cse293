module icebreak_runner;

localparam ClockPeriod = 21.0526316ns;
localparam prescale_lp = 35;

// Variable Declaration

logic                   clk_i;
logic                   rst_i = 1;


logic tx_valid, rx_ready;
logic tb_tx, tb_rx;

logic [7:0] data_tb_i, data_tb_o;

logic busy_tx, busy_rx;

logic tx_ready_o, rx_valid_o;

uart_tx uart_tx(.clk(clk_i), .rst(rst_i), .s_axis_tdata(data_tb_i), .s_axis_tvalid(tx_valid),
.s_axis_tready(tx_ready_o), .txd(tb_tx), .busy(busy_tx), .prescale(prescale_lp));


uart_rx uart_rx(.clk(clk_i), .rst(rst_i), .m_axis_tdata(data_tb_o), .m_axis_tvalid(rx_valid_o), 
.m_axis_tready(rx_ready), .rxd(tb_rx), .busy(busy_rx), .overrun_error(), .frame_error(), 
.prescale(prescale_lp));

uart_comm 
    #()
dut
    (
      .clk(clk_i),
      .rst(rst_i),
      .tx_valid(tx_valid),
      .rx_ready(rx_ready),
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

initial begin;
    rst_i <= 1;
    @(posedge clk_i);
    @(posedge clk_i);
    rst_i <= 0;
end

// task automatic run_single_UART(); // Will include packages l8r
//     //Set Input Data
//     while (busy) @(negedge busy);
//     tx_valid <= 1'b1;
//     rx_ready <= 1'b1;
//     data_tb_i <= 8'd1;
//     @(posedge clk_i);
//     tx_valid <= 1'b0;
//     rx_ready <= 1'b0;
//     data_tb_i <= 8'd0;
//     @(posedge clk_i);
// endtask

task automatic run_UART(logic [7:0] task_data); // Will include packages l8r
    tx_valid <= 1'b1;
    rx_ready <= 1'b1;
    data_tb_i <= task_data;
    while(!tx_ready_o) @(posedge clk_i);
    @(posedge clk_i); #1ps;
    tx_valid <= 1'b0;
    rx_ready <= 1'b0;
endtask

task automatic delay();
    int cycles = $urandom_range(10, 20);
    for (int i = 0; i < cycles; i++) begin
        @(posedge clk_i); #1;
    end
endtask

endmodule