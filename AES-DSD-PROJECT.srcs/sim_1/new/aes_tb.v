// AES-128 Testbench
// Verifies the aes_top module against NIST FIPS 197 test vectors.
//
// Test vector 1 (FIPS 197 Appendix B):
//   Plaintext  : 3243f6a8885a308d313198a2e0370734
//   Key        : 2b7e151628aed2a6abf7158809cf4f3c
//   Ciphertext : 3925841d02dc09fbdc118597196a0b32
//
// Test vector 2 (FIPS 197 Appendix C.1):
//   Plaintext  : 00112233445566778899aabbccddeeff
//   Key        : 000102030405060708090a0b0c0d0e0f
//   Ciphertext : 69c4e0d86a7b0430d8cdb78070b4c55a
//
// Test vector 3 (all-zero):
//   Plaintext  : 00000000000000000000000000000000
//   Key        : 00000000000000000000000000000000
//   Ciphertext : 66e94bd4ef8a2c3b884cfa59ca342b2e

`timescale 1ns / 1ps

module aes_tb;
    // -------------------------------------------------------------------------
    // DUT signals
    // -------------------------------------------------------------------------
    reg         clk;
    reg         rst;
    reg         start;
    reg         decrypt;
    reg  [127:0] plaintext;
    reg  [127:0] cipher_key;
    wire [127:0] ciphertext;
    wire         done;

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    aes_top dut (
        .clk        (clk),
        .rst        (rst),
        .start      (start),
        .decrypt    (decrypt),
        .plaintext  (plaintext),
        .cipher_key (cipher_key),
        .ciphertext (ciphertext),
        .done       (done)
    );

    // -------------------------------------------------------------------------
    // Clock generation: 100 MHz (10 ns period)
    // -------------------------------------------------------------------------
    initial clk = 1'b0;
    always  #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // Task: run one encryption and check result
    // -------------------------------------------------------------------------
    integer pass_count;
    integer fail_count;

    task run_test;
        input [127:0] pt;
        input [127:0] key;
        input [127:0] expected_ct;
        input [127:0] test_num;
        begin
            // Apply inputs
            @(negedge clk);
            plaintext  = pt;
            cipher_key = key;
            start      = 1'b1;
            @(negedge clk);
            start      = 1'b0;

            // Wait for done
            wait (done == 1'b1);
            @(negedge clk); // let ciphertext latch

            // Check result
            if (ciphertext === expected_ct) begin
                $display("[PASS] Test %0d: ciphertext = %h", test_num, ciphertext);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d:", test_num);
                $display("       Expected  : %h", expected_ct);
                $display("       Got       : %h", ciphertext);
                fail_count = fail_count + 1;
            end

            // Wait a few cycles before next test
            repeat(5) @(posedge clk);
        end
    endtask

    // -------------------------------------------------------------------------
    // Test sequence
    // -------------------------------------------------------------------------
    initial begin
        // Initialise
        rst        = 1'b1;
        start      = 1'b0;
        decrypt    = 1'b0;
        plaintext  = 128'b0;
        cipher_key = 128'b0;
        pass_count = 0;
        fail_count = 0;

        // Hold reset for 4 clock cycles
        repeat(4) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;
        repeat(2) @(posedge clk);

        // -----------------------------------------------------------------
        // Test 1: FIPS 197 Appendix B
        // -----------------------------------------------------------------
        run_test(
            128'h3243f6a8885a308d313198a2e0370734,
            128'h2b7e151628aed2a6abf7158809cf4f3c,
            128'h3925841d02dc09fbdc118597196a0b32,
            1
        );

        // -----------------------------------------------------------------
        // Test 2: FIPS 197 Appendix C.1
        // -----------------------------------------------------------------
        run_test(
            128'h00112233445566778899aabbccddeeff,
            128'h000102030405060708090a0b0c0d0e0f,
            128'h69c4e0d86a7b0430d8cdb78070b4c55a,
            2
        );

        // -----------------------------------------------------------------
        // Test 3: All-zero plaintext and key
        // -----------------------------------------------------------------
        run_test(
            128'h00000000000000000000000000000000,
            128'h00000000000000000000000000000000,
            128'h66e94bd4ef8a2c3b884cfa59ca342b2e,
            3
        );

        // -----------------------------------------------------------------
        // Test 4: All-ones plaintext and key
        // -----------------------------------------------------------------
        run_test(
            128'hffffffffffffffffffffffffffffffff,
            128'hffffffffffffffffffffffffffffffff,
            128'hbcbf217cb280cf30b2517052193ab979,
            4
        );

        // -----------------------------------------------------------------
        // Test 5: Decryption of Test 1 (FIPS 197 App B)
        // -----------------------------------------------------------------
        decrypt = 1'b1;
        run_test(
            128'h3925841d02dc09fbdc118597196a0b32, // Ciphertext from Test 1
            128'h2b7e151628aed2a6abf7158809cf4f3c, // Key
            128'h3243f6a8885a308d313198a2e0370734, // Expected resulting Plaintext
            5
        );
        decrypt = 1'b0;

        // -----------------------------------------------------------------
        // Summary
        // -----------------------------------------------------------------
        $display("-------------------------------------");
        $display("Results: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");
        $display("-------------------------------------");

        // Waveform dumping already declared below; just finish
        #50 $finish;
    end

    // -------------------------------------------------------------------------
    // Waveform dump for GTKWave / Vivado simulator
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("aes_sim.vcd");
        $dumpvars(0, aes_tb);
    end

endmodule
