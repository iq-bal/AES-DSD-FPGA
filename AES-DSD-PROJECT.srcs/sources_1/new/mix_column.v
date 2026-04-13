// AES MixColumns - single column
// Operates on one 32-bit column: col_in[31:24]=a0, [23:16]=a1, [15:8]=a2, [7:0]=a3
//
// GF(2^8) multiplication by 2 (xtime):
//   xtime(a) = (a << 1) if MSB(a) == 0
//            = (a << 1) ^ 0x1B if MSB(a) == 1
//
// Column transformation (MixColumns matrix in GF(2^8)):
//   [02 03 01 01]   [a0]
//   [01 02 03 01] * [a1]
//   [01 01 02 03]   [a2]
//   [03 01 01 02]   [a3]
//
// Since 03*x = 02*x ^ x (in GF(2^8)):
//   c0 = xtime(a0) ^ (xtime(a1)^a1) ^ a2 ^ a3
//   c1 = a0 ^ xtime(a1) ^ (xtime(a2)^a2) ^ a3
//   c2 = a0 ^ a1 ^ xtime(a2) ^ (xtime(a3)^a3)
//   c3 = (xtime(a0)^a0) ^ a1 ^ a2 ^ xtime(a3)

`timescale 1ns / 1ps

module mix_column (
    input  [31:0] col_in,
    output [31:0] col_out
);
    wire [7:0] a0, a1, a2, a3;
    wire [7:0] b0, b1, b2, b3;  // bi = xtime(ai)

    assign a0 = col_in[31:24];
    assign a1 = col_in[23:16];
    assign a2 = col_in[15: 8];
    assign a3 = col_in[ 7: 0];

    // xtime: multiply by 2 in GF(2^8) mod x^8+x^4+x^3+x+1 (0x11B)
    assign b0 = a0[7] ? ({a0[6:0], 1'b0} ^ 8'h1b) : {a0[6:0], 1'b0};
    assign b1 = a1[7] ? ({a1[6:0], 1'b0} ^ 8'h1b) : {a1[6:0], 1'b0};
    assign b2 = a2[7] ? ({a2[6:0], 1'b0} ^ 8'h1b) : {a2[6:0], 1'b0};
    assign b3 = a3[7] ? ({a3[6:0], 1'b0} ^ 8'h1b) : {a3[6:0], 1'b0};

    // c0 = 02*a0 ^ 03*a1 ^ 01*a2 ^ 01*a3
    assign col_out[31:24] = b0 ^ b1 ^ a1 ^ a2 ^ a3;
    // c1 = 01*a0 ^ 02*a1 ^ 03*a2 ^ 01*a3
    assign col_out[23:16] = a0 ^ b1 ^ b2 ^ a2 ^ a3;
    // c2 = 01*a0 ^ 01*a1 ^ 02*a2 ^ 03*a3
    assign col_out[15: 8] = a0 ^ a1 ^ b2 ^ b3 ^ a3;
    // c3 = 03*a0 ^ 01*a1 ^ 01*a2 ^ 02*a3
    assign col_out[ 7: 0] = b0 ^ a0 ^ a1 ^ a2 ^ b3;
endmodule
