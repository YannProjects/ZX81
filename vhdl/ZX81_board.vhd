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
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.ZX81_pack.all;
use work.T80_Pack.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
-- library UNISIM;
-- use UNISIM.VComponents.all;

entity ZX81_board is
    Port ( CLK_12M : in STD_LOGIC; -- Clock from CMOD S7
           MIC : in STD_LOGIC;
           RESET : in std_logic;
           KBD_L : in STD_LOGIC_vector (4 downto 0);
           KBD_C : out STD_LOGIC_vector (7 downto 0);
           EAR : out STD_LOGIC;
           Video : out STD_LOGIC;
           Iorq_Heart_Beat : out std_logic;
           CSYNCn : out STD_LOGIC;
           
           -- Signaux de debug
           Debug : out std_logic_vector(5 downto 0)
                      
           -- LEDs embarquées sur le CMOD S7
           -- LED_1 -> E2 : IORQn_Heart_Beat
           -- LED_2 -> K1 : NOP_Detect_Hear_Beat
           -- LED_3 -> J1 : HALTn_Heart_Beat
           -- LED_4 -> E1 : LINE_CNTR_Heart_Beat
           -- IORQn_Heart_Beat: out std_logic;
           -- NOP_Detect_Heart_Beat: out std_logic;
           -- HALTn_Heart_Beat: out std_logic
         );
end ZX81_board;

architecture Behavioral of ZX81_board is

    component dist_mem_gen_0 IS
    port (
        a : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
        spo : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
    end component; 
    
    component clk_wiz_0 IS
    port (
        clk_6_5m : OUT STD_LOGIC;
        clk_in1 : IN STD_LOGIC  
    );
    end component; 
         
    component dist_mem_gen_1 IS
    port (
       a : IN STD_LOGIC_VECTOR(RAM_ADDRWIDTH - 1 DOWNTO 0);
       d : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
       clk : IN STD_LOGIC;
       we : IN STD_LOGIC;
       spo : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
     );
     end component;
    
    -- Control signal
    signal i_waitn, i_nmin : std_logic := '1';
    signal i_busackn, i_m1n, i_mreqn, i_iorqn, i_mic : std_logic;
    signal i_rdn, i_wrn, i_wrram, i_rfrshn, i_haltn, i_nop_detect : std_logic;
    signal i_a_cpu, i_a_vid_pattern,i_a_rom : std_logic_vector (15 downto 0);
    signal a_ram_addr_2K : std_logic_vector (13 downto 0);
    signal i_d_cpu_out, i_d_cpu_in, i_d_ram_in, i_d_ram_out, i_d_ram_out_0, i_d_rom_out : std_logic_vector (7 downto 0);
    signal i_csyncn, i_clk_6_5m, i_clk_6_5mn, i_clk_3_25m, i_video, i_resetn : std_logic;
    signal ULA_Debug : std_logic_vector(4 downto 0);
    
    -- attribute mark_debug : string;
    -- attribute mark_debug of KBD_C : signal is "true";
    -- attribute mark_debug of KBD_L : signal is "true";
    -- attribute mark_debug of i_iorqn : signal is "true";
    -- attribute mark_debug of i_wrram : signal is "true";
    -- attribute mark_debug of i_d_ram_out : signal is "true";
    -- attribute mark_debug of i_a_cpu : signal is "true";
    -- attribute mark_debug of i_m1n : signal is "true";
    -- attribute mark_debug of i_mic : signal is "true";
    -- attribute mark_debug of i_d_cpu_in : signal is "true";
    -- attribute mark_debug of i_clk_3_25m : signal is "true";
    
begin        
     
    -- Instantiation Z80 basé sur le site OpenCores 
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
	 	BUSAK_n => i_busackn,
	 	A => i_a_cpu,
	 	DI => i_d_cpu_in,
	 	DO => i_d_cpu_out
     );
    
    clocks_gen0 : entity work.Clocks_gen
    port map (
        main_clk => i_clk_6_5m,
        resetn => i_resetn,
        clk_3_25m => i_clk_3_25m
    );
              
    ula0 : entity work.ULA
    port map ( 
       CLK_6_5_M => i_clk_6_5m,
       A_cpu => i_a_cpu, -- CPU address bus
       A_vid_pattern => i_a_vid_pattern, -- RAM/ROM address bus
       D_cpu_IN => i_d_cpu_in, -- CPU data bus IN. Output from ULA side
       D_cpu_OUT => i_d_cpu_out, -- CPU data bus OUT. Input from ULA side
       D_ram_in => i_d_ram_in, -- RAM input data bus. Output from ULA side
       D_ram_out => i_d_ram_out, -- RAM output data bus. Input for ULA side
       D_rom_out => i_d_rom_out, -- ROM ouput data bus. Input for ULA side       
       KBDn => KBD_L, -- <<==
       TAPE_IN => i_mic,
       USA_UK => '0',
       TAPE => EAR,
       Video => Video, -- Data video
       Iorq_Heart_Beat => Iorq_Heart_Beat,
       CSYNCn => i_csyncn, -- Composite sync (HSYNC + VSYNC)
       RDn => i_rdn,
       WRn => i_wrn,
       HALTn => i_haltn,
       IORQn => i_iorqn,
       NMIn => i_nmin,
       MREQn => i_mreqn,
       RFRSHn => i_rfrshn,
       NOP_Detect => i_nop_detect,
       M1n => i_m1n,
       WAITn => i_waitn,
       RESETn => i_resetn
    );

    ram1 : dist_mem_gen_1
    port map (
       a => i_a_cpu (RAM_ADDRWIDTH - 1 downto 0),
       d => i_d_cpu_out,
       clk => i_clk_6_5mn,
       we => i_wrram,     -- Write actif sur niveau haut...
       spo => i_d_ram_out
    );
    -- a_ram_addr_2K <= B"000" & i_a_mem (10 downto 0);
    
    -- i_wrram <= i_wrn when i_mreqn = '0' else '1';
    -- Ajout d'une condition sur le signal WR Ram suite au problème rencontré sur l'instruction en L1A14 (LD      (DE),A)
    -- avec DE qui vaut 0. Je ne sais pas pourquoi vaut 0 dans ce cas. Mais, on reproduit le problème avec MAME.
    -- => Ajout de la condition sur A14 pour valider l'écriture en RAM.
    i_wrram <= '1' when (i_wrn = '0' and i_mreqn = '0' and i_a_cpu(14) = '1' and i_a_cpu(15) = '0') else '0';

    -- ROM du ZX81
    rom0 : dist_mem_gen_0
    port map (
        a => i_a_rom (12 downto 0),
        spo => i_d_rom_out
    );
    i_a_rom <= i_a_vid_pattern when i_nop_detect = '1' else i_a_cpu;
    
    -- Composant utiliser pour générer du 6,5 Mhz à partir du 12 MHz de l'oscillateur du CMOD S7    
    clk_gen : clk_wiz_0
    port map (
        clk_in1 => CLK_12M,
        clk_6_5m => i_clk_6_5m
    );
   
    KBD_C <= i_a_cpu(15 downto 8);
    i_clk_6_5mn <= not i_clk_6_5m;
    -- Video <= not i_video;
    CSYNCn <= i_csyncn;
    i_resetn <= not RESET;
    i_mic <= not MIC;
    
    -- Signaux de debug vers un connecteur externe
    Debug <= "000000";
    
end Behavioral;
