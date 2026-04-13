// AES Decryption Round (combinatorial)
// Decryption round order (equivalent inverse cipher):
//   InvShiftRows -> InvSubBytes -> AddRoundKey -> (optional InvMixColumns)
// Set is_final_round=1 to skip InvMixColumns (first decryption round = last key).

`timescale 1ns / 1ps

module aes_inv_round (
    input  [127:0] state_in,
    input  [127:0] round_key,
    input          is_final_round,
    output [127:0] state_out
);
    wire [127:0] after_inv_shiftrows;
    wire [127:0] after_inv_subbytes;
    wire [127:0] after_addroundkey;
    wire [127:0] after_inv_mixcolumns;

    // InvShiftRows: pure wire routing
    inv_shift_rows isr_inst (
        .state_in (state_in),
        .state_out(after_inv_shiftrows)
    );

    // InvSubBytes: apply inverse S-box to each of the 16 bytes in parallel
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : inv_sbox_array
            inv_sbox inv_sbox_inst (
                .in (after_inv_shiftrows[127 - 8*i -: 8]),
                .out(after_inv_subbytes[127 - 8*i -: 8])
            );
        end
    endgenerate

    // AddRoundKey
    add_round_key ark_inst (
        .state_in (after_inv_subbytes),
        .round_key(round_key),
        .state_out(after_addroundkey)
    );

    // InvMixColumns: skip in final round (round 0 key)
    inv_mix_columns imc_inst (
        .state_in (after_addroundkey),
        .state_out(after_inv_mixcolumns)
    );

    assign state_out = is_final_round ? after_addroundkey : after_inv_mixcolumns;

endmodule
