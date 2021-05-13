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
set_property IOSTANDARD LVCMOS33 [get_ports {Debug[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Debug[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Debug[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Debug[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Debug[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Debug[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports CLK_12M]
set_property IOSTANDARD LVCMOS33 [get_ports CSYNCn]
set_property IOSTANDARD LVCMOS33 [get_ports EAR]
set_property IOSTANDARD LVCMOS33 [get_ports MIC]
set_property IOSTANDARD LVCMOS33 [get_ports RESET]
set_property IOSTANDARD LVCMOS33 [get_ports Video]
set_property IOSTANDARD LVCMOS33 [get_ports Iorq_Heart_Beat]
set_property PACKAGE_PIN M9 [get_ports CLK_12M]
set_property PACKAGE_PIN M4 [get_ports {KBD_C[7]}]
set_property PACKAGE_PIN N1 [get_ports {KBD_C[0]}]
set_property PACKAGE_PIN M3 [get_ports {KBD_C[6]}]
set_property PACKAGE_PIN P1 [get_ports {KBD_C[1]}]
set_property PACKAGE_PIN N2 [get_ports {KBD_C[5]}]
set_property PACKAGE_PIN N3 [get_ports {KBD_C[2]}]
set_property PACKAGE_PIN M2 [get_ports {KBD_C[4]}]
set_property PACKAGE_PIN P3 [get_ports {KBD_C[3]}]
set_property PACKAGE_PIN P15 [get_ports {KBD_L[0]}]
set_property PACKAGE_PIN N15 [get_ports {KBD_L[1]}]
set_property PACKAGE_PIN N14 [get_ports {KBD_L[2]}]
set_property PACKAGE_PIN M15 [get_ports {KBD_L[3]}]
set_property PACKAGE_PIN M14 [get_ports {KBD_L[4]}]
set_property PACKAGE_PIN C1 [get_ports CSYNCn]
set_property PACKAGE_PIN B3 [get_ports EAR]
set_property PACKAGE_PIN A4 [get_ports MIC]
set_property PACKAGE_PIN A3 [get_ports Video]
set_property PACKAGE_PIN E2 [get_ports Iorq_Heart_Beat]
set_property PACKAGE_PIN D2 [get_ports RESET]

set_property PACKAGE_PIN L1 [get_ports {Debug[0]}]
set_property PACKAGE_PIN C5 [get_ports {Debug[1]}]
set_property PACKAGE_PIN B1 [get_ports {Debug[2]}]
set_property PACKAGE_PIN B4 [get_ports {Debug[3]}]
set_property PACKAGE_PIN B2 [get_ports {Debug[4]}]
set_property PACKAGE_PIN A2 [get_ports {Debug[5]}]

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

set_property PULLUP true [get_ports {KBD_L[4]}]
set_property PULLUP true [get_ports {KBD_L[3]}]
set_property PULLUP true [get_ports {KBD_L[2]}]
set_property PULLUP true [get_ports {KBD_L[1]}]
set_property PULLUP true [get_ports {KBD_L[0]}]
set_property PULLDOWN true [get_ports MIC]
