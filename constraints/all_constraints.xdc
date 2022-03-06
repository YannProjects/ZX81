

# Ignore input delays related to input ports (RESET, KBD,...)

# Ignore ouput delays related to output ports (A_CPU, ...)
# set_false_path -to [get_ports *Debug*]
# set_false_path -to [get_ports *debug*]
set_false_path -to [get_ports KBD_C*]
set_false_path -to [get_ports HSYNC_VGA]
set_false_path -to [get_ports VSYNC_VGA]
set_false_path -to [get_ports MIC]
set_false_path -to [get_ports Vsync_Heart_Beat]

#set_property DONT_TOUCH true [get_cells -hier -filter {REF_NAME==T80se || ORIG_REF_NAME==T80se}]
#set_property DONT_TOUCH true [get_nets cpu1/u0/*]

#set_property DONT_TOUCH true [get_cells -hier]
#set_property DONT_TOUCH true [get_nets -hier]




# Il y a des erreurs report�es lors des checks de timing sur l'interface entre la CLK � 6,5 MHz c�t� ULA et
# cell � 52 MHz c�t� controller VGA. J'ai essay� de rajouter un double �chantillonage comme indiqu�
# dans https://www.nandland.com/articles/crossing-clock-domains-in-an-fpga.html.
# Mais, il y a toujours l'erreur. En attendant j'ajoute
# une contrainte pour ignorer le cross domain checking.
# (voir aussi: https://www.youtube.com/watch?v=KoC9hEckJdk)



















