module alu_rtl (
    input   clk_i,
    input   rst_i,
    input   rx_i,
    output  tx_o
);

logic [2:0] state_d, state_q;

logic [7:0] rx_data;
logic [31:0] tx_data;
logic [0:0] rx_valid, tx_ready;

logic [15:0] length_l;
 
//If pos edge for rx_i, then we're ready
uart_rx uart_rx(.clk(clk_i), .rst(rst_i), .m_axis_tdata(rx_data), .m_axis_tvalid(rx_valid), 
.m_axis_tready(), .rxd(rx_i), .busy(), .overrun_error(), .frame_error(), 
.prescale(35));

uart_tx uart_tx(.clk(clk_i), .rst(rst_i), .s_axis_tdata(tx_data_l), .s_axis_tvalid(),
.s_axis_tready(tx_ready), .txd(tx_o), .busy(), .prescale(35));

logic [2:0] frame_cnt_d, frame_cnt_q;
logic [7:0] opcode_l;
always_ff @( posedge clk_i ) begin : state
    if (rst_i) begin
        state_q <= 2'd0;
        frame_cnt_q <= 3'd0;
    end else begin
        state_q <= state_d;
        frame_cnt_q <= frame_cnt_d;
    end
end

always_comb begin : state_machine
    state_d = state_q;
    frame_cnt_d = frame_cnt_q;
    case(state_q)
        3'd0: begin
            if (rx_valid) begin
                opcode_l = rx_data;
                state_d = 3'd1;
                frame_cnt_d = frame_cnt_q + 1;

            end else begin
                opcode_l = 8'h00;
                state_d = 3'd0;
                frame_cnt_d = frame_cnt_q;

            end
        end
        3'd1: begin
            if (rx_valid) begin
                state_d = 3'd2;
                frame_cnt_d = frame_cnt_q + 1;

            end else begin
                state_d = 3'd1;
                frame_cnt_d = frame_cnt_q;

            end
        end
        3'd2: begin
            if (frame_cnt_q != 3'd4) begin
                if (rx_valid) begin
                    length_l += rx_data;
                    frame_cnt_d = frame_cnt_q + 1;
                end else begin
                    frame_cnt_d = frame_cnt_q;
                end
                state_d = 3'd2
            end else begin
                if (opcode_l == 8'hEC) begin
                    state_d = 3'd3;
                end else if (opcode_l == 8'hAD) begin
                    state_d = 3'd4;
                end else if (opcode_l == 8'hFF) begin
                    state_d = 3'd5;
                end else if (opcode_l == 8'hDE) begin
                    state_d = 3'd6;
                end else begin
                    ;
                end
            end
        end
        3'd3: begin
            if (frame_cnt_q != (length_l - 1)) begin
                if (rx_valid) begin
                    frame_cnt_d = frame_cnt_q + 1;
                    tx_data = rx_data;
                    tx_ready = 1'b1;
                end else begin
                    frame_cnt_d = frame_cnt_q;
                    tx_ready = 1'b0;
                end
            end else begin
                frame_cnt_d = 3'd0;
                tx_ready = 1'b1;
                state_d = 3'd0;
            end
        end
        3'd4: begin
            if (frame_cnt_q != (length_l - 1)) begin
                if (rx_valid) begin
                    tx_data += rx_data;
                    frame_cnt_d = frame_cnt_q + 1;
                end else begin
                    frame_cnt_d = frame_cnt_q;
                end
            end else begin
                frame_cnt_d = 3'd0;
                tx_ready = 1'b1;
                state_d = 3'd0;
            end
        end
        3'd5: begin
            if (frame_cnt_q != (length_l - 1)) begin
                if (rx_valid) begin
                    tx_data = tx_data * rx_data;
                    frame_cnt_d = frame_cnt_q + 1;
                end else begin
                    frame_cnt_d = frame_cnt_q;
                end
            end else begin
                frame_cnt_d = 3'd0;
                tx_ready = 1'b1;
                state_d = 3'd0;
            end
        end
        3'd6: begin
            if (frame_cnt_q != (length_l - 1)) begin
                if (rx_valid) begin
                    frame_cnt_d = frame_cnt_q + 1;
                    tx_data = rx_data;
                    tx_ready = 1'b1;
                end else begin
                    frame_cnt_d = frame_cnt_q;
                    tx_ready = 1'b0;
                end
            end else begin
                frame_cnt_d = 3'd0;
                tx_ready = 1'b1;
                state_d = 3'd0;
            end
        end
    endcase
end

endmodule