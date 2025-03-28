`timescale 1ns / 1ps

module uart_comm
#(
    parameter DATA_WIDTH = 8,
    parameter prescale_lp = 35
)
(
    input   wire                        clk,
    input   wire                        rst,

    input   wire                        rx_i,
    output  wire                        tx_o
);

logic [7:0] rx_data;
logic [7:0] tx_data;

logic [0:0] rx_valid, rx_ready;
logic [0:0] tx_valid, tx_ready;

uart_rx uart_rx(
    .clk(clk),
    .rst(rst),
    .m_axis_tdata(rx_data),
    .m_axis_tvalid(rx_valid),
    .m_axis_tready(rx_ready),
    .rxd(rx_i),
    .busy(),
    .overrun_error(),
    .frame_error(),
    .prescale(prescale_lp)
);

uart_tx uart_tx(
    .clk(clk),
    .rst(rst),
    .s_axis_tdata(tx_data),
    .s_axis_tvalid(tx_valid),
    .s_axis_tready(tx_ready),
    .txd(tx_o),
    .busy(),
    .prescale(prescale_lp)
);

typedef enum logic [3:0] {
    FETCH_OPCODE,
    FETCH_RESERVED,
    FETCH_LENGTH_LSB,
    FETCH_LENGTH_MSB,
    FETCH_ECHO_DATA,
    FETCH_OPERAND_1,
    FETCH_OPERAND_2,
    WAITING_FOR_OPERATION
} state_t;

typedef enum logic [7:0] {
    NOP = 8'h00,
    ECHO = 8'hEC,
    // ADD = 8'hAD,
    // MUL = 8'hFF,
    DIV = 8'hDE
} opcode_t;

state_t state_d, state_q;
opcode_t opcode_d, opcode_q;
logic [15:0] length_d, length_q;
logic [15:0] frame_cnt_d, frame_cnt_q;
logic [31:0] operand_1_d, operand_1_q;
logic [31:0] operand_2_d, operand_2_q;

logic [0:0] div_valid;
logic [31:0] div_o;

bsg_idiv_iterative bsg_idiv(
    .clk_i(clk),
    .reset_i(rst),
    .v_i(state_q == WAITING_FOR_OPERATION),
    .ready_and_o(),
    .dividend_i(operand_1_q),
    .divisor_i(operand_2_q),
    .signed_div_i(1'b1),
    .v_o(div_valid),
    .quotient_o(div_o),
    .remainder_o(),
    .yumi_i(1'b1)
);

always_comb begin
    state_d = state_q;
    opcode_d = opcode_q;
    rx_ready = 0;
    tx_valid = 0;
    tx_data = 'x;
    length_d = length_q;
    frame_cnt_d = frame_cnt_q;
    operand_1_d = operand_1_q;
    operand_2_d = operand_2_q;

    if (state_q == FETCH_OPCODE) begin
        rx_ready = 1;
        if (rx_valid) begin
            frame_cnt_d++;
            opcode_d = opcode_t'(rx_data);
            state_d = FETCH_RESERVED;
        end
    end else if (state_q == FETCH_RESERVED) begin
        rx_ready = 1;
        if (rx_valid) begin
            frame_cnt_d++;
            state_d = FETCH_LENGTH_LSB;
        end
    end else if (state_q == FETCH_LENGTH_LSB) begin
        rx_ready = 1;
        if (rx_valid) begin
            frame_cnt_d++;
            length_d[7:0] = rx_data;
            state_d = FETCH_LENGTH_MSB;
        end
    end else if (state_q == FETCH_LENGTH_MSB) begin
        rx_ready = 1;
        if (rx_valid) begin
            frame_cnt_d++;
            length_d[15:8] = rx_data;
            if (opcode_q==ECHO) begin
                state_d = FETCH_ECHO_DATA;
            end else begin
                state_d = FETCH_OPERAND_1;
            end
        end
    end else if (state_q == FETCH_ECHO_DATA) begin
        rx_ready = tx_ready;
        if (rx_ready && rx_valid) begin
            frame_cnt_d++;
            tx_data = rx_data;
            tx_valid = 1;
            if (frame_cnt_d == length_q) begin
                state_d = FETCH_OPCODE;
            end
        end
    end else if (state_q == FETCH_OPERAND_1) begin
        rx_ready = 1'b1;
        if (rx_valid) begin
            frame_cnt_d++;
            operand_1_d = rx_data;
            state_d = FETCH_OPERAND_2;
        end
    end else if (state_q == FETCH_OPERAND_2) begin
        rx_ready = 1'b1;
        if (rx_valid) begin
            frame_cnt_d++;
            operand_2_d = rx_data;
            state_d = WAITING_FOR_OPERATION;
        end
    end else if (state_q == WAITING_FOR_OPERATION) begin
        rx_ready = tx_ready;
        if (rx_ready && div_valid) begin
            frame_cnt_d++;
            tx_data = div_o[7:0];
            tx_valid = 1;
            if (frame_cnt_d == length_q) begin
                state_d = FETCH_OPCODE;
            end
        end
    end
end

always_ff @( posedge clk ) begin
    if (rst) begin
        state_q <= FETCH_OPCODE;
        opcode_q <= NOP;
        length_q <= '0;
        frame_cnt_q <= '0;
        operand_1_q <= '0;
        operand_2_q <= '0;
    end else begin
        state_q <= state_d;
        opcode_q <= opcode_d;
        length_q <= length_d;
        frame_cnt_q <= frame_cnt_d;
        operand_1_q <= operand_1_d;
        operand_2_q <= operand_2_d;
    end
end

endmodule
