module icebreaker (
	clk_i,
	rst_i,
	tx_o,
	rx_i
);
	input wire clk_i;
	input wire rst_i;
	output wire tx_o;
	input wire rx_i;
	wire clk_12 = clk_i;
	wire clk_50;
	SB_PLL40_PAD #(
		.FEEDBACK_PATH("SIMPLE"),
		.DIVR(4'd0),
		.DIVF(7'd66),
		.DIVQ(3'd4),
		.FILTER_RANGE(3'd1)
	) pll(
		.LOCK(),
		.RESETB(1'b1),
		.BYPASS(1'b0),
		.PACKAGEPIN(clk_12),
		.PLLOUTGLOBAL(clk_50)
	);
	uart_comm #(.DATA_WIDTH(8)) uart_comm(
		.clk(clk_50),
		.rst(rst_i),
		.rx_i(rx_i),
		.tx_o(tx_o)
	);
endmodule
module uart_rx (
	clk,
	rst,
	m_axis_tdata,
	m_axis_tvalid,
	m_axis_tready,
	rxd,
	busy,
	overrun_error,
	frame_error,
	prescale
);
	parameter DATA_WIDTH = 8;
	input wire clk;
	input wire rst;
	output wire [DATA_WIDTH - 1:0] m_axis_tdata;
	output wire m_axis_tvalid;
	input wire m_axis_tready;
	input wire rxd;
	output wire busy;
	output wire overrun_error;
	output wire frame_error;
	input wire [15:0] prescale;
	reg [DATA_WIDTH - 1:0] m_axis_tdata_reg = 0;
	reg m_axis_tvalid_reg = 0;
	reg rxd_reg = 1;
	reg busy_reg = 0;
	reg overrun_error_reg = 0;
	reg frame_error_reg = 0;
	reg [DATA_WIDTH - 1:0] data_reg = 0;
	reg [18:0] prescale_reg = 0;
	reg [3:0] bit_cnt = 0;
	assign m_axis_tdata = m_axis_tdata_reg;
	assign m_axis_tvalid = m_axis_tvalid_reg;
	assign busy = busy_reg;
	assign overrun_error = overrun_error_reg;
	assign frame_error = frame_error_reg;
	always @(posedge clk)
		if (rst) begin
			m_axis_tdata_reg <= 0;
			m_axis_tvalid_reg <= 0;
			rxd_reg <= 1;
			prescale_reg <= 0;
			bit_cnt <= 0;
			busy_reg <= 0;
			overrun_error_reg <= 0;
			frame_error_reg <= 0;
		end
		else begin
			rxd_reg <= rxd;
			overrun_error_reg <= 0;
			frame_error_reg <= 0;
			if (m_axis_tvalid && m_axis_tready)
				m_axis_tvalid_reg <= 0;
			if (prescale_reg > 0)
				prescale_reg <= prescale_reg - 1;
			else if (bit_cnt > 0) begin
				if (bit_cnt > (DATA_WIDTH + 1)) begin
					if (!rxd_reg) begin
						bit_cnt <= bit_cnt - 1;
						prescale_reg <= (prescale << 3) - 1;
					end
					else begin
						bit_cnt <= 0;
						prescale_reg <= 0;
					end
				end
				else if (bit_cnt > 1) begin
					bit_cnt <= bit_cnt - 1;
					prescale_reg <= (prescale << 3) - 1;
					data_reg <= {rxd_reg, data_reg[DATA_WIDTH - 1:1]};
				end
				else if (bit_cnt == 1) begin
					bit_cnt <= bit_cnt - 1;
					if (rxd_reg) begin
						m_axis_tdata_reg <= data_reg;
						m_axis_tvalid_reg <= 1;
						overrun_error_reg <= m_axis_tvalid_reg;
					end
					else
						frame_error_reg <= 1;
				end
			end
			else begin
				busy_reg <= 0;
				if (!rxd_reg) begin
					prescale_reg <= (prescale << 2) - 2;
					bit_cnt <= DATA_WIDTH + 2;
					data_reg <= 0;
					busy_reg <= 1;
				end
			end
		end
endmodule
module uart_tx (
	clk,
	rst,
	s_axis_tdata,
	s_axis_tvalid,
	s_axis_tready,
	txd,
	busy,
	prescale
);
	parameter DATA_WIDTH = 8;
	input wire clk;
	input wire rst;
	input wire [DATA_WIDTH - 1:0] s_axis_tdata;
	input wire s_axis_tvalid;
	output wire s_axis_tready;
	output wire txd;
	output wire busy;
	input wire [15:0] prescale;
	reg s_axis_tready_reg = 0;
	reg txd_reg = 1;
	reg busy_reg = 0;
	reg [DATA_WIDTH:0] data_reg = 0;
	reg [18:0] prescale_reg = 0;
	reg [3:0] bit_cnt = 0;
	assign s_axis_tready = s_axis_tready_reg;
	assign txd = txd_reg;
	assign busy = busy_reg;
	always @(posedge clk)
		if (rst) begin
			s_axis_tready_reg <= 0;
			txd_reg <= 1;
			prescale_reg <= 0;
			bit_cnt <= 0;
			busy_reg <= 0;
		end
		else if (prescale_reg > 0) begin
			s_axis_tready_reg <= 0;
			prescale_reg <= prescale_reg - 1;
		end
		else if (bit_cnt == 0) begin
			s_axis_tready_reg <= 1;
			busy_reg <= 0;
			if (s_axis_tvalid) begin
				s_axis_tready_reg <= !s_axis_tready_reg;
				prescale_reg <= (prescale << 3) - 1;
				bit_cnt <= DATA_WIDTH + 1;
				data_reg <= {1'b1, s_axis_tdata};
				txd_reg <= 0;
				busy_reg <= 1;
			end
		end
		else if (bit_cnt > 1) begin
			bit_cnt <= bit_cnt - 1;
			prescale_reg <= (prescale << 3) - 1;
			{data_reg, txd_reg} <= {1'b0, data_reg};
		end
		else if (bit_cnt == 1) begin
			bit_cnt <= bit_cnt - 1;
			prescale_reg <= prescale << 3;
			txd_reg <= 1;
		end
endmodule
module uart_comm (
	clk,
	rst,
	rx_i,
	tx_o
);
	parameter DATA_WIDTH = 8;
	input wire clk;
	input wire rst;
	input wire rx_i;
	output wire tx_o;
	wire [7:0] data;
	wire tx_ready;
	wire rx_valid;
	uart_tx uart_tx(
		.clk(clk),
		.rst(rst),
		.s_axis_tdata(data),
		.s_axis_tvalid(rx_valid),
		.s_axis_tready(tx_ready),
		.txd(tx_o),
		.busy(),
		.prescale(1)
	);
	uart_rx uart_rx(
		.clk(clk),
		.rst(rst),
		.m_axis_tdata(data),
		.m_axis_tvalid(rx_valid),
		.m_axis_tready(tx_ready),
		.rxd(rx_i),
		.busy(),
		.overrun_error(),
		.frame_error(),
		.prescale(1)
	);
endmodule