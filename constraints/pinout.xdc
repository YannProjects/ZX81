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
set_property IOSTANDARD LVCMOS33 [get_ports R_VGA_0]
set_property IOSTANDARD LVCMOS33 [get_ports R_VGA_1]
set_property IOSTANDARD LVCMOS33 [get_ports R_VGA_2]

set_property IOSTANDARD LVCMOS33 [get_ports G_VGA_0]
set_property IOSTANDARD LVCMOS33 [get_ports G_VGA_1]
set_property IOSTANDARD LVCMOS33 [get_ports G_VGA_2]

set_property IOSTANDARD LVCMOS33 [get_ports B_VGA_0]
set_property IOSTANDARD LVCMOS33 [get_ports B_VGA_1]
set_property IOSTANDARD LVCMOS33 [get_ports B_VGA_2]

set_property IOSTANDARD LVCMOS33 [get_ports HSYNC_VGA]
set_property IOSTANDARD LVCMOS33 [get_ports VSYNC_VGA]

# PIN 48
set_property PACKAGE_PIN A4 [get_ports R_VGA_0]
# PIN 47
set_property PACKAGE_PIN A3 [get_ports R_VGA_1]
# PIN 46
set_property PACKAGE_PIN B4 [get_ports R_VGA_2]

# PIN 45
set_property PACKAGE_PIN B3 [get_ports G_VGA_0]
# PIN 44
set_property PACKAGE_PIN C1 [get_ports G_VGA_1]
# PIN 43
set_property PACKAGE_PIN B1 [get_ports G_VGA_2]

# PIN 42
set_property PACKAGE_PIN B2 [get_ports B_VGA_0]
# PIN 41
set_property PACKAGE_PIN A2 [get_ports B_VGA_1]
# PIN 40
set_property PACKAGE_PIN C5 [get_ports B_VGA_2]

# PIN 30
set_property PACKAGE_PIN M13 [get_ports VSYNC_VGA]
# PIN 31
set_property PACKAGE_PIN J11 [get_ports HSYNC_VGA]

# Divers
#set_property IOSTANDARD LVCMOS33 [get_ports {Debug[0]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {Debug[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {Debug[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {Debug[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {Debug[4]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {Debug[5]}]
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
#set_property IOSTANDARD LVCMOS33 [get_ports Dbg(6)]
#set_property IOSTANDARD LVCMOS33 [get_ports Dbg(5)]
#set_property IOSTANDARD LVCMOS33 [get_ports Dbg(4)]
#set_property IOSTANDARD LVCMOS33 [get_ports Dbg(3)]
#set_property IOSTANDARD LVCMOS33 [get_ports Dbg(2)]
#set_property IOSTANDARD LVCMOS33 [get_ports Dbg(1)]
#set_property IOSTANDARD LVCMOS33 [get_ports Dbg(0)]

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

set_clock_groups -asynchronous -group [get_clocks CLK_52M] -group [get_clocks -of_objects [get_pins clk_gen_0/clk_divider_3/O]]

set_false_path -to [get_ports B_VGA_*]






connect_debug_port u_ila_0/probe3 [get_nets [list ula0/i_vid_ram_detect]]



create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 8192 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list clk_gen_0/clk_gen/inst/clk_52M]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 8 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {ula0/i_vga_line_counter_reg[5]} {ula0/i_vga_line_counter_reg[6]} {ula0/i_vga_line_counter_reg[7]} {ula0/i_vga_line_counter_reg[8]} {ula0/i_vga_line_counter_reg[9]} {ula0/i_vga_line_counter_reg[10]} {ula0/i_vga_line_counter_reg[11]} {ula0/i_vga_line_counter_reg[12]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 14 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {i_a_cpu[0]} {i_a_cpu[1]} {i_a_cpu[2]} {i_a_cpu[3]} {i_a_cpu[4]} {i_a_cpu[5]} {i_a_cpu[6]} {i_a_cpu[7]} {i_a_cpu[8]} {i_a_cpu[9]} {i_a_cpu[10]} {i_a_cpu[13]} {i_a_cpu[14]} {i_a_cpu[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 13 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {i_vga_addr[0]} {i_vga_addr[1]} {i_vga_addr[2]} {i_vga_addr[3]} {i_vga_addr[4]} {i_vga_addr[5]} {i_vga_addr[6]} {i_vga_addr[7]} {i_vga_addr[8]} {i_vga_addr[9]} {i_vga_addr[10]} {i_vga_addr[11]} {i_vga_addr[12]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 8 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {i_d_cpu_in[0]} {i_d_cpu_in[1]} {i_d_cpu_in[2]} {i_d_cpu_in[3]} {i_d_cpu_in[4]} {i_d_cpu_in[5]} {i_d_cpu_in[6]} {i_d_cpu_in[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 8 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {i_d_ram_out[0]} {i_d_ram_out[1]} {i_d_ram_out[2]} {i_d_ram_out[3]} {i_d_ram_out[4]} {i_d_ram_out[5]} {i_d_ram_out[6]} {i_d_ram_out[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 1 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list ula0/i_new_frame_start]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 1 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list i_vga_wr_cyc]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 1 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list ula0/i_vid_ram_detect]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 1 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list ula0/i_vsync]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets i_clk_52m]
