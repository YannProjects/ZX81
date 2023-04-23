----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.07.2020 17:24:25
-- Design Name: 
-- Module Name: ZX81_board - Behavioral
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
-- 27-11-2021: Suppression partie video composite pour ne garder que la partie VGA
----------------------------------------------------------------------------------


library IEEE;
library unisim;

use IEEE.STD_LOGIC_1164.ALL;
-- use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_arith.ALL;
use work.T80_Pack.all;
use work.VGA_control_pack.all;
use work.zx81_pack.all;
library UNISIM;
use UNISIM.VComponents.all;
use std.textio.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

entity ZX81_board is
    Port ( CLK_12M : in STD_LOGIC; -- Clock from CMOD S7
           -- Sortie "audio" ZX81 - Entrée "audio" PC
           o_MIC : out STD_LOGIC;
           i_RESET : in std_logic;
           i_KBD_L : in STD_LOGIC_vector (4 downto 0);
           o_KBD_C : out STD_LOGIC_vector (7 downto 0);
           -- Sortie "audio" PC - Entrée "audio" ZX81
           i_EAR : in STD_LOGIC;
           
           -- Video
           o_HSYNC_VGA : out STD_LOGIC;
           o_VSYNC_VGA : out STD_LOGIC;
           o_R_VGA_H : out std_logic_vector (2 downto 0);
           o_G_VGA_H : out std_logic_vector (2 downto 0);
           o_B_VGA_H : out std_logic_vector (2 downto 0);
           
           -- Signaux de debug
           -- Debug : out std_logic_vector(5 downto 0)
                      
           -- LEDs embarquées sur le CMOD S7
           -- LED_1 -> E2 : IORQn_Heart_Beat
           -- LED_2 -> K1 : Non utilisée
           -- LED_3 -> J1 : Non utilisée
           -- LED_4 -> E1 : Non utilisée
           o_heart_beat : out std_logic
         );
end ZX81_board;

architecture Behavioral of ZX81_board is   

    signal clk_52m, clk_3_25m, clk_6_5m, clk_13m : std_logic;
    
    -- Control signal
    signal waitn, nmin : std_logic := '1';
    signal m1n, mreqn, iorqn, tape_in : std_logic;
    signal rdn, wrn, wrram, rfrshn, haltn : std_logic;
    signal cpu_addr, mem_addr_char, mem_addr : std_logic_vector (15 downto 0);
    signal A_prim : std_logic_vector (8 downto 0);
    signal cpu_data_out, cpu_data_in, ram_data, rom_data : std_logic_vector (7 downto 0);
    signal ula_data, video_pattern_data : std_logic_vector (7 downto 0);
    signal cpu_resetn : std_logic;
    signal kbd_l_swap : std_logic_vector(4 downto 0);
    signal rom_csn, ram_csn, ula_csn : std_logic;
    signal vsync_0, vsync_1, vsync_heart_beat, vsync_frame_detect : std_logic;
    
    -- VGA
    signal vga_clock, pll_locked : std_logic;
    signal vga_addr: std_logic_vector(19 downto 0);
    signal vga_data: std_logic_vector(1 downto 0);
    signal vga_wr_cyc : std_logic;
    signal vga_control_init_done, vga_control_init_done_0 : std_logic;
    signal hsync, vsync, line_vid_data : std_logic;
    
    signal R_VGA, G_VGA, B_VGA : std_logic_vector(7 downto 0);
    signal BLANK_VGA : std_logic;
    signal i_hsync, i_vsync : std_logic;

    attribute ASYNC_REG : string;
    attribute ASYNC_REG of vga_control_init_done_0 : signal is "TRUE";
    
    -- RAM
    component blk_mem_gen_0 IS
    port (
         clka : IN STD_LOGIC;
         wea : IN STD_LOGIC;
         addra : IN STD_LOGIC_VECTOR(RAM_ADDRWIDTH-1 DOWNTO 0);
         dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
         douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
    end component;
       
    -- ROM
    component blk_mem_gen_1 IS
    port (
         clka : IN STD_LOGIC;
         addra : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
         douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
    end component;
    
    begin
        
    clk_gen_0 : entity work.Clocks_gen
    port map (
        main_clk => clk_12M,
        clk_52m => clk_52m,
        clk_3_25m => clk_3_25m,
        clk_6_5m => clk_6_5m,
        clk_13m => clk_13m,
        vga_clk => vga_clock,
        rst => i_reset,
        pll_locked => pll_locked
    );
    
    ---------------------------------------------------------------------
    -- Gestion du reset (resynchronisation avec une horloge pour éviter les
    -- métastabilités)
    ---------------------------------------------------------------------
    p_resync_vga_control_init : process(clk_3_25m)
    begin
        if rising_edge(clk_3_25m) then
            vga_control_init_done_0 <= vga_control_init_done;
        end if;
    end process;
    
    cpu_resetn <= not i_reset and pll_locked and vga_control_init_done_0;
         
    -- Instantiation Z80 basé sur la version MIST-devel (https://github.com/mist-devel/T80)
    cpu1 : entity work.T80se
    port map (
		RESET_n	=> cpu_resetn,
	 	CLK_n => clk_3_25m,
	 	CLKEN => '1',
	 	WAIT_n => waitn,
	 	INT_n => cpu_addr(6),
	 	NMI_n => nmin,
	 	BUSRQ_n => '1',
	 	M1_n => m1n,
	 	MREQ_n => mreqn,
	 	IORQ_n => iorqn,
	 	RD_n => rdn,
	 	WR_n => wrn,
	 	RFSH_n => rfrshn,
	 	HALT_n => haltn,
	 	A => cpu_addr,
	 	DI => cpu_data_in,
	 	DO => cpu_data_out
    );

    ula0 : entity work.ULA
    port map ( 
        i_resetn => cpu_resetn,
        i_clk_3_25_m => clk_3_25m,
        i_clk_6_5_m => clk_6_5m,
        
        i_A => cpu_addr,
        o_Ap => A_prim,
        i_video_pattern => video_pattern_data,
        o_ula_data => ula_data, 
        i_kbdn => kbd_l_swap,
        i_tape_in => tape_in,
        i_usa_uk => '0',
        o_tape_out => o_MIC,
        o_ram_csn => ram_csn,
        o_rom_csn => rom_csn,
        o_ulan => ula_csn,
        
        i_rdn => rdn,
        i_wrn => wrn,
        i_haltn => haltn,
        i_iorqn => iorqn,
        i_mreqn => mreqn,
        i_m1n => m1n,
        i_rfshn => rfrshn,
        o_waitn => waitn,
        o_nmin => nmin,
        
        o_vsync => vsync,
        o_hsync => hsync,
        o_video_data => line_vid_data
    );
    
    p_write_pattern : process(clk_6_5m)
        file outfile : text open write_mode is "C:\Users\yannv\Documents\Projets_HW\ZX81\test_patterns\VGA_test_pattern.txt";
        variable test_pattern : line;  
    begin    
        if rising_edge(clk_6_5m) then
            write(test_pattern, std_logic'image(vsync) & " " & std_logic'image(hsync) & " " & std_logic'image(line_vid_data), right, 1);
            writeline(outfile, test_pattern);
        end if;
    end process;         
    
    mem_addr <= mem_addr_char when (cpu_addr(14) = '0' and rfrshn = '0') else cpu_addr;
    mem_addr_char <= cpu_addr(15 downto 9) & A_prim;
    -- Char address in RAM or video pattern in ROM
    video_pattern_data <= rom_data when (cpu_addr(14) = '0' and rfrshn = '0') else ram_data;
    
    p_cpu_data_select : process(ram_csn, rom_csn, ula_csn, ram_data, rom_data, ula_data)
    begin
        if ula_csn = '0' then
            cpu_data_in <= ula_data;
        elsif rom_csn = '0' then
            cpu_data_in <= rom_data;
        elsif ram_csn = '0' then
            cpu_data_in <= ram_data;
        else
            cpu_data_in <= (others => 'X');
        end if;
    end process;
    
    -- ROM du ZX81
    rom0 : blk_mem_gen_1
    port map (
        clka => clk_3_25m,
        addra => mem_addr (12 downto 0),
        douta => rom_data
    );

    ram1 : blk_mem_gen_0
    port map (
       clka => clk_3_25m,
       addra => mem_addr(RAM_ADDRWIDTH - 1 downto 0),
       dina => cpu_data_out,
       douta => ram_data,       
       wea => wrram
    );
    
    vga_control0 : entity work.vga_control_top
    port map (
        i_RESET => i_RESET,
        i_CLK_52M => clk_52m,
        i_CLK_6_5M => clk_6_5m,
        i_VGA_CLK => vga_clock,
        i_ula_vid_data => line_vid_data,
        o_VGA_CONTROL_INIT_DONE => vga_control_init_done,
        i_ula_hsync => hsync,
        i_ula_vsync => vsync,
        o_R => R_VGA,
        o_G => G_VGA,
        o_B => B_VGA
    );
    
    -- Ajout d'une condition sur le signal WR Ram suite au problème rencontré sur l'instruction en L1A14 (LD      (DE),A)
    -- avec DE qui vaut 0. Je ne sais pas pourquoi vaut 0 dans ce cas. Mais, on reproduit le problème avec MAME.
    -- => Ajout de la condition sur A14 pour valider l'écriture en RAM.
    wrram <= '1' when (wrn = '0' and mreqn = '0' and cpu_addr(14) = '1' and cpu_addr(15) = '0') else '0';    

    -- Les 5 lignes du clavier
    o_KBD_C <= cpu_addr(15 downto 8);

    tape_in <= i_EAR;
    
    -- On ne garde que 3 bits sur les 8
    o_R_VGA_H(2 downto 0) <= R_VGA(7 downto 5) when BLANK_VGA = '0' else "000";
    o_G_VGA_H(2 downto 0) <= G_VGA(7 downto 5) when BLANK_VGA = '0' else "000";
    o_B_VGA_H(2 downto 0) <= B_VGA(7 downto 5) when BLANK_VGA = '0' else "000";
    
    o_HSYNC_VGA <= i_hsync;
    o_VSYNC_VGA <= i_vsync;
    
    kbd_l_swap <= i_KBD_L;

-----------------------------------------------------
-- Process pour le heart beat (allumage LED)
-----------------------------------------------------
p_vsync_hb : process (i_RESET, clk_3_25m, IORQn)

variable i_vsync_counter : integer;
variable i_heart_beat : std_logic;

begin
    if (i_RESET = '0') then
        i_heart_beat := '0';
        i_vsync_counter := VSYNC_COUNTER_PERIOD;
    -- Sur chaque front descendant de l'horloge 6.5 MHz
    elsif rising_edge(clk_3_25m) then
        vsync_0 <= vsync_frame_detect;
        vsync_1 <= vsync_0;
        -- Compteur de heart beat pour faire clignoter la LED sur le CMOD S7. 
        -- Détection transtion 1 -> 0
        if vsync_1 = '1' and vsync_0 = '0' then
            i_vsync_counter := i_vsync_counter - 1;
            if  i_vsync_counter = 0 then
                i_vsync_counter := VSYNC_COUNTER_PERIOD;
                i_heart_beat := not i_heart_beat;
            end if;
        end if;
    end if;
    
    vsync_heart_beat <= i_heart_beat;
    
end process;

end Behavioral;
