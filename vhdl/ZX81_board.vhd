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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

entity ZX81_board is
    Port ( CLK_12M : in STD_LOGIC; -- Clock from CMOD S7
           -- Sortie "audio" ZX81 - Entrée "audio" PC
           MIC : out STD_LOGIC;
           RESET : in std_logic;
           PUSH_BUTTON : in std_logic;
           KBD_L : in STD_LOGIC_vector (4 downto 0);
           KBD_C : out STD_LOGIC_vector (7 downto 0);
           -- Sortie "audio" PC - Entrée "audio" ZX81
           EAR : in STD_LOGIC;
           HSYNC_VGA : out STD_LOGIC;
           VSYNC_VGA : out STD_LOGIC;
           
           R_VGA_H : out std_logic_vector (2 downto 0);
           G_VGA_H : out std_logic_vector (2 downto 0);
           B_VGA_H : out std_logic_vector (2 downto 0);
           
           -- Signaux de debug
           -- Debug : out std_logic_vector(5 downto 0)
                      
           -- LEDs embarquées sur le CMOD S7
           -- LED_1 -> E2 : IORQn_Heart_Beat
           -- LED_2 -> K1 : Non utilisée
           -- LED_3 -> J1 : Non utilisée
           -- LED_4 -> E1 : Non utilisée
           Vsync_Heart_Beat : out std_logic;
           
           Dbg : out std_logic_vector(7 downto 0)
          
         );
end ZX81_board;

architecture Behavioral of ZX81_board is

    component blk_mem_gen_0 IS
      PORT (
        clka : IN STD_LOGIC;
        wea : IN STD_LOGIC;
        addra : IN STD_LOGIC_VECTOR(RAM_ADDRWIDTH-1 DOWNTO 0);
        dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
      );
    end component;     
     
    component blk_mem_gen_1 IS
      PORT (
        clka : IN STD_LOGIC;
        addra : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
        douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
      );
    end component;     
    
    -- Control signal
    signal waitn, nmin : std_logic := '1';
    signal m1n, mreqn, iorqn, tape_in : std_logic;
    signal rdn, wrn, wrram, rfrshn, haltn, video_pattern_select : std_logic;
    signal a_cpu, a_vid_pattern, addr : std_logic_vector (15 downto 0);
    signal d_cpu_out, d_cpu_in, d_ram_out, d_rom_out : std_logic_vector (7 downto 0);
    signal clk_52m, clk_3_25m, clk_6_5m, clk_13m : std_logic;
    signal resetn : std_logic;
    signal kbd_l_swap : std_logic_vector(4 downto 0);
    -- VGA
    signal vga_clock, pll_locked : std_logic;
    signal vga_addr: std_logic_vector(17 downto 0);
    signal vga_data: std_logic_vector(1 downto 0);
    signal vga_wr_cyc : std_logic;
    signal vga_control_init_done, vga_control_init_done_0, vga_control_init_done_1 : std_logic;
    
    signal R_VGA, G_VGA, B_VGA : std_logic_vector(7 downto 0);
    signal BLANK_VGA : std_logic;
    signal hsync, vsync : std_logic;
    
    -- attribute mark_debug : string;
    -- attribute mark_debug of KBD_C : signal is "true";
    -- attribute mark_debug of KBD_L : signal is "true";
    -- attribute mark_debug of i_wrram : signal is "true";
    -- attribute mark_debug of i_d_ram_out : signal is "true";
    -- attribute mark_debug of i_a_cpu : signal is "true";
    -- attribute mark_debug of i_m1n : signal is "true";
    -- attribute mark_debug of i_tape_in : signal is "true";
    -- attribute mark_debug of i_d_cpu_in : signal is "true";
    -- attribute mark_debug of i_nmin : signal is "true";  
        
    -- attribute mark_debug of i_clk_3_25m : signal is "true";
    -- attribute mark_debug of i_kbd_l_swap : signal is "true";
    -- attribute mark_debug of i_iorqn : signal is "true";
    -- attribute mark_debug of i_rdn : signal is "true";
    -- attribute mark_debug of i_rfrshn : signal is "true";

    attribute ASYNC_REG : string;
    attribute ASYNC_REG of vga_control_init_done_0 : signal is "TRUE";
    
    begin
        
    clk_gen_0 : entity work.Clocks_gen
    port map (
        main_clk => CLK_12M,
        clk_52m => clk_52m,
        clk_3_25m => clk_3_25m,
        clk_6_5m => clk_6_5m,
        clk_13m => clk_13m,
        vga_clk => vga_clock,
        rst => RESET,
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
    resetn <= not RESET and pll_locked and vga_control_init_done_0;
         
    -- Instantiation Z80 basé sur la version MIST-devel (https://github.com/mist-devel/T80)
    cpu1 : entity work.T80se
    port map (
		RESET_n	=> resetn,
	 	CLK_n => clk_3_25m,
	 	CLKEN => '1',
	 	WAIT_n => waitn,
	 	INT_n => a_cpu(6),
	 	NMI_n => nmin,
	 	BUSRQ_n => '1',
	 	M1_n => m1n,
	 	MREQ_n => mreqn,
	 	IORQ_n => iorqn,
	 	RD_n => rdn,
	 	WR_n => wrn,
	 	RFSH_n => rfrshn,
	 	HALT_n => haltn,
	 	A => a_cpu,
	 	DI => d_cpu_in,
	 	DO => d_cpu_out
     );
              
    ula0 : entity work.ULA
    port map ( 
       i_RESETn => resetn,
       
       i_CLK_3_25_M => clk_3_25m,
       i_CLK_6_5_M => clk_6_5m,
       i_CLK_13_M => clk_13m,
       i_Cpu_Addr => a_cpu,
       o_Mem_Addr => addr, -- CPU and video addresser address bus
       o_D_cpu_IN => d_cpu_in, -- CPU data bus IN. Output from ULA side
       i_D_ram_out => d_ram_out, -- RAM output data bus. Input for ULA side
       i_D_rom_out => d_rom_out, -- ROM ouput data bus. Input for ULA side 
       
       o_vga_addr => vga_addr,
       o_vga_data => vga_data,    
       o_vga_wr_cyc => vga_wr_cyc, 
       
       i_KBDn => kbd_l_swap,
       i_TAPE_IN => tape_in,
       i_USA_UK => '0',
       o_TAPE_OUT => MIC,
       o_vsync_heart_beat => Vsync_Heart_Beat,
       i_RDn => rdn,
       i_WRn => wrn,
       i_HALTn => haltn,
       i_IORQn => iorqn,
       o_NMIn => nmin,
       i_MREQn => mreqn,
       i_RFRSHn => rfrshn,
       i_M1n => m1n,
       o_WAITn => waitn
    );
    
    -- ROM du ZX81
    rom0 : blk_mem_gen_1
    port map (
        -- L'horloge est à 6,5 MHz car les accès aux patterns video en ROM se font en un cycle de 3,5 MHz
        -- La ROM a un accès synchrone et il faut 2 cycles : 1 pour latcher l'adresse et 1 pour lire la donnée
        clka => clk_6_5m,
        addra => addr (12 downto 0),
        douta => d_rom_out
    );

    ram1 : blk_mem_gen_0
    port map (
       addra => addr (RAM_ADDRWIDTH - 1 downto 0),
       dina => d_cpu_out,
       douta => d_ram_out,       
       clka => clk_3_25m,
       wea => wrram
    );
    
    vga_control0 : entity work.vga_control_top
    port map ( 
        RESET => RESET,
        CLK_52M => clk_52m,
        VGA_CLK => vga_clock,
        VIDEO_ADDR => vga_addr,
        VIDEO_DATA => vga_data,
        WR_CYC => vga_wr_cyc,
        VGA_CONTROL_INIT_DONE => vga_control_init_done,
        HSYNC => hsync,
        VSYNC => vsync,
        BLANK => BLANK_VGA,
        R => R_VGA,
        G => G_VGA,
        B => B_VGA
    );
    
    -- Ajout d'une condition sur le signal WR Ram suite au problème rencontré sur l'instruction en L1A14 (LD      (DE),A)
    -- avec DE qui vaut 0. Je ne sais pas pourquoi vaut 0 dans ce cas. Mais, on reproduit le problème avec MAME.
    -- => Ajout de la condition sur A14 pour valider l'écriture en RAM.
    wrram <= '1' when (wrn = '0' and mreqn = '0' and addr(14) = '1' and addr(15) = '0') else '0';    

    -- Les 5 lignes du clavier
    KBD_C <= a_cpu(15 downto 8);

    tape_in <= EAR;
    
    -- On ne garde que 3 bits sur les 8
    R_VGA_H(2 downto 0) <= R_VGA(7 downto 5) when BLANK_VGA = '0' else "000";
    G_VGA_H(2 downto 0) <= G_VGA(7 downto 5) when BLANK_VGA = '0' else "000";
    B_VGA_H(2 downto 0) <= B_VGA(7 downto 5) when BLANK_VGA = '0' else "000";
    
    HSYNC_VGA <= hsync;
    VSYNC_VGA <= vsync;
    
    kbd_l_swap <= KBD_L;
        
end Behavioral;
