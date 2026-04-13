## AES-128 Timing Constraints
## Target: Xilinx Artix-7 XC7A35T (xc7a35ticpg236-1L)
## Clock: 100 MHz system clock
##
## Critical path: combinatorial key expansion (10 chained S-box stages)
## and the round datapath (SubBytes->ShiftRows->MixColumns->AddRoundKey).
## The 100 MHz (10 ns) target provides sufficient margin for Artix-7 speed grade -1L.

# Primary clock constraint — create on the top-level clk port
create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]

# Input setup/hold timing relative to clk
# plaintext and cipher_key must be stable before start is sampled
set_input_delay -clock clk -max 2.000 [get_ports {plaintext[*]}]
set_input_delay -clock clk -min 0.500 [get_ports {plaintext[*]}]

set_input_delay -clock clk -max 2.000 [get_ports {cipher_key[*]}]
set_input_delay -clock clk -min 0.500 [get_ports {cipher_key[*]}]

set_input_delay -clock clk -max 2.000 [get_ports start]
set_input_delay -clock clk -min 0.500 [get_ports start]

set_input_delay -clock clk -max 2.000 [get_ports rst]
set_input_delay -clock clk -min 0.500 [get_ports rst]

# Output timing: ciphertext and done are registered outputs, 2 ns setup margin
set_output_delay -clock clk -max 2.000 [get_ports {ciphertext[*]}]
set_output_delay -clock clk -min 0.500 [get_ports {ciphertext[*]}]

set_output_delay -clock clk -max 2.000 [get_ports done]
set_output_delay -clock clk -min 0.500 [get_ports done]

# False path on async reset (synchronous reset is registered; no combinatorial path needed)
# set_false_path -from [get_ports rst]

# Clock uncertainty (jitter + skew budget for -1L grade Artix-7)
set_clock_uncertainty 0.200 [get_clocks clk]
