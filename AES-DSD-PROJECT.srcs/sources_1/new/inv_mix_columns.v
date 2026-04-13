// AES Inverse MixColumns Transformation - all 4 columns

`timescale 1ns / 1ps

module inv_mix_columns (
    input  [127:0] state_in,
    output [127:0] state_out
);
    inv_mix_column imc0 (.col_in(state_in[127:96]), .col_out(state_out[127:96]));
    inv_mix_column imc1 (.col_in(state_in[ 95:64]), .col_out(state_out[ 95:64]));
    inv_mix_column imc2 (.col_in(state_in[ 63:32]), .col_out(state_out[ 63:32]));
    inv_mix_column imc3 (.col_in(state_in[ 31: 0]), .col_out(state_out[ 31: 0]));
endmodule
