// AES MixColumns Transformation - all 4 columns
// Instantiates 4 mix_column modules operating on columns in parallel.
// Column layout in 128-bit state:
//   Column 0: state[127:96]
//   Column 1: state[ 95:64]
//   Column 2: state[ 63:32]
//   Column 3: state[ 31: 0]

`timescale 1ns / 1ps

module mix_columns (
    input  [127:0] state_in,
    output [127:0] state_out
);
    mix_column mc0 (.col_in(state_in[127:96]), .col_out(state_out[127:96]));
    mix_column mc1 (.col_in(state_in[ 95:64]), .col_out(state_out[ 95:64]));
    mix_column mc2 (.col_in(state_in[ 63:32]), .col_out(state_out[ 63:32]));
    mix_column mc3 (.col_in(state_in[ 31: 0]), .col_out(state_out[ 31: 0]));
endmodule
