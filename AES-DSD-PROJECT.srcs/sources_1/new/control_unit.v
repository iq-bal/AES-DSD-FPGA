// AES Control Unit - Finite State Machine
// Implements an iterative architecture: one round datapath reused for all rounds.
//
// FSM States:
//   IDLE        - waiting for start
//   INIT_ROUND  - initial AddRoundKey with key[0] (round_counter=0)
//   MAIN_ROUND  - full rounds 1..9 (SubBytes+ShiftRows+MixColumns+AddRoundKey)
//   FINAL_ROUND - round 10 without MixColumns
//   DONE        - encryption complete, done=1 for one cycle
//
// Timing (cycles after start assertion):
//   Cycle 1  : INIT_ROUND   - state ← plaintext ^ key[0], counter → 1
//   Cycles 2-10: MAIN_ROUND - state ← round(state, key[i]), i=1..9, counter → 1..10
//   Cycle 11 : FINAL_ROUND  - state ← final_round(state, key[10])
//   Cycle 12 : DONE         - done=1, ciphertext latched
//   Cycle 13 : IDLE
//
// Total latency: 12 clock cycles from start to done.

`timescale 1ns / 1ps

module control_unit (
    input        clk,
    input        rst,
    input        start,
    output reg [3:0] round_counter,
    output reg   init_round_en,     // load plaintext ^ key[0] into state_reg
    output reg   round_en,          // clock enable for main/final round
    output reg   is_final_round,    // select final-round path (no MixColumns)
    output reg   done
);
    // State encoding
    localparam IDLE        = 3'd0;
    localparam INIT_ROUND  = 3'd1;
    localparam MAIN_ROUND  = 3'd2;
    localparam FINAL_ROUND = 3'd3;
    localparam DONE_STATE  = 3'd4;

    reg [2:0] state, next_state;

    // --------------------------------------------------------------------------
    // State register (synchronous reset)
    // --------------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    // --------------------------------------------------------------------------
    // Next-state logic (combinatorial)
    // --------------------------------------------------------------------------
    always @(*) begin
        case (state)
            IDLE:        next_state = start       ? INIT_ROUND  : IDLE;
            INIT_ROUND:  next_state = MAIN_ROUND;
            MAIN_ROUND:  next_state = (round_counter == 4'd9) ? FINAL_ROUND : MAIN_ROUND;
            FINAL_ROUND: next_state = DONE_STATE;
            DONE_STATE:  next_state = IDLE;
            default:     next_state = IDLE;
        endcase
    end

    // --------------------------------------------------------------------------
    // Round counter
    // Starts at 0 when INIT_ROUND begins, increments each active cycle.
    // Value at start of each state:
    //   INIT_ROUND  : 0  → key[0]
    //   MAIN_ROUND  : 1..9 → key[1..9]
    //   FINAL_ROUND : 10 → key[10]
    // --------------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst)
            round_counter <= 4'd0;
        else begin
            case (state)
                IDLE:        round_counter <= 4'd0;
                INIT_ROUND:  round_counter <= 4'd1;   // will be 1 when MAIN_ROUND starts
                MAIN_ROUND:  round_counter <= round_counter + 4'd1;
                default:     round_counter <= round_counter;
            endcase
        end
    end

    // --------------------------------------------------------------------------
    // Output logic (combinatorial, Mealy/Moore mix)
    // --------------------------------------------------------------------------
    always @(*) begin
        // Default outputs
        init_round_en = 1'b0;
        round_en      = 1'b0;
        is_final_round = 1'b0;
        done          = 1'b0;

        case (state)
            INIT_ROUND: begin
                init_round_en = 1'b1;
            end
            MAIN_ROUND: begin
                round_en      = 1'b1;
                is_final_round = 1'b0;
            end
            FINAL_ROUND: begin
                round_en      = 1'b1;
                is_final_round = 1'b1;
            end
            DONE_STATE: begin
                done = 1'b1;
            end
            default: begin
                // IDLE: all outputs default (zero)
            end
        endcase
    end

endmodule
