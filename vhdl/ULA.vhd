----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09.11.2019 22:56:50
-- Design Name: 
-- Module Name: ULA - Behavioral
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
use work.ZX81_Pack.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
-- library UNISIM;
-- use UNISIM.VComponents.all;
-- use work.ZX81_Pack.all;

entity ULA is
    Port ( CLK_6_5_M : in std_logic;
           -- Separation bus addresse CPU et RAM/ROM
           A_cpu : in std_logic_vector (15 downto 0); -- CPU address bus to ULA. Input from ULA side
           A_vid_pattern : out std_logic_vector (15 downto 0); -- Address bus to RAM/ROM memories. Output from ULA side
           -- Separation bus donnees RAM/ROM           
           D_cpu_IN : out STD_LOGIC_VECTOR (7 downto 0); -- CPU data bus IN. Output from ULA side
           D_cpu_OUT : in STD_LOGIC_VECTOR (7 downto 0); -- CPU data bus OUT. Input from ULA side
           D_ram_in : out STD_LOGIC_VECTOR (7 downto 0); -- RAM input data bus. Output from ULA side
           D_ram_out : in STD_LOGIC_VECTOR (7 downto 0); -- RAM output data bus. Input for ULA side
           D_rom_out : in STD_LOGIC_VECTOR (7 downto 0); -- ROM ouput data bus. Input for ULA side
           -- Adresse et data vid�o pour le controlleur VGA
           vga_addr : out std_logic_vector(13 downto 0);
           vga_data : out std_logic_vector(7 downto 0);
           vga_wr_cyc : out STD_LOGIC;
           -- 
           KBDn : in STD_LOGIC_VECTOR (4 downto 0);
           TAPE_IN : in STD_LOGIC;
           USA_UK : in STD_LOGIC;
           TAPE_OUT : out STD_LOGIC;
           Video : out std_logic; -- Data video
           Iorq_Heart_Beat : out std_logic; -- Heart beat pour la sortie video
           CSYNCn : out std_logic; -- Composite sync (HSYNC + VSYNC)
           RDn : in STD_LOGIC;
           WRn : in STD_LOGIC;
           HALTn : in STD_LOGIC;
           IORQn : in STD_LOGIC;
           NMIn : out STD_LOGIC;
           MREQn : in STD_LOGIC;
           RFRSHn : in std_logic;
           NOP_Detect : out std_logic;
           M1n : in STD_LOGIC;
           WAITn : out std_logic;
           RESETn : in STD_LOGIC
         );
end ULA;

architecture Behavioral of ULA is

signal i_nmin : std_logic;

begin

vid_state_machine_0 : entity work.vid_state_machine
port map (
    clk => CLK_6_5_M,
    RSTn => RESETn,
    A_cpu => A_cpu,
    A_vid_pattern => A_vid_pattern,
    D_cpu_IN => D_cpu_IN,
    D_cpu_OUT => D_cpu_OUT,
    D_ram_in => D_ram_in,
    D_ram_out => D_ram_out,
    D_rom_out => D_rom_out,
    vga_addr => vga_addr,
    vga_data => vga_data,
    vga_wr_cyc => vga_wr_cyc,
    
    M1n => M1n,
    RDn => RDn,
    WRn => WRn,
    HALTn => HALTn,
    IORQn => IORQn,
    NMIn => i_nmin,
    MREQn => MREQn,
    RFRSHn => RFRSHn,
    NOP_Detect => NOP_Detect,
    SEROUT => TAPE_OUT,
    iorq_heart_beat => Iorq_Heart_Beat,
    
    KBDn => KBDn,
    TAPE_IN => TAPE_IN,
    USA_UK => USA_UK
);

-- Explications issue de la page http://www.user.dccnet.com/wrigter/index_files/ZX81WAIT.htm
-- En slow mode, le Z80 est interrompu toutes les 64 us par la NMI. La proc�dure d'interruption (en 0x0066)
-- compte le nombre de lignes restantes pour commencer l'afficahge vid�o.
-- Lorsque le nombre de ligne est atteint, le CPU ex�cute une instruction HALT et attend la prochaine NMI
-- Lorsque celle-ci arrive, le CPU continue son ex�cution � l'adresse 0x007A. Ce code, stoppe la NMI (OUT FD, A)
-- et d�mare "l'ex�cution" en RAM vid�o (JP (IX)).
-- Cependant, cette phase a besoin d'�tre synchonis�e avec la fin du pulse de NMI afin de d�marrer l'envoi
-- de la vid�o pr�ci�sement � ce moment.
-- C'est la fonction de la porte OR ci-dessous.
-- Si on sort de HALTn et que NMIn = 0 (NMI pulse en court), on ins�re des cycles de WAIT afin d'attendre la fin du pulse de NMI
-- et relacher le CPU sur le cycle T3 (apr�s les cycles de WAIT) et charger le registre � d�calage vid�o sur le cycle T4 juste apr�s...
NMIn <= i_nmin;
WAITn <= not HALTn or i_nmin;

end Behavioral;
