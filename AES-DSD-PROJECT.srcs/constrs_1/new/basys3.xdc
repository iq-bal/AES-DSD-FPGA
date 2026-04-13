## Clock signal (100 MHz)
set_property -dict { PACKAGE_PIN W5   IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## Buttons (Center Button for reset)
set_property -dict { PACKAGE_PIN U18  IOSTANDARD LVCMOS33 } [get_ports rst]

## Switches
set_property -dict { PACKAGE_PIN V17  IOSTANDARD LVCMOS33 } [get_ports decrypt_mode_switch]

## Status LEDs
set_property -dict { PACKAGE_PIN U16  IOSTANDARD LVCMOS33 } [get_ports {led[0]}]
set_property -dict { PACKAGE_PIN E19  IOSTANDARD LVCMOS33 } [get_ports {led[1]}]
set_property -dict { PACKAGE_PIN U19  IOSTANDARD LVCMOS33 } [get_ports {led[2]}]

## USB-RS232 Interface (UART)
set_property -dict { PACKAGE_PIN B18  IOSTANDARD LVCMOS33 } [get_ports uart_rx]
set_property -dict { PACKAGE_PIN A18  IOSTANDARD LVCMOS33 } [get_ports uart_tx]

## Configuration Details
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
