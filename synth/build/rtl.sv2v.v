(* blackbox *) module SB_PLL40_PAD (
	PACKAGEPIN,
	PLLOUTCORE,
	PLLOUTGLOBAL,
	EXTFEEDBACK,
	DYNAMICDELAY,
	LOCK,
	BYPASS,
	RESETB,
	LATCHINPUTVALUE,
	SDO,
	SDI,
	SCLK
);
	input PACKAGEPIN;
	output wire PLLOUTCORE;
	output wire PLLOUTGLOBAL;
	input EXTFEEDBACK;
	input [7:0] DYNAMICDELAY;
	output wire LOCK;
	input BYPASS;
	input RESETB;
	input LATCHINPUTVALUE;
	output wire SDO;
	input SDI;
	input SCLK;
	parameter FEEDBACK_PATH = "SIMPLE";
	parameter DELAY_ADJUSTMENT_MODE_FEEDBACK = "FIXED";
	parameter DELAY_ADJUSTMENT_MODE_RELATIVE = "FIXED";
	parameter SHIFTREG_DIV_MODE = 1'b0;
	parameter FDA_FEEDBACK = 4'b0000;
	parameter FDA_RELATIVE = 4'b0000;
	parameter PLLOUT_SELECT = "GENCLK";
	parameter DIVR = 4'b0000;
	parameter DIVF = 7'b0000000;
	parameter DIVQ = 3'b000;
	parameter FILTER_RANGE = 3'b000;
	parameter ENABLE_ICEGATE = 1'b0;
	parameter TEST_MODE = 1'b0;
	parameter EXTERNAL_DIVIDE_FACTOR = 1;
endmodule
module uart_comm (
	clk,
	rst,
	ready_i,
	valid_i,
	prescale,
	data_i,
	busy_tx_o,
	busy_rx_o,
	data_o
);
	parameter DATA_WIDTH = 8;
	input wire clk;
	input wire rst;
	input wire ready_i;
	input wire valid_i;
	input wire [15:0] prescale;
	input wire [DATA_WIDTH - 1:0] data_i;
	output wire busy_tx_o;
	output wire busy_rx_o;
	output wire [DATA_WIDTH - 1:0] data_o;
	wire xd_w;
	uart_tx uart_tx_inst(
		.clk(clk),
		.rst(rst),
		.s_axis_tdata(data_i),
		.s_axis_tvalid(valid_i),
		.s_axis_tready(),
		.txd(xd_w),
		.busy(busy_tx_o),
		.prescale(prescale)
	);
	uart_rx uart_rx_inst(
		.clk(clk),
		.rst(rst),
		.m_axis_tdata(data_o),
		.m_axis_tvalid(),
		.m_axis_tready(ready_i),
		.rxd(xd_w),
		.busy(busy_rx_o),
		.overrun_error(),
		.frame_error(),
		.prescale(prescale)
	);
endmodule