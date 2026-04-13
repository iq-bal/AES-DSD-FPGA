// AES-128 Top-Level Module
// Iterative architecture targeting Xilinx Artix-7 XC7A35T (xc7a35ticpg236-1L).
//
// Architecture overview:
//   - Key expansion  : combinatorial, generates all 11 round keys from cipher_key
//   - AES round      : combinatorial datapath (SubBytes→ShiftRows→MixColumns→AddRoundKey)
//   - Control unit   : 5-state FSM (IDLE/INIT_ROUND/MAIN_ROUND/FINAL_ROUND/DONE)
//   - State register : 128-bit, updated on each active round cycle
//
// Interface:
//   clk         - system clock (target 100-150 MHz on Artix-7)
//   rst         - synchronous active-high reset
//   start       - pulse high for one clock to begin encryption
//   plaintext   - 128-bit input (must be stable when start is asserted)
//   cipher_key  - 128-bit AES key (must be stable when start is asserted)
//   ciphertext  - 128-bit output (valid when done=1)
//   done        - high for one clock cycle when encryption is complete
//
// Latency: 12 clock cycles from start assertion to done assertion.
// Throughput (iterative): one block per 12 clock cycles.

`timescale 1ns / 1ps

module aes_top (
    input         clk,
    input         rst,
    input         start,
    input         decrypt,
    input  [127:0] plaintext,
    input  [127:0] cipher_key,
    output reg [127:0] ciphertext,
    output        done
);
    // -------------------------------------------------------------------------
    // Control unit signals
    // -------------------------------------------------------------------------
    wire [3:0] round_counter;
    wire       init_round_en;
    wire       round_en;
    wire       is_final_round;

    control_unit cu (
        .clk           (clk),
        .rst           (rst),
        .start         (start),
        .round_counter (round_counter),
        .init_round_en (init_round_en),
        .round_en      (round_en),
        .is_final_round(is_final_round),
        .done          (done)
    );

    // -------------------------------------------------------------------------
    // Key expansion (combinatorial): generates all 11 round keys
    // -------------------------------------------------------------------------
    wire [127:0] rk0,  rk1,  rk2,  rk3,  rk4;
    wire [127:0] rk5,  rk6,  rk7,  rk8,  rk9, rk10;

    key_expansion kex (
        .key          (cipher_key),
        .round_key_0  (rk0),
        .round_key_1  (rk1),
        .round_key_2  (rk2),
        .round_key_3  (rk3),
        .round_key_4  (rk4),
        .round_key_5  (rk5),
        .round_key_6  (rk6),
        .round_key_7  (rk7),
        .round_key_8  (rk8),
        .round_key_9  (rk9),
        .round_key_10 (rk10)
    );

    // -------------------------------------------------------------------------
    // Round key MUX: select key indexed by round_counter (or reversed if decrypting)
    // -------------------------------------------------------------------------
    wire [3:0] key_index = decrypt ? (4'd10 - round_counter) : round_counter;
    reg [127:0] current_round_key;
    
    always @(*) begin
        case (key_index)
            4'd0:    current_round_key = rk0;
            4'd1:    current_round_key = rk1;
            4'd2:    current_round_key = rk2;
            4'd3:    current_round_key = rk3;
            4'd4:    current_round_key = rk4;
            4'd5:    current_round_key = rk5;
            4'd6:    current_round_key = rk6;
            4'd7:    current_round_key = rk7;
            4'd8:    current_round_key = rk8;
            4'd9:    current_round_key = rk9;
            4'd10:   current_round_key = rk10;
            default: current_round_key = 128'b0;
        endcase
    end

    // -------------------------------------------------------------------------
    // State register
    // -------------------------------------------------------------------------
    reg [127:0] state_reg;

    // -------------------------------------------------------------------------
    // AES round datapath (combinatorial): operates on current state_reg
    // -------------------------------------------------------------------------
    wire [127:0] encrypt_round_out;
    aes_round round_inst (
        .state_in     (state_reg),
        .round_key    (current_round_key),
        .is_final_round(is_final_round),
        .state_out    (encrypt_round_out)
    );

    wire [127:0] decrypt_round_out;
    aes_inv_round inv_round_inst (
        .state_in     (state_reg),
        .round_key    (current_round_key),
        .is_final_round(is_final_round),
        .state_out    (decrypt_round_out)
    );

    wire [127:0] round_out = decrypt ? decrypt_round_out : encrypt_round_out;

    // -------------------------------------------------------------------------
    // State register update
    //   INIT_ROUND  : state ← plaintext ^ rk0  (initial AddRoundKey)
    //   MAIN_ROUND  : state ← aes_round(state, key[1..9])
    //   FINAL_ROUND : state ← aes_round(state, key[10], final=1)
    // -------------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_reg <= 128'b0;
        end else begin
            if (init_round_en)
                state_reg <= plaintext ^ current_round_key;   // initial AddRoundKey
            else if (round_en)
                state_reg <= round_out;         // main/final round
        end
    end

    // -------------------------------------------------------------------------
    // Output: latch ciphertext at the end of the final round
    // -------------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst)
            ciphertext <= 128'b0;
        else if (round_en && is_final_round)
            ciphertext <= round_out;
    end

endmodule
