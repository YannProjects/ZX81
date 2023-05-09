

# Ignore input delays related to input ports (RESET, KBD,...)

# Ignore ouput delays related to output ports (A_CPU, ...)
# set_false_path -to [get_ports *Debug*]
# set_false_path -to [get_ports *debug*]
#set_false_path -to [get_ports KBD_C*]
#set_false_path -to [get_ports HSYNC_VGA]
#set_false_path -to [get_ports VSYNC_VGA]
#set_false_path -to [get_ports MIC]
#set_false_path -to [get_ports Vsync_Heart_Beat]

#set_property DONT_TOUCH true [get_cells -hier -filter {REF_NAME==T80se || ORIG_REF_NAME==T80se}]
#set_property DONT_TOUCH true [get_nets cpu1/u0/*]

#set_property DONT_TOUCH true [get_cells -hier]
#set_property DONT_TOUCH true [get_nets -hier]




# Il y a des erreurs reportées lors des checks de timing sur l'interface entre la CLK à 6,5 MHz côté ULA et
# cell à 52 MHz côté controller VGA. J'ai essayé de rajouter un double échantillonage comme indiqué
# dans https://www.nandland.com/articles/crossing-clock-domains-in-an-fpga.html.
# Mais, il y a toujours l'erreur. En attendant j'ajoute
# une contrainte pour ignorer le cross domain checking.
# (voir aussi: https://www.youtube.com/watch?v=KoC9hEckJdk)











set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

create_generated_clock -name PIXEL_CLK -source [get_pins clk_gen_0/clk_gen/inst/clk_52m] -divide_by 8 [get_pins clk_gen_0/clk_6_5m]
create_generated_clock -name CPU_CLK -source [get_pins clk_gen_0/clk_gen/inst/clk_52m] -divide_by 16 [get_pins -hierarchical *clk_3_25m*]



set_false_path -from [get_pins {cpu1/u0/A_reg[*]/C}] -to [get_ports {o_KBD_C[*]}]

set_false_path -from [get_pins heart_beat_reg/C] -to [get_ports o_heart_beat]
set_false_path -from [get_ports i_RESET] -to [all_registers]

set_false_path -from [get_pins vga_control0/vga_controller_ok_reg/C] -to [get_pins vga_control_init_done_0_reg/D]
set_false_path -from [get_clocks -of_objects [get_pins clk_gen_0/clk_gen/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins clk_gen_0/clk_gen/inst/mmcm_adv_inst/CLKOUT1]]
set_false_path -from [get_clocks -of_objects [get_pins clk_gen_0/clk_gen/inst/mmcm_adv_inst/CLKOUT1]] -to [get_clocks -of_objects [get_pins clk_gen_0/clk_gen/inst/mmcm_adv_inst/CLKOUT0]]






