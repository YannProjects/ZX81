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
    signal i_waitn, i_nmin : std_logic := '1';
    signal i_m1n, i_mreqn, i_iorqn, i_tape_in : std_logic;
    signal i_rdn, i_wrn, i_wrram, i_rfrshn, i_haltn, i_video_pattern_select : std_logic;
    signal i_a_cpu, i_a_vid_pattern, i_addr : std_logic_vector (15 downto 0);
    signal i_d_cpu_out, i_d_cpu_in, i_d_ram_out, i_d_rom_out : std_logic_vector (7 downto 0);
    signal i_clk_52m, i_clk_3_25m, i_clk_6_5m, i_clk_13m : std_logic;
    signal i_resetn : std_logic;
    signal i_kbd_l_swap : std_logic_vector(4 downto 0);
    -- VGA
    signal i_vga_clock, i_pll_locked : std_logic;
    signal i_vga_addr: std_logic_vector(19 downto 0);
    signal i_vga_data: std_logic_vector(1 downto 0);
    signal i_vga_wr_cyc : std_logic;
    signal i_vga_control_init_done, i_vga_control_init_done_0, i_vga_control_init_done_1 : std_logic;
    
    signal R_VGA, G_VGA, B_VGA : std_logic_vector(7 downto 0);
    signal BLANK_VGA : std_logic;
    signal i_hsync, i_vsync : std_logic;
    
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
    attribute ASYNC_REG of i_vga_control_init_done_0 : signal is "TRUE";
    
    begin
        
    clk_gen_0 : entity work.Clocks_gen
    port map (
        main_clk => CLK_12M,
        clk_52m => i_clk_52m,
        clk_3_25m => i_clk_3_25m,
        clk_6_5m => i_clk_6_5m,
        clk_13m => i_clk_13m,
        vga_clk => i_vga_clock,
        rst => RESET,
        pll_locked => i_pll_locked
    );
    
    ---------------------------------------------------------------------
    -- Gestion du reset (resynchronisation avec une horloge pour éviter les
    -- métastabilités)
    ---------------------------------------------------------------------
    p_resync_vga_control_init : process(i_clk_3_25m)
    begin
        if rising_edge(i_clk_3_25m) then
            i_vga_control_init_done_0 <= i_vga_control_init_done;
        end if;
    end process;
    i_resetn <= not RESET and i_pll_locked and i_vga_control_init_done_0;
         
    -- Instantiation Z80 basé sur la version MIST-devel (https://github.com/mist-devel/T80)
    cpu1 : entity work.T80se
    port map (
		RESET_n	=> i_resetn,
	 	CLK_n => i_clk_3_25m,
	 	CLKEN => '1',
	 	WAIT_n => i_waitn,
	 	INT_n => i_a_cpu(6),
	 	NMI_n => i_nmin,
	 	BUSRQ_n => '1',
	 	M1_n => i_m1n,
	 	MREQ_n => i_mreqn,
	 	IORQ_n => i_iorqn,
	 	RD_n => i_rdn,
	 	WR_n => i_wrn,
	 	RFSH_n => i_rfrshn,
	 	HALT_n => i_haltn,
	 	A => i_a_cpu,
	 	DI => i_d_cpu_in,
	 	DO => i_d_cpu_out
     );
              
    ula0 : entity work.ULA
    port map ( 
       CLK_3_25_M => i_clk_3_25m,
       CLK_6_5_M => i_clk_6_5m,
       CLK_13_M => i_clk_13m,
       Cpu_Addr => i_a_cpu,
       Mem_Addr => i_addr, -- CPU and video addresser address bus
       D_cpu_IN => i_d_cpu_in, -- CPU data bus IN. Output from ULA side
       D_ram_out => i_d_ram_out, -- RAM output data bus. Input for ULA side
       D_rom_out => i_d_rom_out, -- ROM ouput data bus. Input for ULA side 
       
       vga_addr => i_vga_addr,
       vga_data => i_vga_data,    
       vga_wr_cyc => i_vga_wr_cyc, 
       
       KBDn => i_kbd_l_swap,
       TAPE_IN => i_tape_in,
       USA_UK => '0',
       TAPE_OUT => MIC,
       vsync_heart_beat => Vsync_Heart_Beat,
       RDn => i_rdn,
       WRn => i_wrn,
       HALTn => i_haltn,
       IORQn => i_iorqn,
       NMIn => i_nmin,
       MREQn => i_mreqn,
       RFRSHn => i_rfrshn,
       M1n => i_m1n,
       WAITn => i_waitn,
       RESETn => i_resetn
    );
    
    -- ROM du ZX81
    rom0 : blk_mem_gen_1
    port map (
        -- L'horloge est à 6,5 MHz car les accès aux patterns video en ROM se font en un cycle de 3,5 MHz
        -- La ROM a un accès synchrone et il faut 2 cycles : 1 pour latcher l'adresse et 1 pour lire la donnée
        clka => i_clk_6_5m,
        addra => i_addr (12 downto 0),
        douta => i_d_rom_out
    );

    ram1 : blk_mem_gen_0
    port map (
       addra => i_addr (RAM_ADDRWIDTH - 1 downto 0),
       dina => i_d_cpu_out,
       douta => i_d_ram_out,       
       clka => i_clk_3_25m,
       wea => i_wrram
    );
    
    vga_control0 : entity work.vga_control_top
    port map ( 
        RESET => RESET,
        CLK_52M => i_clk_52m,
        VGA_CLK => i_vga_clock,
        VIDEO_ADDR => i_vga_addr,
        VIDEO_DATA => i_vga_data,
        WR_CYC => i_vga_wr_cyc,
        VGA_CONTROL_INIT_DONE => i_vga_control_init_done,
        HSYNC => i_hsync,
        VSYNC => i_vsync,
        BLANK => BLANK_VGA,
        R => R_VGA,
        G => G_VGA,
        B => B_VGA
    );
    
    -- Ajout d'une condition sur le signal WR Ram suite au problème rencontré sur l'instruction en L1A14 (LD      (DE),A)
    -- avec DE qui vaut 0. Je ne sais pas pourquoi vaut 0 dans ce cas. Mais, on reproduit le problème avec MAME.
    -- => Ajout de la condition sur A14 pour valider l'écriture en RAM.
    i_wrram <= '1' when (i_wrn = '0' and i_mreqn = '0' and i_addr(14) = '1' and i_addr(15) = '0') else '0';    

    -- Les 5 lignes du clavier
    KBD_C <= i_a_cpu(15 downto 8);

    i_tape_in <= EAR;
    
    -- On ne garde que 3 bits sur les 8
    R_VGA_H(2 downto 0) <= R_VGA(7 downto 5) when BLANK_VGA = '0' else "000";
    G_VGA_H(2 downto 0) <= G_VGA(7 downto 5) when BLANK_VGA = '0' else "000";
    B_VGA_H(2 downto 0) <= B_VGA(7 downto 5) when BLANK_VGA = '0' else "000";
    
    HSYNC_VGA <= i_hsync;
    VSYNC_VGA <= i_vsync;
    
    i_kbd_l_swap <= KBD_L;
    
    -- Debug
    Dbg(0) <= i_iorqn or i_rdn;
    Dbg(5 downto 1) <= i_kbd_l_swap(4 downto 0);
    Dbg(6) <= i_a_cpu(11);
    Dbg(7) <= i_a_cpu(12);
    
end Behavioral;
