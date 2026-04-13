`timescale 1ns / 1ps

module uart_aes_top (
    input        clk,
    input        rst,        // Active-high reset from button
    input        decrypt_mode_switch, // Switch 0
    input        uart_rx,
    output       uart_tx,
    output [2:0] led         // Status LEDs
);

    // UART RX
    wire [7:0] rx_data;
    wire       rx_valid;
    
    uart_rx #(
        .CLKS_PER_BIT(868) // 100MHz / 115200 Baud
    ) urx (
        .clk(clk),
        .rst(rst),
        .rx(uart_rx),
        .data_out(rx_data),
        .valid(rx_valid)
    );

    // UART TX
    reg        tx_start;
    wire [7:0] tx_data_in;
    wire       tx_busy;

    uart_tx #(
        .CLKS_PER_BIT(868)
    ) utx (
        .clk(clk),
        .rst(rst),
        .start(tx_start),
        .data_in(tx_data_in),
        .tx(uart_tx),
        .busy(tx_busy)
    );

    // AES Module
    reg          aes_start;
    reg  [127:0] plaintext;
    reg  [127:0] cipher_key;
    wire [127:0] ciphertext;
    wire         aes_done;

    aes_top aes_inst (
        .clk(clk),
        .rst(rst),
        .start(aes_start),
        .decrypt(decrypt_mode_switch),
        .plaintext(plaintext),
        .cipher_key(cipher_key),
        .ciphertext(ciphertext),
        .done(aes_done)
    );

    // FSM States
    localparam WAIT_RX = 2'd0;
    localparam COMPUTE = 2'd1;
    localparam SEND_TX = 2'd2;

    reg [1:0] state;
    reg [6:0] rx_count; // 0 to 63 (64 hex characters: 32 Key + 32 PT)
    reg [5:0] tx_count; // 0 to 33 (32 hex characters + \r + \n)
    
    reg [127:0] tx_shift_reg;

    // Status LEDs: LED0 = Receiving, LED1 = Computing, LED2 = Sending Result
    assign led[0] = (state == WAIT_RX);
    assign led[1] = (state == COMPUTE);
    assign led[2] = (state == SEND_TX);

    // Filter to only accept valid Hex characters (0-9, A-F, a-f)
    wire is_hex = (rx_data >= 8'h30 && rx_data <= 8'h39) || 
                  (rx_data >= 8'h41 && rx_data <= 8'h46) || 
                  (rx_data >= 8'h61 && rx_data <= 8'h66);

    // Hex ASCII character to 4-bit Binary conversion
    function [3:0] hex2bin(input [7:0] ascii);
        begin
            if (ascii >= 8'h30 && ascii <= 8'h39)
                hex2bin = ascii - 8'h30;
            else if (ascii >= 8'h41 && ascii <= 8'h46)
                hex2bin = ascii - 8'h41 + 4'd10;
            else if (ascii >= 8'h61 && ascii <= 8'h66)
                hex2bin = ascii - 8'h61 + 4'd10;
            else
                hex2bin = 4'd0;
        end
    endfunction

    // 4-bit Binary to Hex ASCII character conversion (Uppercase)
    function [7:0] bin2hex(input [3:0] bin);
        begin
            if (bin <= 4'd9)
                bin2hex = 8'h30 + {4'd0, bin};
            else
                bin2hex = 8'h41 + ({4'd0, bin} - 8'd10);
        end
    endfunction

    // Combinatorial logic to select the next byte to send over UART TX
    reg [7:0] tx_data_mux;
    always @(*) begin
        if (tx_count < 32) begin
            // Extract the top 4 bits (MSB nibble) from the shift register
            tx_data_mux = bin2hex(tx_shift_reg[127:124]);
        end else if (tx_count == 32) begin
            tx_data_mux = 8'h0D; // Carriage Return (\r)
        end else begin
            tx_data_mux = 8'h0A; // Line Feed (\n)
        end
    end
    assign tx_data_in = tx_data_mux;

    // Main Control FSM
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= WAIT_RX;
            rx_count <= 0;
            tx_count <= 0;
            aes_start <= 0;
            tx_start <= 0;
            cipher_key <= 0;
            plaintext <= 0;
            tx_shift_reg <= 0;
        end else begin
            case (state)
                WAIT_RX: begin
                    aes_start <= 0;
                    if (rx_valid && is_hex) begin
                        if (rx_count < 32) begin
                            // First 32 hex chars represent the 128-bit Key
                            // Shift left by 4, inserting the new nibble at the bottom
                            cipher_key <= {cipher_key[123:0], hex2bin(rx_data)};
                        end else begin
                            // Next 32 hex chars represent the 128-bit Plaintext 
                            plaintext <= {plaintext[123:0], hex2bin(rx_data)};
                        end
                        
                        if (rx_count == 63) begin // 64 hex characters received
                            state <= COMPUTE;
                            aes_start <= 1;
                            rx_count <= 0;
                        end else begin
                            rx_count <= rx_count + 1;
                        end
                    end
                end
                
                COMPUTE: begin
                    aes_start <= 0;
                    if (aes_done) begin // Wait for encryption to finish (~12 cycles)
                        state <= SEND_TX;
                        tx_count <= 0;
                        tx_shift_reg <= ciphertext; // Load ciphertext to shift register
                    end
                end
                
                SEND_TX: begin
                    if (!tx_busy && !tx_start) begin // UART TX is idle, trigger transmission
                        if (tx_count < 34) begin // 32 hex + 2 line returns
                            tx_start <= 1; // Pulse start
                        end else begin
                            state <= WAIT_RX; // Finished sending, wait for next input
                            rx_count <= 0;
                        end
                    end else if (tx_busy && tx_start) begin // Acknowledge that UART TX caught the start pulse
                        tx_start <= 0;
                        if (tx_count < 32) begin
                            // Shift left by 4 to expose the next nibble at the top
                            tx_shift_reg <= {tx_shift_reg[123:0], 4'd0}; 
                        end
                        tx_count <= tx_count + 1;
                    end
                end
                
                default: begin
                    state <= WAIT_RX;
                end
            endcase
        end
    end

endmodule
