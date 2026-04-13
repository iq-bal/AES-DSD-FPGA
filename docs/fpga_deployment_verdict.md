# AES-128 FPGA Deployment Verdict

## ✅ What's Ready

| Component | Status | Notes |
|---|---|---|
| AES-128 Encryption Core | ✅ Verified | 4/4 NIST test vectors pass |
| Key Expansion | ✅ Working | Combinatorial, all 11 round keys |
| FSM Control Unit | ✅ Working | 12-cycle latency, 5-state FSM |
| Timing Constraints | ✅ Present | 100 MHz target clock |
| Target FPGA | ✅ Configured | xc7a35ticpg236-1L (Artix-7 35T) |

## ❌ What's Missing for Hardware

> [!CAUTION]
> **You CANNOT burn the current design to the board as-is.** Here's what's missing:

### 1. No Pin Assignments (Critical)
The `timing.xdc` has clock/timing constraints but **no physical pin mappings** (`set_property PACKAGE_PIN ...`). Vivado won't know which FPGA pins to connect `clk`, `rst`, `start`, `plaintext`, `cipher_key`, `ciphertext`, and `done` to.

### 2. The I/O Problem
Your AES core needs:
- **Inputs**: 128-bit plaintext + 128-bit key + clk + rst + start = **259 signals**
- **Outputs**: 128-bit ciphertext + done = **129 signals**

Your Basys 3 / equivalent Artix-7 board typically has:
- 16 switches, 5 buttons, 16 LEDs, 4-digit 7-segment display, UART (USB)

**You can't wire 259 input bits to 16 switches!** You need a wrapper/interface.

---

## 🎯 Demonstration Options (Pick One)

### Option A: UART Interface (Recommended ⭐)
**How it works**: Send plaintext + key from your PC via serial terminal → FPGA encrypts → sends ciphertext back to PC.

```
PC (Serial Terminal)  ←→  UART RX/TX  ←→  UART Wrapper  ←→  AES Core
```

**Pros**:
- Most impressive demo — live encryption of arbitrary data
- Teacher can type any plaintext/key and see the result
- Professional-looking (matches real AES hardware accelerators)

**Cons**:
- Requires writing a UART RX/TX module + controller (~200 lines of Verilog)
- Need a serial terminal app (PuTTY, Tera Term, or screen)

---

### Option B: Hardcoded Demo with LEDs + Button (Simplest ⭐)
**How it works**: Hardcode 2-3 known test vectors inside the FPGA. Use buttons to cycle through them. Show pass/fail on LEDs.

```
Button press → selects test vector → AES encrypts → 
compares with expected → green LED (pass) / red LED (fail)
```

**Pros**:
- Simplest to implement (~50 lines wrapper)
- No external tools needed
- Visual feedback on LEDs
- Can show on 7-segment display (partial ciphertext)

**Cons**:
- Less impressive — can only show pre-programmed vectors
- Teacher might ask "how do I know it's actually computing?"

---

### Option C: ILA (Integrated Logic Analyzer) — Vivado Built-in
**How it works**: Use Vivado's ILA IP core to probe internal AES signals in real-time from your laptop while connected to the board.

```
Vivado hardware manager → ILA → sees clk, state_reg, ciphertext, done in real-time
```

**Pros**:
- No extra Verilog code needed
- Can see all internal signals (state_reg, round_counter, etc.)
- Very educational — shows the FSM stepping through rounds

**Cons**:
- Still need some way to trigger encryption (button + hardcoded data)
- Requires Vivado open on laptop during demo
- Less "standalone" feeling

---

## 💡 My Recommendation

**Go with Option A (UART) if you have time**, or **Option B (Hardcoded + LEDs) if you need it fast**.

For a DSD course project, **Option B + Option C combined** is probably the sweet spot:
1. Hardcode NIST test vectors, use a button to trigger encryption
2. Show PASS/FAIL on LEDs + partial ciphertext on 7-segment
3. Open Vivado ILA to show teacher the internal FSM states stepping through rounds

This gives you: **visual proof on LEDs** + **deep internal verification via ILA** = convincing demo.

---

## 📋 What You Need to Tell Me

To proceed, I need to know:

1. **Which board exactly?** (Basys 3? Nexys A7? Arty A7? — determines pin mappings)
2. **Which demo option** do you want? (A, B, or C, or a combination?)
3. **Timeline** — when is the demo? (determines how complex we can go)
