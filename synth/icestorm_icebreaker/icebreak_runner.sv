module icebreak_runner;

localparam DATA_WIDTH = 8;

// Variable Declaration

logic                   clk_i;
logic                   rst_i = 1;
wire [15:0]             prescale_w = 1; // Change this


logic   [DATA_WIDTH-1:0]   data_tb_i; 
logic   [DATA_WIDTH-1:0]   data_tb_o; //We're Monitoring this Output
logic   [0:0]              tx_valid_w;
logic   [0:0]      rx_ready_w;
logic   [0:0]      busy_tx_w;
logic   [0:0]      busy_rx_w;


initial begin
    clk_i = 0;
    forever begin
        #20ns; // 12MHz
        clk_i = !clk_i;
    end
end

logic pll_out;
initial begin
    pll_out = 0;
    forever begin
        #50.000ns; // 20MHz
        pll_out = !pll_out;
    end
end

initial begin;
    rst_i <= 1;
    @(posedge clk_i);
    rst_i <= 0;
end

assign icebreaker.pll.PLLOUTCORE = pll_out;

icebreaker icebreaker (.clk_i, .rst_i, .ready_i(rx_ready_w), .valid_i(tx_valid_w), .prescale(prescale_w), .data_i(data_tb_i));


task automatic run_single_UART(); // Will include packages l8r
    if ((busy_rx_w | busy_tx_w)) @(negedge busy_rx_w);
    //Set Input Data
    tx_valid_w <= 1'b1;
    rx_ready_w <= 1'b1;
    data_tb_i <= 8'd1;
    @(posedge clk_i);

    tx_valid_w <= 1'b0;
    rx_ready_w <= 1'b0;
    data_tb_i <= 8'd0;
    @(posedge clk_i);
    if ((busy_rx_w | busy_tx_w)) @(negedge busy_rx_w);
endtask

task automatic run_UART(); // Will include packages l8r
    if ((busy_rx_w | busy_tx_w)) @(negedge busy_rx_w);
    //Set Input Data
    tx_valid_w <= 1'b1;
    rx_ready_w <= 1'b1;
    data_tb_i <= $urandom_range(0, 255); 
    @(posedge clk_i);

    tx_valid_w <= 1'b0;
    rx_ready_w <= 1'b0;
    data_tb_i <= 8'd0;
    @(posedge clk_i);
    if ((busy_rx_w | busy_tx_w)) @(negedge busy_rx_w);
endtask

task automatic delay();
    int cycles = $urandom_range(10, 20);
    for (int i = 0; i < cycles; i++) begin
        @(posedge clk_i); #1;
    end
endtask

endmodule