`timescale 1ns / 1ps

module uart_comm 
#(
    parameter DATA_WIDTH = 8
)
(
    input   wire                        clk,
    input   wire                        rst,

    input   wire                        tx_valid,
    input   wire                        rx_ready,

    input   wire                        rx_i,
    output  wire                        tx_o
);

logic [2:0] state_d, state_q;

logic [7:0] rx_data;
logic [7:0] tx_data_d, tx_data_q;

logic [15:0] length_d, length_q;
 
 logic [0:0] rx_tvalid, tx_tready;
//If pos edge for rx_i, then we're ready
uart_rx uart_rx(.clk(clk), .rst(rst), .m_axis_tdata(rx_data), .m_axis_tvalid(rx_tvalid), 
.m_axis_tready(1'b1), .rxd(rx_i), .busy(), .overrun_error(), .frame_error(), 
.prescale(35));

uart_tx uart_tx(.clk(clk), .rst(rst), .s_axis_tdata(tx_data_q), .s_axis_tvalid((state_q >= 2) && data_o_f),
.s_axis_tready(tx_tready), .txd(tx_o), .busy(), .prescale(35));

logic [3:0] frame_cnt_d, frame_cnt_q;
logic [7:0] opcode_d, opcode_q;

logic [0:0] cnt_d, cnt_q;
always_ff @( posedge clk ) begin : state
    if (rst) begin
        state_q <= 3'd7;
        frame_cnt_q <= 4'd0;
        tx_data_q <= '0;
        opcode_q <= 8'h00;
        length_q <= '0;
        cnt_q <= 1'b0;
    end else begin
        state_q <= state_d;
        frame_cnt_q <= frame_cnt_d;
        tx_data_q <= tx_data_d;
        opcode_q <= opcode_d;
        length_q <= length_d;
        cnt_q <= cnt_d;
    end
end

logic [0:0] tx_valid_ed;
always_ff @(posedge clk) begin
    if (rst) begin
        tx_valid_ed <= 1'b0;
    end else if (!tx_valid_ed & tx_valid) begin
        tx_valid_ed <= 1'b1;
    end else begin
        tx_valid_ed <= 1'b0;
    end
end

logic [0:0] data_o_f;
always_comb begin : state_machine
    state_d = state_q;
    frame_cnt_d = frame_cnt_q;
    
    tx_data_d = tx_data_q;
    opcode_d = opcode_q;
    length_d = length_q;

    data_o_f = 1'b0;

    cnt_d = cnt_q;
    case(state_q)
        3'd0: begin
            if (rx_tvalid) begin
                opcode_d = rx_data;
                state_d = 3'd1;
                frame_cnt_d = 1;

            end else begin
                opcode_d = 8'h00;
                state_d = 3'd0;
                frame_cnt_d = frame_cnt_q;

            end
        end
        3'd1: begin
            if (rx_tvalid) begin
                state_d = 3'd2;
                frame_cnt_d = 2;

            end else begin
                state_d = 3'd1;
                frame_cnt_d = frame_cnt_q;
            end
        end
        3'd2: begin
            if (frame_cnt_q != 3'd4) begin
                if (rx_tvalid) begin
                    length_d += rx_data;  
                    frame_cnt_d = frame_cnt_q + 1;  
                end else begin
                    frame_cnt_d = frame_cnt_q;
                    length_d = length_q;
                end

                state_d = 3'd2;
            end else begin
                if (opcode_q == 8'hEC) begin
                    state_d = 3'd3;
                    
                end else if (opcode_q == 8'hAD) begin
                    state_d = 3'd4;

                    
                end else if (opcode_q == 8'hFF) begin
                    state_d = 3'd5;

                    
                end else if (opcode_q == 8'hDE) begin
                    state_d = 3'd6;

                    
                end else begin
                    
                end
            end
        end
        3'd3: begin
            if (frame_cnt_q != (length_q + 1)) begin
                data_o_f = 1'b1;
                if (rx_tvalid) begin
                    frame_cnt_d = frame_cnt_q + 1;
                    tx_data_d = rx_data;
                end else begin
                    frame_cnt_d = frame_cnt_q;      
                end
            end else begin
                data_o_f = 1'b1;
                frame_cnt_d = 3'd0;
                state_d = 3'd0; 
            end
        end
        3'd4: begin // ADD
            if (frame_cnt_q != (length_q)) begin
                if (rx_tvalid) begin
                    frame_cnt_d = frame_cnt_q + 1;
                    tx_data_d += rx_data;  
                    data_o_f = 1'b0;  
                end else begin
                    frame_cnt_d = frame_cnt_q; 
                    data_o_f = 1'b0;      
                end
            end else begin
                frame_cnt_d = 3'd0;
                data_o_f = 1'b1;
                state_d = 3'd0; 
            end
        end
        3'd5: begin // MUL
            if (frame_cnt_q != (length_q)) begin
                if (rx_tvalid) begin
                    frame_cnt_d = frame_cnt_q + 1;
                    if (tx_data_q == 0) begin
                        tx_data_d = rx_data;
                    end else begin
                        tx_data_d = tx_data_q * rx_data;  
                    end
                    data_o_f = 1'b0;  
                end else begin
                    frame_cnt_d = frame_cnt_q; 
                    data_o_f = 1'b0;      
                end
            end else begin
                frame_cnt_d = 3'd0;
                data_o_f = 1'b1;
                state_d = 3'd0; 
            end
        end
        3'd6: begin // DIV
            if (frame_cnt_q != (length_q)) begin
                if (rx_tvalid) begin
                    frame_cnt_d = frame_cnt_q + 1;
                    if (tx_data_q == 0) begin
                        tx_data_d = rx_data;
                    end else begin
                        tx_data_d = tx_data_q / rx_data;  
                    end
                    data_o_f = 1'b0;  
                end else begin
                    frame_cnt_d = frame_cnt_q; 
                    data_o_f = 1'b0;      
                end
            end else begin
                frame_cnt_d = 3'd0;
                data_o_f = 1'b1;
                state_d = 3'd0; 
            end
        end

        3'd7: begin
            if (tx_valid) begin
                if (cnt_q != 1) begin
                    cnt_d = cnt_q + 1;
                    state_d = 3'd7;
                end else begin
                    cnt_d = cnt_q;
                    state_d = 3'd0;
                end
            end
            else state_d = 3'd7;
        end
        default: begin
            
            state_d = 3'd0;
            
        end
    endcase
end

endmodule