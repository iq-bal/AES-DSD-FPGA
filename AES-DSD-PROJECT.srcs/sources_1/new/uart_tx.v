`timescale 1ns / 1ps

module uart_tx #(
    parameter CLKS_PER_BIT = 868 // 100 MHz / 115200 baud
)(
    input        clk,
    input        rst,
    input        start,
    input  [7:0] data_in,
    output reg   tx,
    output reg   busy
);

    localparam IDLE  = 3'd0;
    localparam START = 3'd1;
    localparam DATA  = 3'd2;
    localparam STOP  = 3'd3;

    reg [2:0] state;
    reg [9:0] clk_count;
    reg [2:0] bit_index;
    reg [7:0] tx_data;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            tx <= 1'b1; // Idle state is high
            busy <= 0;
            clk_count <= 0;
            bit_index <= 0;
            tx_data <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1'b1;
                    clk_count <= 0;
                    bit_index <= 0;
                    if (start) begin
                        busy <= 1;
                        tx_data <= data_in;
                        state <= START;
                    end else begin
                        busy <= 0;
                    end
                end
                
                START: begin
                    tx <= 1'b0; // Send Start bit (low)
                    if (clk_count < CLKS_PER_BIT-1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        state <= DATA;
                    end
                end
                
                DATA: begin
                    tx <= tx_data[bit_index];
                    if (clk_count < CLKS_PER_BIT-1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            bit_index <= 0;
                            state <= STOP;
                        end
                    end
                end
                
                STOP: begin
                    tx <= 1'b1; // Send Stop bit (high)
                    if (clk_count < CLKS_PER_BIT-1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        state <= IDLE;
                        busy <= 0;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule
