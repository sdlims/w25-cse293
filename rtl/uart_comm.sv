`timescale 1ns / 1ps

module uart_comm 
#(
    parameter DATA_WIDTH = 8
)
(
    input   wire                        clk,
    input   wire                        rst,

    input   wire                        rx_i,
    output  wire                        tx_o
);

logic [3:0] state_d, state_q;

logic [7:0] rx_data, tx_data;
 
logic [0:0] rx_tvalid, rx_tready;
logic [0:0] tx_tvalid, tx_tready;

//If pos edge for rx_i, then we're ready
uart_rx uart_rx(.clk(clk), .rst(rst), .m_axis_tdata(rx_data), .m_axis_tvalid(rx_tvalid), 
.m_axis_tready(rx_tready), .rxd(rx_i), .busy(), .overrun_error(), .frame_error(),  .prescale(35));

uart_tx uart_tx(.clk(clk), .rst(rst), .s_axis_tdata(tx_data), .s_axis_tvalid(tx_tvalid),
.s_axis_tready(tx_tready), .txd(tx_o), .busy(), .prescale(35));

logic [0:0] idiv, div_valid;
logic [63:0] div_o;
bsg_idiv_iterative #(.width_p(32), .bitstack_p(0), .bits_per_iter_p(1))
idiv_inst (.clk_i(clk), .reset_i(rst), .v_i(idiv), .ready_and_o(), .dividend_i(operand_1_q), .divisor_i(operand_2_q), .signed_div_i(1'b1),
.v_o(div_valid), .quotient_o(div_o), .remainder_o(), .yumi_i(1'b1));

logic [7:0] opcode_d, opcode_q;
logic [15:0] length_d, length_q;
logic [15:0] frame_cnt_d, frame_cnt_q;
logic [31:0] operand_1_d, operand_1_q;
logic [31:0] operand_2_d, operand_2_q;

logic [0:0] cnt_d, cnt_q;
always_ff @( posedge clk ) begin : ps_ns
    if (rst) begin
        state_q <= 4'd0;
        frame_cnt_q <= 16'd0;
        opcode_q <= 8'h00;
        length_q <= '0;
        operand_1_q <= 32'd0;
        operand_2_q <= 32'd0;
        cnt_q <= 1'b0;
    end else begin
        state_q <= state_d;
        frame_cnt_q <= frame_cnt_d;
        opcode_q <= opcode_d;
        length_q <= length_d;
        operand_1_q <= operand_1_d;
        operand_2_q <= operand_2_d;
        cnt_q <= cnt_d;
    end
end

always_comb begin : state_machine
    state_d = state_q;
    opcode_d = opcode_q;
    rx_tready = 1'b0;
    tx_tvalid = 1'b0;
    idiv = 1'b0;
    tx_data = 'x;
    length_d = length_q;
    frame_cnt_d = frame_cnt_q;
    cnt_d = cnt_q;
    case(state_q)
        4'd0: begin // OPCODE
            rx_tready = 1'b1;
            if (rx_tvalid) begin
                frame_cnt_d = frame_cnt_q + 1;
                opcode_d = rx_data;
                state_d = 4'd1;
            end else begin
                frame_cnt_d = frame_cnt_q;
                opcode_d = '0;
                state_d = 4'd0;
            end
        end

        4'd1: begin // RESERVED
            rx_tready = 1'b1;
            if (rx_tvalid) begin
                frame_cnt_d = frame_cnt_q + 1;
                state_d = 4'd2;
            end else begin
                frame_cnt_d = frame_cnt_q;
                state_d = 4'd1;
            end
        end

        4'd2: begin // LENGTH LSB
            rx_tready = 1'b1;
            if (rx_tvalid) begin
                frame_cnt_d = frame_cnt_q + 1;
                length_d[7:0] = rx_data;
                state_d = 4'd3;
            end else begin
                length_d[7:0] = 8'd0;
                frame_cnt_d = frame_cnt_q;
                state_d = 4'd2;
            end
        end

        4'd3: begin // LENGTH MSB
            rx_tready = 1'b1;
            if (rx_tvalid) begin
                frame_cnt_d = frame_cnt_q + 1;
                length_d[15:8] = rx_data;
                if (opcode_q == 8'hEC) begin
                    state_d = 4'd4;
                end else begin
                    state_d = 4'd5;
                end
            end else begin
                length_d[15:8] = 8'd0;
                frame_cnt_d = frame_cnt_q;
                state_d = 4'd3;
            end
        end

        4'd4: begin // ECHO
            rx_tready = tx_tready;
            if (rx_tvalid && tx_tready) begin
                frame_cnt_d = frame_cnt_q + 1;
                tx_tvalid = 1'b1;
                tx_data = rx_data;
                if (frame_cnt_d == length_q) begin
                    state_d = 4'd0;
                    frame_cnt_d = '0;
                end else begin
                    state_d = 4'd4;
                    frame_cnt_d = frame_cnt_q;
                end
            end
        end

        4'd5: begin // OP_1
            rx_tready = 1'b1;
            idiv = 1'b0;
            if (rx_tvalid) begin
                idiv = 1'b0;
                frame_cnt_d = frame_cnt_q + 1;
                operand_1_d = rx_data;
                operand_2_d = 32'd1;
                state_d = 4'd6;
            end else begin
                frame_cnt_d = frame_cnt_q;
                operand_1_d = operand_1_q;
                operand_2_d = operand_1_q;
                state_d = 4'd5;
            end
        end

        4'd6: begin // OP_2
            rx_tready = 1'b1;
            idiv = 1'b0;
            if (rx_tvalid) begin
                frame_cnt_d = frame_cnt_q + 1;
                operand_2_d = rx_data;
                state_d = 4'd7;
            end else begin
                frame_cnt_d = frame_cnt_q;
                operand_2_d = operand_2_q;
                state_d = 4'd6;
            end
        end

        4'd7: begin
            if (cnt_q != 1'b1) begin
                cnt_d = cnt_q + 1;
            end else begin
                cnt_d = cnt_q;
                idiv = 1'b1;
                rx_tready = tx_tready;
                if (tx_tready && div_valid) begin
                    frame_cnt_d = frame_cnt_q + 1;
                    tx_tvalid = 1'b1;
                    tx_data = div_o[7:0];
                    if (frame_cnt_d >= length_q) begin
                        state_d = 4'd0;
                        frame_cnt_d = '0;
                    end else begin
                        state_d = 4'd7;
                        frame_cnt_d = frame_cnt_q + 1;
                    end
                end
            end
        end

        // 4'd5: begin // DELAY
        //     rx_tready = 1'b1;
        //     if (rx_tvalid) begin
        //         frame_cnt_d = frame_cnt_q;
        //         state_d = 4'd6;
        //     end else begin
        //         frame_cnt_d = frame_cnt_q;
        //         state_d = 4'd5;
        //     end
        // end

        // 4'd6: begin // OP_1
        //     rx_tready = 1'b1;
        //     idiv = 1'b0;
        //     if (rx_tvalid) begin
        //         idiv = 1'b0;
        //         frame_cnt_d = frame_cnt_q + 1;
        //         operand_1_d = rx_data;
        //         operand_2_d = 32'd1;
        //         state_d = 4'd7;
        //     end else begin
        //         frame_cnt_d = frame_cnt_q;
        //         operand_1_d = operand_1_q;
        //         operand_2_d = operand_1_q;
        //         state_d = 4'd6;
        //     end
        // end

        // 4'd7: begin // OP_2
        //     rx_tready = 1'b1;
        //     idiv = 1'b0;
        //     if (rx_tvalid) begin
        //         frame_cnt_d = frame_cnt_q + 1;
        //         operand_2_d = rx_data;
        //         state_d = 4'd8;
        //     end else begin
        //         frame_cnt_d = frame_cnt_q;
        //         operand_2_d = operand_2_q;
        //         state_d = 4'd7;
        //     end
        // end

        // 4'd8: begin
        //     if (cnt_q != 1'b1) begin
        //         cnt_d = cnt_q + 1;
        //     end else begin
        //         cnt_d = cnt_q;
        //         idiv = 1'b1;
        //         rx_tready = tx_tready;
        //         if (tx_tready && div_valid) begin
        //             frame_cnt_d = frame_cnt_q + 1;
        //             tx_tvalid = 1'b1;
        //             tx_data = div_o[7:0];
        //             if (frame_cnt_d >= length_q) begin
        //                 state_d = 4'd0;
        //                 frame_cnt_d = '0;
        //             end else begin
        //                 state_d = 4'd8;
        //                 frame_cnt_d = frame_cnt_q + 1;
        //             end
        //         end
        //     end
        // end
    endcase
end

endmodule
