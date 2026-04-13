// AES Inverse MixColumns - single column
// InvMixColumns matrix over GF(2^8):
//   [0E 0B 0D 09]   [a0]
//   [09 0E 0B 0D] * [a1]
//   [0D 09 0E 0B]   [a2]
//   [0B 0D 09 0E]   [a3]
//
// GF(2^8) multiplications derived using repeated xtime:
//   t1(a) = xtime(a)           = 0x02 * a
//   t2(a) = xtime(t1(a))       = 0x04 * a
//   t4(a) = xtime(t2(a))       = 0x08 * a
//   0x09 * a = t4 ^ a
//   0x0B * a = t4 ^ t1 ^ a
//   0x0D * a = t4 ^ t2 ^ a
//   0x0E * a = t4 ^ t2 ^ t1

`timescale 1ns / 1ps

module inv_mix_column (
    input  [31:0] col_in,
    output [31:0] col_out
);
    wire [7:0] a0, a1, a2, a3;

    assign a0 = col_in[31:24];
    assign a1 = col_in[23:16];
    assign a2 = col_in[15: 8];
    assign a3 = col_in[ 7: 0];

    // xtime helpers for each byte
    wire [7:0] t1_a0, t1_a1, t1_a2, t1_a3;  // 0x02 * ai
    wire [7:0] t2_a0, t2_a1, t2_a2, t2_a3;  // 0x04 * ai
    wire [7:0] t4_a0, t4_a1, t4_a2, t4_a3;  // 0x08 * ai

    assign t1_a0 = a0[7] ? ({a0[6:0], 1'b0} ^ 8'h1b) : {a0[6:0], 1'b0};
    assign t1_a1 = a1[7] ? ({a1[6:0], 1'b0} ^ 8'h1b) : {a1[6:0], 1'b0};
    assign t1_a2 = a2[7] ? ({a2[6:0], 1'b0} ^ 8'h1b) : {a2[6:0], 1'b0};
    assign t1_a3 = a3[7] ? ({a3[6:0], 1'b0} ^ 8'h1b) : {a3[6:0], 1'b0};

    assign t2_a0 = t1_a0[7] ? ({t1_a0[6:0], 1'b0} ^ 8'h1b) : {t1_a0[6:0], 1'b0};
    assign t2_a1 = t1_a1[7] ? ({t1_a1[6:0], 1'b0} ^ 8'h1b) : {t1_a1[6:0], 1'b0};
    assign t2_a2 = t1_a2[7] ? ({t1_a2[6:0], 1'b0} ^ 8'h1b) : {t1_a2[6:0], 1'b0};
    assign t2_a3 = t1_a3[7] ? ({t1_a3[6:0], 1'b0} ^ 8'h1b) : {t1_a3[6:0], 1'b0};

    assign t4_a0 = t2_a0[7] ? ({t2_a0[6:0], 1'b0} ^ 8'h1b) : {t2_a0[6:0], 1'b0};
    assign t4_a1 = t2_a1[7] ? ({t2_a1[6:0], 1'b0} ^ 8'h1b) : {t2_a1[6:0], 1'b0};
    assign t4_a2 = t2_a2[7] ? ({t2_a2[6:0], 1'b0} ^ 8'h1b) : {t2_a2[6:0], 1'b0};
    assign t4_a3 = t2_a3[7] ? ({t2_a3[6:0], 1'b0} ^ 8'h1b) : {t2_a3[6:0], 1'b0};

    // Precompute coefficient*byte products
    wire [7:0] mul9_a0, mul9_a1, mul9_a2, mul9_a3;  // 0x09 * ai = t4 ^ a
    wire [7:0] mulb_a0, mulb_a1, mulb_a2, mulb_a3;  // 0x0B * ai = t4 ^ t1 ^ a
    wire [7:0] muld_a0, muld_a1, muld_a2, muld_a3;  // 0x0D * ai = t4 ^ t2 ^ a
    wire [7:0] mule_a0, mule_a1, mule_a2, mule_a3;  // 0x0E * ai = t4 ^ t2 ^ t1

    assign mul9_a0 = t4_a0 ^ a0;  assign mul9_a1 = t4_a1 ^ a1;
    assign mul9_a2 = t4_a2 ^ a2;  assign mul9_a3 = t4_a3 ^ a3;

    assign mulb_a0 = t4_a0 ^ t1_a0 ^ a0;  assign mulb_a1 = t4_a1 ^ t1_a1 ^ a1;
    assign mulb_a2 = t4_a2 ^ t1_a2 ^ a2;  assign mulb_a3 = t4_a3 ^ t1_a3 ^ a3;

    assign muld_a0 = t4_a0 ^ t2_a0 ^ a0;  assign muld_a1 = t4_a1 ^ t2_a1 ^ a1;
    assign muld_a2 = t4_a2 ^ t2_a2 ^ a2;  assign muld_a3 = t4_a3 ^ t2_a3 ^ a3;

    assign mule_a0 = t4_a0 ^ t2_a0 ^ t1_a0;  assign mule_a1 = t4_a1 ^ t2_a1 ^ t1_a1;
    assign mule_a2 = t4_a2 ^ t2_a2 ^ t1_a2;  assign mule_a3 = t4_a3 ^ t2_a3 ^ t1_a3;

    // c0 = 0E*a0 ^ 0B*a1 ^ 0D*a2 ^ 09*a3
    assign col_out[31:24] = mule_a0 ^ mulb_a1 ^ muld_a2 ^ mul9_a3;
    // c1 = 09*a0 ^ 0E*a1 ^ 0B*a2 ^ 0D*a3
    assign col_out[23:16] = mul9_a0 ^ mule_a1 ^ mulb_a2 ^ muld_a3;
    // c2 = 0D*a0 ^ 09*a1 ^ 0E*a2 ^ 0B*a3
    assign col_out[15: 8] = muld_a0 ^ mul9_a1 ^ mule_a2 ^ mulb_a3;
    // c3 = 0B*a0 ^ 0D*a1 ^ 09*a2 ^ 0E*a3
    assign col_out[ 7: 0] = mulb_a0 ^ muld_a1 ^ mul9_a2 ^ mule_a3;
endmodule
