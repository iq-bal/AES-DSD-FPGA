// AES Encryption Round (combinatorial)
// Performs: SubBytes -> ShiftRows -> (optional MixColumns) -> AddRoundKey
// Set is_final_round=1 to skip MixColumns (round 10).
// All sub-modules are combinatorial; this module has zero registers.
// The state register lives in aes_top.

`timescale 1ns / 1ps

module aes_round (
    input  [127:0] state_in,
    input  [127:0] round_key,
    input          is_final_round,
    output [127:0] state_out
);
    wire [127:0] after_subbytes;
    wire [127:0] after_shiftrows;
    wire [127:0] after_mixcolumns;
    wire [127:0] pre_ark;

    // SubBytes: apply S-box to each of the 16 bytes in parallel
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : sbox_array
            sbox sbox_inst (
                .in (state_in[127 - 8*i -: 8]),
                .out(after_subbytes[127 - 8*i -: 8])
            );
        end
    endgenerate

    // ShiftRows: pure wire routing
    shift_rows sr_inst (
        .state_in (after_subbytes),
        .state_out(after_shiftrows)
    );

    // MixColumns: skip in final round
    mix_columns mc_inst (
        .state_in (after_shiftrows),
        .state_out(after_mixcolumns)
    );

    // MUX: bypass MixColumns in final round
    assign pre_ark = is_final_round ? after_shiftrows : after_mixcolumns;

    // AddRoundKey
    add_round_key ark_inst (
        .state_in (pre_ark),
        .round_key(round_key),
        .state_out(state_out)
    );

endmodule
