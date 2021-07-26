----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.07.2020 18:21:23
-- Design Name: 
-- Module Name: Z81_board_sim - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library ieee;
library STD;
library work;
use IEEE.STD_LOGIC_1164.ALL;
use STD.textio.all;
use ieee.std_logic_textio.all;
use work.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Z81_board_sim is
--  Port ( );
end Z81_board_sim;

architecture Behavioral of Z81_board_sim is

constant clk_period : time := 83 ns;
constant micin_simu_start_time : time := 1000 ms;
constant vector_file_name :string := "D:\Users\Yann\Documents\Projets_HW\ZX81\Traces oscilloscope\Fichier .P en audio\cHARGEMENT_FICHIER_";

signal i_board_reset, i_ear, i_video, i_main_clk, i_csyncn : std_logic;
signal i_kbd_l : std_logic_vector (4 downto 0);
signal i_debug : std_logic_vector (5 downto 0);
signal i_kbd_c : std_logic_vector (7 downto 0);
signal i_mic_in : std_logic := '1';
signal i_hsync_vga, i_vsync_vga, i_blank_vga : std_logic;
-- signal i_r_vga, i_g_vga, i_b_vga : std_logic_vector(7 downto 0);

begin
   
   ZX81_board0: entity work.ZX81_board
   port map (
       CLK_12M => i_main_clk,
       MIC => i_mic_in,
       RESET => i_board_reset,
       KBD_L => i_kbd_l,
       KBD_C => i_kbd_c,
       EAR => i_ear,
       Video => i_video,
       CSYNCn => i_csyncn,
       -- Debug => i_debug,
       HSYNC_VGA => i_hsync_vga,
       VSYNC_VGA => i_vsync_vga,
       BLANK_VGA => i_blank_vga
       -- R_VGA => i_r_vga,
       -- G_VGA => i_g_vga,
       -- B_VGA => i_b_vga

   );
   
   i_board_reset <= '0', '1' after 100 ns, '0' after 100 us;

   -- 13 MHz CLK
   clk_process :process
   begin
        i_main_clk <= '0';
        wait for clk_period / 2;
        i_main_clk <= '1';
        wait for clk_period / 2;
   end process;
   
   simu_micin: process
   variable start_simu_micin : time := now;
   variable absolute_time_prev, absolute_time : time;
   variable new_file_start_time : time := 0 ms;
   file file_VECTORS : text;
   variable absolute_time_real : real;
   variable void_1 : real;
   variable void_2, file_num_char : character;
   variable micin_state: std_logic := '0';
   variable v_ILINE : line;
   variable input_file_name : string(1 to (vector_file_name'length + 6));
   type file_name_extension is array (0 to 16) of string(1 to 2);
   variable extensions : file_name_extension := ("01", "02", "03", 
                                                 "04", "05", "06", "07",
                                                 "08", "09", "10", "11",
                                                 "12", "13", "14", "15",
                                                 "16", "17");
   begin
      wait for micin_simu_start_time;
      
      for file_num in 0 to 16 loop
        input_file_name := vector_file_name & extensions(file_num) & ".csv";
        file_open(file_VECTORS, input_file_name,  read_mode);
      
        -- Saute les 3 premières lignes
        readline(file_VECTORS, v_ILINE);
        readline(file_VECTORS, v_ILINE);
        readline(file_VECTORS, v_ILINE);
        readline(file_VECTORS, v_ILINE);
        read(v_ILINE, absolute_time_real);
        read(v_ILINE, void_2);
        read(v_ILINE, void_1);
        read(v_ILINE, void_2);
        read(v_ILINE, micin_state);
        absolute_time_prev := new_file_start_time + absolute_time_real * 1 ms;
      
        while not endfile(file_VECTORS) loop
          readline(file_VECTORS, v_ILINE);
          read(v_ILINE, absolute_time_real);
          read(v_ILINE, void_2);
          read(v_ILINE, void_1);
          read(v_ILINE, void_2);
          read(v_ILINE, micin_state);
        
          absolute_time := new_file_start_time + absolute_time_real * 1ms;
          wait for (absolute_time - absolute_time_prev);
          absolute_time_prev := absolute_time;
          i_mic_in <= not micin_state;
        end loop;
        new_file_start_time := absolute_time;
        
        file_close(file_VECTORS);
  end loop;
        
   end process;
   
   simu_clavier: process(i_kbd_c) 
   variable start_simu_time : time := now;   
   begin
        -- Si 18-15 = 0xFFFE ou 0xFFF7, on retourne 0x1E pour simuler l'appui sift + 0 (RUBOUT) qui ne fonctionne pas
        -- sur la cible...
        -- KBD_C => A15 A14 A13 A12 A11 A10 A9 A8
        -- KDB_L => KBD0 KBD1 KBD2 KBD3 KBD4
        -- J (=LOAD)  
        if ((i_kbd_c = B"10111111") and ((now - start_simu_time) > 300 ms and (now - start_simu_time) < 350 ms)) then
            i_kbd_l <= B"11101";
        -- " (SHIFT)
        elsif (((i_kbd_c = B"11111110")) and ((now - start_simu_time) > 400 ms and (now - start_simu_time) < 450 ms)) then
            i_kbd_l <= B"01111";
        -- " (SHIFT + P)
        elsif (((i_kbd_c = B"11011111") or (i_kbd_c = B"11111110")) and ((now - start_simu_time) > 500 ms and (now - start_simu_time) < 550 ms)) then
            i_kbd_l <= B"01111";
        -- " (SHIFT)
        elsif (((i_kbd_c = B"11111110")) and ((now - start_simu_time) > 600 ms and (now - start_simu_time) < 650 ms)) then
            i_kbd_l <= B"01111";                        
        -- " (SHIFT + P)
        elsif (((i_kbd_c = B"11011111") or (i_kbd_c = B"11111110")) and ((now - start_simu_time) > 700 ms and (now - start_simu_time) < 750 ms)) then
            i_kbd_l <= B"01111";
        -- N/L
        elsif ((i_kbd_c = B"10111111") and ((now - start_simu_time) > 900 ms and (now - start_simu_time) < 1000 ms)) then
            i_kbd_l <= B"01111";
        else
            i_kbd_l <= B"11111";
        end if;
   end process;	
   
end Behavioral;
