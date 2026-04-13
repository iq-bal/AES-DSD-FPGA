// AES-128 Key Expansion
// Combinatorial generation of all 11 round keys from the 128-bit cipher key.
// Follows FIPS 197 Section 5.2 key schedule.
//
// For AES-128: 4 key words (w[0..3]) expanded to 44 words (w[0..43]).
// Round key i = {w[4i], w[4i+1], w[4i+2], w[4i+3]}
//
// Core operation for each new word group:
//   temp  = RotWord(w[4i-1])
//   temp  = SubWord(temp)
//   temp  = temp ^ Rcon[i]
//   w[4i] = w[4i-4] ^ temp
//   w[4i+1] = w[4i-3] ^ w[4i]
//   w[4i+2] = w[4i-2] ^ w[4i+1]
//   w[4i+3] = w[4i-1] ^ w[4i+2]
//
// Rcon values (only MSB byte of the 32-bit word matters):
//   Round 1-10: 01,02,04,08,10,20,40,80,1B,36

`timescale 1ns / 1ps

module key_expansion (
    input  [127:0] key,
    output [127:0] round_key_0,
    output [127:0] round_key_1,
    output [127:0] round_key_2,
    output [127:0] round_key_3,
    output [127:0] round_key_4,
    output [127:0] round_key_5,
    output [127:0] round_key_6,
    output [127:0] round_key_7,
    output [127:0] round_key_8,
    output [127:0] round_key_9,
    output [127:0] round_key_10
);
    // Round key 0 = cipher key itself
    assign round_key_0 = key;

    // -------------------------------------------------------------------------
    // Internal word wires: w[0..43], each 32 bits
    // w[0..3]  = cipher key words
    // -------------------------------------------------------------------------
    wire [31:0] w0, w1, w2, w3;
    assign w0 = key[127:96];
    assign w1 = key[ 95:64];
    assign w2 = key[ 63:32];
    assign w3 = key[ 31: 0];

    // -------------------------------------------------------------------------
    // Helper function implemented as wires: SubWord and RotWord
    // RotWord([a,b,c,d]) = [b,c,d,a]  (left rotate by 1 byte)
    // SubWord applies S-box to each of the 4 bytes
    // -------------------------------------------------------------------------

    // --- Round 1 (Rcon = 0x01000000) ---
    wire [31:0] rot1, sub1, temp1;
    wire [31:0] w4, w5, w6, w7;
    assign rot1 = {w3[23:0], w3[31:24]};  // RotWord(w3)
    sbox sb1_0(.in(rot1[31:24]), .out(sub1[31:24]));
    sbox sb1_1(.in(rot1[23:16]), .out(sub1[23:16]));
    sbox sb1_2(.in(rot1[15: 8]), .out(sub1[15: 8]));
    sbox sb1_3(.in(rot1[ 7: 0]), .out(sub1[ 7: 0]));
    assign temp1 = sub1 ^ 32'h01000000;
    assign w4 = w0 ^ temp1;
    assign w5 = w1 ^ w4;
    assign w6 = w2 ^ w5;
    assign w7 = w3 ^ w6;
    assign round_key_1 = {w4, w5, w6, w7};

    // --- Round 2 (Rcon = 0x02000000) ---
    wire [31:0] rot2, sub2, temp2;
    wire [31:0] w8, w9, w10, w11;
    assign rot2 = {w7[23:0], w7[31:24]};
    sbox sb2_0(.in(rot2[31:24]), .out(sub2[31:24]));
    sbox sb2_1(.in(rot2[23:16]), .out(sub2[23:16]));
    sbox sb2_2(.in(rot2[15: 8]), .out(sub2[15: 8]));
    sbox sb2_3(.in(rot2[ 7: 0]), .out(sub2[ 7: 0]));
    assign temp2 = sub2 ^ 32'h02000000;
    assign w8  = w4 ^ temp2;
    assign w9  = w5 ^ w8;
    assign w10 = w6 ^ w9;
    assign w11 = w7 ^ w10;
    assign round_key_2 = {w8, w9, w10, w11};

    // --- Round 3 (Rcon = 0x04000000) ---
    wire [31:0] rot3, sub3, temp3;
    wire [31:0] w12, w13, w14, w15;
    assign rot3 = {w11[23:0], w11[31:24]};
    sbox sb3_0(.in(rot3[31:24]), .out(sub3[31:24]));
    sbox sb3_1(.in(rot3[23:16]), .out(sub3[23:16]));
    sbox sb3_2(.in(rot3[15: 8]), .out(sub3[15: 8]));
    sbox sb3_3(.in(rot3[ 7: 0]), .out(sub3[ 7: 0]));
    assign temp3 = sub3 ^ 32'h04000000;
    assign w12 = w8  ^ temp3;
    assign w13 = w9  ^ w12;
    assign w14 = w10 ^ w13;
    assign w15 = w11 ^ w14;
    assign round_key_3 = {w12, w13, w14, w15};

    // --- Round 4 (Rcon = 0x08000000) ---
    wire [31:0] rot4, sub4, temp4;
    wire [31:0] w16, w17, w18, w19;
    assign rot4 = {w15[23:0], w15[31:24]};
    sbox sb4_0(.in(rot4[31:24]), .out(sub4[31:24]));
    sbox sb4_1(.in(rot4[23:16]), .out(sub4[23:16]));
    sbox sb4_2(.in(rot4[15: 8]), .out(sub4[15: 8]));
    sbox sb4_3(.in(rot4[ 7: 0]), .out(sub4[ 7: 0]));
    assign temp4 = sub4 ^ 32'h08000000;
    assign w16 = w12 ^ temp4;
    assign w17 = w13 ^ w16;
    assign w18 = w14 ^ w17;
    assign w19 = w15 ^ w18;
    assign round_key_4 = {w16, w17, w18, w19};

    // --- Round 5 (Rcon = 0x10000000) ---
    wire [31:0] rot5, sub5, temp5;
    wire [31:0] w20, w21, w22, w23;
    assign rot5 = {w19[23:0], w19[31:24]};
    sbox sb5_0(.in(rot5[31:24]), .out(sub5[31:24]));
    sbox sb5_1(.in(rot5[23:16]), .out(sub5[23:16]));
    sbox sb5_2(.in(rot5[15: 8]), .out(sub5[15: 8]));
    sbox sb5_3(.in(rot5[ 7: 0]), .out(sub5[ 7: 0]));
    assign temp5 = sub5 ^ 32'h10000000;
    assign w20 = w16 ^ temp5;
    assign w21 = w17 ^ w20;
    assign w22 = w18 ^ w21;
    assign w23 = w19 ^ w22;
    assign round_key_5 = {w20, w21, w22, w23};

    // --- Round 6 (Rcon = 0x20000000) ---
    wire [31:0] rot6, sub6, temp6;
    wire [31:0] w24, w25, w26, w27;
    assign rot6 = {w23[23:0], w23[31:24]};
    sbox sb6_0(.in(rot6[31:24]), .out(sub6[31:24]));
    sbox sb6_1(.in(rot6[23:16]), .out(sub6[23:16]));
    sbox sb6_2(.in(rot6[15: 8]), .out(sub6[15: 8]));
    sbox sb6_3(.in(rot6[ 7: 0]), .out(sub6[ 7: 0]));
    assign temp6 = sub6 ^ 32'h20000000;
    assign w24 = w20 ^ temp6;
    assign w25 = w21 ^ w24;
    assign w26 = w22 ^ w25;
    assign w27 = w23 ^ w26;
    assign round_key_6 = {w24, w25, w26, w27};

    // --- Round 7 (Rcon = 0x40000000) ---
    wire [31:0] rot7, sub7, temp7;
    wire [31:0] w28, w29, w30, w31;
    assign rot7 = {w27[23:0], w27[31:24]};
    sbox sb7_0(.in(rot7[31:24]), .out(sub7[31:24]));
    sbox sb7_1(.in(rot7[23:16]), .out(sub7[23:16]));
    sbox sb7_2(.in(rot7[15: 8]), .out(sub7[15: 8]));
    sbox sb7_3(.in(rot7[ 7: 0]), .out(sub7[ 7: 0]));
    assign temp7 = sub7 ^ 32'h40000000;
    assign w28 = w24 ^ temp7;
    assign w29 = w25 ^ w28;
    assign w30 = w26 ^ w29;
    assign w31 = w27 ^ w30;
    assign round_key_7 = {w28, w29, w30, w31};

    // --- Round 8 (Rcon = 0x80000000) ---
    wire [31:0] rot8, sub8, temp8;
    wire [31:0] w32, w33, w34, w35;
    assign rot8 = {w31[23:0], w31[31:24]};
    sbox sb8_0(.in(rot8[31:24]), .out(sub8[31:24]));
    sbox sb8_1(.in(rot8[23:16]), .out(sub8[23:16]));
    sbox sb8_2(.in(rot8[15: 8]), .out(sub8[15: 8]));
    sbox sb8_3(.in(rot8[ 7: 0]), .out(sub8[ 7: 0]));
    assign temp8 = sub8 ^ 32'h80000000;
    assign w32 = w28 ^ temp8;
    assign w33 = w29 ^ w32;
    assign w34 = w30 ^ w33;
    assign w35 = w31 ^ w34;
    assign round_key_8 = {w32, w33, w34, w35};

    // --- Round 9 (Rcon = 0x1B000000) ---
    wire [31:0] rot9, sub9, temp9;
    wire [31:0] w36, w37, w38, w39;
    assign rot9 = {w35[23:0], w35[31:24]};
    sbox sb9_0(.in(rot9[31:24]), .out(sub9[31:24]));
    sbox sb9_1(.in(rot9[23:16]), .out(sub9[23:16]));
    sbox sb9_2(.in(rot9[15: 8]), .out(sub9[15: 8]));
    sbox sb9_3(.in(rot9[ 7: 0]), .out(sub9[ 7: 0]));
    assign temp9 = sub9 ^ 32'h1b000000;
    assign w36 = w32 ^ temp9;
    assign w37 = w33 ^ w36;
    assign w38 = w34 ^ w37;
    assign w39 = w35 ^ w38;
    assign round_key_9 = {w36, w37, w38, w39};

    // --- Round 10 (Rcon = 0x36000000) ---
    wire [31:0] rot10, sub10, temp10;
    wire [31:0] w40, w41, w42, w43;
    assign rot10 = {w39[23:0], w39[31:24]};
    sbox sb10_0(.in(rot10[31:24]), .out(sub10[31:24]));
    sbox sb10_1(.in(rot10[23:16]), .out(sub10[23:16]));
    sbox sb10_2(.in(rot10[15: 8]), .out(sub10[15: 8]));
    sbox sb10_3(.in(rot10[ 7: 0]), .out(sub10[ 7: 0]));
    assign temp10 = sub10 ^ 32'h36000000;
    assign w40 = w36 ^ temp10;
    assign w41 = w37 ^ w40;
    assign w42 = w38 ^ w41;
    assign w43 = w39 ^ w42;
    assign round_key_10 = {w40, w41, w42, w43};

endmodule
