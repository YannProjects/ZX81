

# Ignore input delays related to input ports (RESET, KBD,...)

# Ignore ouput delays related to output ports (A_CPU, ...)
# set_false_path -to [get_ports *Debug*]
# set_false_path -to [get_ports *debug*]
set_false_path -to [get_ports KBD_C*]
set_false_path -to [get_ports HSYNC_VGA]
set_false_path -to [get_ports VSYNC_VGA]
set_false_path -to [get_ports MIC]
set_false_path -to [get_ports Iorq_Heart_Beat]

#set_property DONT_TOUCH true [get_cells -hier -filter {REF_NAME==T80se || ORIG_REF_NAME==T80se}]
#set_property DONT_TOUCH true [get_nets cpu1/u0/*]

#set_property DONT_TOUCH true [get_cells -hier]
#set_property DONT_TOUCH true [get_nets -hier]


create_clock -period 19.231 -name CLK_52M -waveform {0.000 9.616} -add [get_pins clk_gen_0/clk_52m]
create_clock -period 39.702 -name CLK_VGA -waveform {0.000 19.851} -add [get_pins clk_gen_0/vga_clk]
create_clock -period 154.850 -name CLK_6_5M -waveform {0.000 76.920} -add [get_pins clk_gen_0/clk_6_5m]
create_generated_clock -name i_clk_3_25m -source [get_pins clk_gen_0/clk_divider_4/I] -divide_by 2 [get_pins -hierarchical *CLK_6_5_M*]

set_clock_groups -asynchronous -group [get_clocks CLK_52M] -group [get_clocks CLK_VGA] -group {[get_clocks CLK_6_5M ] [get_clocks i_clk_3_25m ]}

# Il y a des erreurs reportées lors des checks de timing sur l'interface entre la CLK à 6,5 MHz côté ULA et
# cell à 52 MHz côté controller VGA. J'ai essayé de rajouter un double échantillonage comme indiqué
# dans https://www.nandland.com/articles/crossing-clock-domains-in-an-fpga.html.
# Mais, il y a toujours l'erreur. En attendant j'ajoute
# une contrainte pour ignorer le cross domain checking.
# (voir aussi: https://www.youtube.com/watch?v=KoC9hEckJdk)










