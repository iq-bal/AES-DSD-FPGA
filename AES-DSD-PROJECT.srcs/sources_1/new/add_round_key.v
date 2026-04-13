// AES AddRoundKey Transformation
// XOR the 128-bit state with the 128-bit round key.
// This operation is its own inverse: XOR twice = identity.
// Resource usage: 128 LUTs (one XOR per bit, minimal logic).

`timescale 1ns / 1ps

module add_round_key (
    input  [127:0] state_in,
    input  [127:0] round_key,
    output [127:0] state_out
);
    assign state_out = state_in ^ round_key;
endmodule
