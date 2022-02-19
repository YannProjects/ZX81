#
#   27-11-2021: Suppression partie video composite
#

# Clavier
set_property IOSTANDARD LVCMOS33 [get_ports {KBD_C[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {KBD_C[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {KBD_C[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {KBD_C[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {KBD_C[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {KBD_C[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {KBD_C[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {KBD_C[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {KBD_L[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {KBD_L[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {KBD_L[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {KBD_L[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {KBD_L[0]}]

# PIN 1
set_property PACKAGE_PIN L1 [get_ports {KBD_C[0]}]
# PIN 2
set_property PACKAGE_PIN M4 [get_ports {KBD_C[1]}]
# PIN 3
set_property PACKAGE_PIN M3 [get_ports {KBD_C[2]}]
# PIN 4
set_property PACKAGE_PIN N2 [get_ports {KBD_C[3]}]
# PIN 5
set_property PACKAGE_PIN M2 [get_ports {KBD_C[4]}]
# PIN 6
set_property PACKAGE_PIN P3 [get_ports {KBD_C[5]}]
# PIN 7
set_property PACKAGE_PIN N3 [get_ports {KBD_C[6]}]
# PIN 8
set_property PACKAGE_PIN P1 [get_ports {KBD_C[7]}]

# PIN 9
set_property PACKAGE_PIN N1 [get_ports {KBD_L[0]}]
# PIN 16
set_property PACKAGE_PIN P14 [get_ports {KBD_L[1]}]
# PIN 17
set_property PACKAGE_PIN P15 [get_ports {KBD_L[2]}]
# PIN 18
set_property PACKAGE_PIN N13 [get_ports {KBD_L[3]}]
# PIN 19
set_property PACKAGE_PIN N15 [get_ports {KBD_L[4]}]

# Video VGA
set_property IOSTANDARD LVCMOS33 [get_ports {R_VGA_H[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {R_VGA_H[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {R_VGA_H[2]}]

set_property IOSTANDARD LVCMOS33 [get_ports {G_VGA_H[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {G_VGA_H[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {G_VGA_H[2]}]

set_property IOSTANDARD LVCMOS33 [get_ports {B_VGA_H[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {B_VGA_H[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {B_VGA_H[2]}]

set_property IOSTANDARD LVCMOS33 [get_ports HSYNC_VGA]
set_property IOSTANDARD LVCMOS33 [get_ports VSYNC_VGA]

# PIN 48
set_property PACKAGE_PIN A4 [get_ports {R_VGA_H[0]}]
# PIN 47
set_property PACKAGE_PIN A3 [get_ports {R_VGA_H[1]}]
# PIN 46
set_property PACKAGE_PIN B4 [get_ports {R_VGA_H[2]}]

# PIN 45
set_property PACKAGE_PIN B3 [get_ports {G_VGA_H[0]}]
# PIN 44
set_property PACKAGE_PIN C1 [get_ports {G_VGA_H[1]}]
# PIN 43
set_property PACKAGE_PIN B1 [get_ports {G_VGA_H[2]}]

# PIN 42
set_property PACKAGE_PIN B2 [get_ports {B_VGA_H[0]}]
# PIN 41
set_property PACKAGE_PIN A2 [get_ports {B_VGA_H[1]}]
# PIN 40
set_property PACKAGE_PIN C5 [get_ports {B_VGA_H[2]}]

# PIN 30
set_property PACKAGE_PIN M13 [get_ports VSYNC_VGA]
# PIN 31
set_property PACKAGE_PIN J11 [get_ports HSYNC_VGA]

# Divers
set_property IOSTANDARD LVCMOS33 [get_ports CLK_12M]
set_property IOSTANDARD LVCMOS33 [get_ports EAR]
set_property IOSTANDARD LVCMOS33 [get_ports MIC]
set_property IOSTANDARD LVCMOS33 [get_ports RESET]
set_property IOSTANDARD LVCMOS33 [get_ports PUSH_BUTTON]
set_property PULLDOWN true [get_ports MIC]
set_property IOSTANDARD LVCMOS33 [get_ports Iorq_Heart_Beat]

set_property PACKAGE_PIN M9 [get_ports CLK_12M]
# PIN 20
set_property PACKAGE_PIN N14 [get_ports EAR]
# PIN 21
set_property PACKAGE_PIN M15 [get_ports MIC]
set_property PACKAGE_PIN D1 [get_ports PUSH_BUTTON]
set_property PACKAGE_PIN D2 [get_ports RESET]
set_property PACKAGE_PIN E2 [get_ports Iorq_Heart_Beat]

# Debug
set_property IOSTANDARD LVCMOS33 [get_ports {Dbg[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Dbg[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Dbg[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Dbg[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Dbg[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Dbg[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Dbg[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Dbg[0]}]

set_property PACKAGE_PIN F4 [get_ports {Dbg[7]}]
set_property PACKAGE_PIN G1 [get_ports {Dbg[6]}]
set_property PACKAGE_PIN H1 [get_ports {Dbg[5]}]
set_property PACKAGE_PIN H3 [get_ports {Dbg[4]}]
set_property PACKAGE_PIN F3 [get_ports {Dbg[3]}]
set_property PACKAGE_PIN H4 [get_ports {Dbg[2]}]
set_property PACKAGE_PIN H2 [get_ports {Dbg[1]}]
set_property PACKAGE_PIN J2 [get_ports {Dbg[0]}]


set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

set_clock_groups -asynchronous -group [get_clocks CLK_52M] -group [get_clocks -of_objects [get_pins clk_gen_0/clk_divider_4/O]]

set_false_path -to [get_ports R_VGA_H*]
set_false_path -to [get_ports G_VGA_H*]
set_false_path -to [get_ports B_VGA_H*]


















set_clock_groups -asynchronous -group [get_clocks [list [get_clocks -of_objects [get_pins clk_gen_0/clk_divider_4/O]] [get_clocks -of_objects [get_pins clk_gen_0/clk_gen/inst/mmcm_adv_inst/CLKOUT2]]]] -group [get_clocks -of_objects [get_pins clk_gen_0/clk_gen/inst/mmcm_adv_inst/CLKOUT0]] -group [get_clocks -of_objects [get_pins clk_gen_0/clk_gen/inst/mmcm_adv_inst/CLKOUT1]]

set_clock_groups -asynchronous -group [get_clocks [list CLK_6_5M [get_clocks -of_objects [get_pins clk_gen_0/clk_divider_4/O]]]] -group [get_clocks CLK_52M] -group [get_clocks CLK_VGA]



set_false_path -from [get_clocks -of_objects [get_pins clk_gen_0/clk_divider_4/O]] -to [get_clocks CLK_6_5M]
