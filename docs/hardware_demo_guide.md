# AES-128 FPGA Hardware Demonstration Guide

This guide outlines exactly how to demonstrate your AES-128 FPGA hardware integration to your professor or instructor using a Basys 3 board. It proves that your design not only simulates correctly but also processes data physically in real-time hardware, supporting both Encryption and Decryption!

## Phase 1: Programming the Board

Because you've integrated a UART interface, your top module is now `uart_aes_top`. First, burn the project onto the FPGA:

1. **Pull the Latest Code**: Make sure the Windows machine connected to the board has pulled the latest code from GitHub (which contains the UART, XDC, and decryption updates).
2. **Open Vivado**: Open `AES-DSD-PROJECT.xpr`.
3. **Generate Bitstream**: Click **Generate Bitstream** in the Flow Navigator. Wait for the synthesis, implementation, and bitstream generation to complete.
4. **Connect Hardware**: Plug in the Basys 3 board to the computer via USB and turn on the power switch.
5. **Program**: Click **Open Hardware Manager** > **Open Target** > **Auto Connect**. Finally, click **Program Device**. 

The "DONE" LED on the board should light up green, indicating your logic is loaded.

> **Note on Critical Warnings**: If Vivado warns you about "Timing Violations" (WNS negative slack) or 10 Critical Warnings regarding undefined ports, completely ignore them! The combinatorial key expansion looks slow to Vivado, but the architectural pipelining guarantees it resolves fast enough for the class demo.

---

## Phase 2: Terminal Setup (PuTTY)

Your FPGA acts as a serial device that receives keys/text and returns encrypted/decrypted text. You must interact with it using a terminal emulator like PuTTY.

1. **Find the COM Port**: Open "Device Manager" in Windows and expand **Ports (COM & LPT)**. Note the COM port number (e.g., `COM8`) next to "USB Serial Port."
2. **Open PuTTY**: 
3. **Configure the Connection**:
   - In the main **Session** category, click the **Serial** radio button.
   - Set **Serial line** to your COM port (e.g. `COM8`).
   - Set **Speed** to `115200`.
   - Before clicking Open, navigate to **Connection -> Serial** on the left menu.
   - **CRITICAL:** Change the **Flow control** dropdown to **None**. *(If this is left on XON/XOFF, it will lock up and nothing will happen).*
4. Click **Open**.

You will see a completely blank black terminal. The board is now waiting for exactly 64 characters (32 for the 128-bit Key, followed immediately by 32 for the 128-bit Plaintext block).

---

## Phase 3: The Live Demo Execution

Once connected, your FPGA is actively waiting for input. You can identify the state of the hardware in real time via the onboard LEDs and control the cipher direction via the board switches.

### Hardware UI Controls:
- **Center Button (`U18`)**: Hardware Reset (Forces the state machine and UART receiver to abort and return to `IDLE`). Use this if you make a typo and need to clear the board's memory buffer.
- **Switch 0 (`V17`, Right-most Switch)**: Controls cipher direction.
  - **DOWN**: Encryption Mode
  - **UP**: Decryption Mode
- **LED 0 (Right-most LED)**: ON = Constantly listening for UART data. It means the board is ready to receive text!

### 1. Show Encryption 

Tell your instructor you are feeding it the official NIST FIPS-197 App B test vector. 
*   **Action**: Ensure **Switch 0 is DOWN**.
*   **Action**: Copy the following 64-character payload:
    ```text
    2B7E151628AED2A6ABF7158809CF4F3C3243F6A8885A308D313198A2E0370734
    ```
*   **Action**: Right-click anywhere in the black PuTTY window to instantly paste the string. 
*   **Result**: Instantly, the FPGA receives the text, performs 10 rounds of encryption mathematically, and prints this response:
    ```text
    3925841d02dc09fbdc118597196a0b32
    ```
This ciphertext perfectly matches the FIPS-197 standard.

### 2. Show Decryption

Now, blow them away by taking that exact ciphertext and sending it backwards through the hardware.
*   **Action**: Flip **Switch 0 UP**.
*   **Action**: Copy the following payload (This has the same key, but the data block is the ciphertext we just received!):
    ```text
    2B7E151628AED2A6ABF7158809CF4F3C3925841d02dc09fbdc118597196a0b32
    ```
*   **Action**: Right-click to paste into the PuTTY window again.
*   **Result**: The FPGA instantly grabs the round keys in reverse, drives the data through the `aes_inv_round` combinational logic path, and spits out the original plaintext!
    ```text
    3243f6a8885a308d313198a2e0370734
    ```

### Optional Troubleshooting during Demo
If the board stops responding to pasted text:
1. Ensure you copied exactly 64 characters (no accidental trailing spaces or missing letters).
2. Press the Center Button on the Basys 3 board to flush the buffer (LED 0 will turn back on).
3. Try pasting again. If PuTTY itself is locked due to Vivado Hardware Manager colliding on the COM port, close Vivado, restart PuTTY, and try again.
