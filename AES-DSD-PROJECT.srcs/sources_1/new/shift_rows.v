// AES ShiftRows Transformation
// Pure wire routing - no computation, zero LUT usage.
// State layout (128-bit, MSB-first):
//   Byte  0 = state[127:120] = s[0,0]  (row 0, col 0)
//   Byte  1 = state[119:112] = s[1,0]  (row 1, col 0)
//   Byte  2 = state[111:104] = s[2,0]  (row 2, col 0)
//   Byte  3 = state[103: 96] = s[3,0]  (row 3, col 0)
//   Byte  4 = state[ 95: 88] = s[0,1]  (row 0, col 1)
//   Byte  5 = state[ 87: 80] = s[1,1]  (row 1, col 1)
//   Byte  6 = state[ 79: 72] = s[2,1]  (row 2, col 1)
//   Byte  7 = state[ 71: 64] = s[3,1]  (row 3, col 1)
//   Byte  8 = state[ 63: 56] = s[0,2]  (row 0, col 2)
//   Byte  9 = state[ 55: 48] = s[1,2]  (row 1, col 2)
//   Byte 10 = state[ 47: 40] = s[2,2]  (row 2, col 2)
//   Byte 11 = state[ 39: 32] = s[3,2]  (row 3, col 2)
//   Byte 12 = state[ 31: 24] = s[0,3]  (row 0, col 3)
//   Byte 13 = state[ 23: 16] = s[1,3]  (row 1, col 3)
//   Byte 14 = state[ 15:  8] = s[2,3]  (row 2, col 3)
//   Byte 15 = state[  7:  0] = s[3,3]  (row 3, col 3)
//
// s'[r,c] = s[r, (c+r) mod 4]  (left circular shift of row r by r positions)

`timescale 1ns / 1ps

module shift_rows (
    input  [127:0] state_in,
    output [127:0] state_out
);
    // Row 0: no shift  s'[0,c] = s[0,c]
    assign state_out[127:120] = state_in[127:120]; // s[0,0]
    assign state_out[ 95: 88] = state_in[ 95: 88]; // s[0,1]
    assign state_out[ 63: 56] = state_in[ 63: 56]; // s[0,2]
    assign state_out[ 31: 24] = state_in[ 31: 24]; // s[0,3]

    // Row 1: shift left by 1  s'[1,c] = s[1,(c+1) mod 4]
    assign state_out[119:112] = state_in[ 87: 80]; // s'[1,0] = s[1,1]
    assign state_out[ 87: 80] = state_in[ 55: 48]; // s'[1,1] = s[1,2]
    assign state_out[ 55: 48] = state_in[ 23: 16]; // s'[1,2] = s[1,3]
    assign state_out[ 23: 16] = state_in[119:112]; // s'[1,3] = s[1,0]

    // Row 2: shift left by 2  s'[2,c] = s[2,(c+2) mod 4]
    assign state_out[111:104] = state_in[ 47: 40]; // s'[2,0] = s[2,2]
    assign state_out[ 79: 72] = state_in[ 15:  8]; // s'[2,1] = s[2,3]
    assign state_out[ 47: 40] = state_in[111:104]; // s'[2,2] = s[2,0]
    assign state_out[ 15:  8] = state_in[ 79: 72]; // s'[2,3] = s[2,1]

    // Row 3: shift left by 3  s'[3,c] = s[3,(c+3) mod 4]
    assign state_out[103: 96] = state_in[  7:  0]; // s'[3,0] = s[3,3]
    assign state_out[ 71: 64] = state_in[103: 96]; // s'[3,1] = s[3,0]
    assign state_out[ 39: 32] = state_in[ 71: 64]; // s'[3,2] = s[3,1]
    assign state_out[  7:  0] = state_in[ 39: 32]; // s'[3,3] = s[3,2]
endmodule
