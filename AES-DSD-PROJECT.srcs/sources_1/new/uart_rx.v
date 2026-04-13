`timescale 1ns / 1ps

module uart_rx #(
    parameter CLKS_PER_BIT = 868 // 100 MHz / 115200 baud
)(
    input            clk,
    input            rst,
    input            rx,
    output reg [7:0] data_out,
    output reg       valid
);

    localparam IDLE  = 3'd0;
    localparam START = 3'd1;
    localparam DATA  = 3'd2;
    localparam STOP  = 3'd3;

    reg [2:0] state;
    reg [9:0] clk_count;
    reg [2:0] bit_index;
    
    // Double register RX to prevent metastability
    reg rx_reg1, rx_reg2;
    always @(posedge clk) begin
        rx_reg1 <= rx;
        rx_reg2 <= rx_reg1;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            clk_count <= 0;
            bit_index <= 0;
            data_out <= 0;
            valid <= 0;
        end else begin
            case (state)
                IDLE: begin
                    valid <= 0;
                    clk_count <= 0;
                    bit_index <= 0;
                    if (rx_reg2 == 1'b0) begin // Start bit detected
                        state <= START;
                    end
                end
                
                START: begin
                    if (clk_count == (CLKS_PER_BIT-1)/2) begin
                        if (rx_reg2 == 1'b0) begin // Verify start bit
                            clk_count <= 0;
                            state <= DATA;
                        end else begin
                            state <= IDLE;
                        end
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end
                
                DATA: begin
                    if (clk_count < CLKS_PER_BIT-1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        data_out[bit_index] <= rx_reg2;
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            bit_index <= 0;
                            state <= STOP;
                        end
                    end
                end
                
                STOP: begin
                    if (clk_count < CLKS_PER_BIT-1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        valid <= 1; // Pulse valid for 1 clock cycle upon stop
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule
