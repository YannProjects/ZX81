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
-- 27-11-2021: Merge vid state machine et ULA
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.ZX81_Pack.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;
use work.ZX81_Pack.all;

entity ULA is
    Port ( 
           CLK_3_25_M : in std_logic;
           CLK_6_5_M : in std_logic; 
           -- Separation bus addresse CPU et RAM/ROM
           A_cpu : in std_logic_vector (15 downto 0); -- CPU address bus to ULA. Input from ULA side
           A_vid_pattern : out std_logic_vector (15 downto 0); -- Address bus to RAM/ROM memories. Output from ULA side
           -- Separation bus donnees RAM/ROM           
           D_cpu_IN : out STD_LOGIC_VECTOR (7 downto 0); -- CPU data bus IN. Output from ULA side
           D_ram_out : in STD_LOGIC_VECTOR (7 downto 0); -- RAM output data bus. Input for ULA side
           D_rom_out : in STD_LOGIC_VECTOR (7 downto 0); -- ROM ouput data bus. Input for ULA side
           -- Adresse et data vidéo pour le controlleur VGA
           vga_addr : out std_logic_vector(17 downto 0);
           vga_data : out std_logic;
           vga_wr_cyc : out STD_LOGIC;
           -- 
           KBDn : in STD_LOGIC_VECTOR (4 downto 0);
           TAPE_IN : in STD_LOGIC;
           USA_UK : in STD_LOGIC;
           TAPE_OUT : out STD_LOGIC;
           Iorq_Heart_Beat : out std_logic; -- Heart beat pour la sortie video
           RDn : in STD_LOGIC;
           WRn : in STD_LOGIC;
           HALTn : in STD_LOGIC;
           IORQn : in STD_LOGIC;
           NMIn : out STD_LOGIC;
           MREQn : in STD_LOGIC;
           RFRSHn : in std_logic;
           VID_PATTERN_ROM_ADDR_SELECT : out std_logic;
           M1n : in STD_LOGIC;
           WAITn : out std_logic;
           RESETn : in STD_LOGIC
         );
end ULA;

architecture Behavioral of ULA is

    signal i_hsyncn : std_logic;
    signal i_vsync, i_vsync_pulse_valid : std_logic;
    signal i_nmionn : std_logic;
    signal char_line_cntr : unsigned(2 downto 0);
    signal i_vsync_pulse_duration : unsigned(11 downto 0);
    signal char_reg : std_logic_vector(7 downto 0);
    signal hsyncn_counter: unsigned(11 downto 0);
    signal i_nop_detect, i_nop_detect_0, i_nop_detect_1: std_logic;
     
    signal i_vga_addr : std_logic_vector(17 downto 0);
    signal i_vga_data : std_logic_vector(7 downto 0);
    signal i_vga_wr : std_logic;
    
    signal iorqn_0, iorqn_1, i_nmin : std_logic;
    
    signal i_hsyncn_cnt : unsigned(11 downto 0);
    signal i_vid_shift_register : std_logic_vector(7 downto 0);
    signal i_rom_addr_enable_for_vid_pattern : std_logic;
       
    -- attribute mark_debug : string;
    -- attribute mark_debug of i_vsync : signal is "true";
    -- attribute mark_debug of i_vsync_pulse_valid : signal is "true";
    -- attribute mark_debug of i_hsyncn : signal is "true";
    -- attribute mark_debug of vga_addr : signal is "true";
    -- attribute mark_debug of vga_data : signal is "true";
    -- attribute mark_debug of vga_wr_cyc : signal is "true";
    -- attribute mark_debug of CLK_3_25_M : signal is "true";
    -- attribute mark_debug of A_cpu : signal is "true";
    -- attribute mark_debug of D_cpu_IN : signal is "true";
    -- attribute mark_debug of M1n : signal is "true";
    -- attribute mark_debug of MREQn : signal is "true";
    -- attribute mark_debug of RFRSHn : signal is "true";
    -- attribute mark_debug of RDn : signal is "true";
    -- attribute mark_debug of char_line_cntr : signal is "true";
    -- attribute mark_debug of HALTn : signal is "true";
    -- attribute mark_debug of i_hsyncn : signal is "true";
    -- attribute mark_debug of i_vsync : signal is "true";
    -- attribute mark_debug of NMIn : signal is "true";
    -- attribute mark_debug of i_vga_addr : signal is "true";
    -- attribute mark_debug of i_vga_data : signal is "true";
    -- attribute mark_debug of vga_wr_cyc : signal is "true";

begin

p_vid_shift_register: process (CLK_6_5_M, RESETn)
begin
    if RESETn = '0' then
        i_vid_shift_register <= (others => '0');
    elsif rising_edge(CLK_6_5_M) then
        -- Sélection de la partie avec MREQn = 0 (cycle T4) durant laquelle on peut lire le pattern video
        if MREQn = '0' and CLK_3_25_M = '0' and i_rom_addr_enable_for_vid_pattern = '1' then
            -- Lecture pattern vidéo
            -- Caractere en inversion video ?
            if (char_reg(7) = '0') then
                i_vid_shift_register <= D_rom_out;
            else
                i_vid_shift_register <= not D_rom_out;
            end if;
        else      
            i_vid_shift_register <= i_vid_shift_register(6 downto 0) & '0';
        end if;
    end if;
end process;

p_vga_addr_counter: process (CLK_6_5_M, i_vsync, RESETn)
begin
    if RESETn = '0' or i_vsync = '1' then
        if RESETn = '0' or (i_vsync = '1' and i_vsync_pulse_valid = '1') then
            i_vga_addr <= (others => '0');
        else
            i_vga_addr <= i_vga_addr and B"11" & X"FF80";
        end if;
    elsif rising_edge(CLK_6_5_M) then
        if i_hsyncn_cnt < MAX_VGA_PIXEL_OFFSET then
            i_vga_addr <= i_vga_addr + 1;
            i_vga_wr <= '1';
        else
            i_vga_wr <= '0';
        end if;
    end if;
end process;

vga_wr_cyc <= i_vga_wr;
vga_addr <= i_vga_addr;
vga_data <= i_vid_shift_register(7);

---------------------------------------------------------------------
-- Process pour la génération du HSYNC et de la gate vidéo
-- Aussi, génération du compteur de lignes par rapport au debut de la trame
---------------------------------------------------------------------
hsync_and_gate_process: process (CLK_3_25_M, RESETn)

variable hsyncn_counter: unsigned(11 downto 0);
 
begin
    if (RESETn = '0' or i_vsync = '1') then
        hsyncn_counter := (others => '0');
        char_line_cntr <= (others => '0');        
        i_hsyncn <= '1';
    -- Sur chaque front descendant de l'horloge 6.5 MHz
    -- L'horloge à 6,5 MHz est utilsée pour rester synchrone par rapport au process p_vga_addr_counter
    elsif rising_edge(CLK_3_25_M) then
        -- 384 cycles d'horloge à 6.5 MHz = 59 µs
        -- Duree pulse HSYNC = (414 - 384) @6.5 MHz = 4,6 µs 
        -- Generateur de HSYNC
        hsyncn_counter := hsyncn_counter + 1;
        if hsyncn_counter >= FB_PORCH_OFF_DURATION and hsyncn_counter < FB_PORCH_OFF_DURATION + HSYNC_PULSE_ON_DURATION then  
            i_hsyncn <= '0';
        elsif hsyncn_counter = FB_PORCH_OFF_DURATION + HSYNC_PULSE_ON_DURATION then
            i_hsyncn <= '1';
            char_line_cntr <= char_line_cntr + 1;
            hsyncn_counter := (others => '0');
        end if;
    end if;
    
    i_hsyncn_cnt <= hsyncn_counter;
    
end process;

-- Nouvelle version utilisant des fonctions combinatoires pour
-- le décodage des adresses.
p_cpu_data_in : process (A_cpu, RDn, MREQn, IORQn, D_ram_out, D_rom_out, TAPE_IN, USA_UK, KBDn)
begin
    if (MREQn = '0' and RDn = '0') then
        -- Cycle de lecture RAM / ROM
        case A_cpu(15 downto 14) is
            -- Adressage de la ROM
            when "00" =>
                D_cpu_IN <= D_rom_out;
            -- Adressage de la RAM 
            when "01" =>
                D_cpu_IN <= D_ram_out;
            -- NOP execution ?
            when "11" =>
                -- NOP uniquement si le bit 6 = 0 (sinon c'est une instruction de HALT et on la laisse passer)
                if D_ram_out(6) = '0' then
                    D_cpu_IN <= X"00";
                else
                    D_cpu_IN <= D_ram_out;
                end if;
            when others =>
                D_cpu_IN <= D_rom_out;
        end case;
    elsif (IORQn = '0' and A_cpu(0) = '0' and RDn = '0') then
        -- IO inputs
        D_cpu_in <= TAPE_IN & USA_UK & '0' & KBDn(0) & KBDn(1) & KBDn(2) & KBDn(3) & KBDn(4);
    else
        D_cpu_in <= (others => 'X');
    end if;
end process;

-- Detection NOP =>  on stockera le pattern video sera lu dans la ROM dans la RAM VGA
i_nop_detect <= '1' when (M1n = '0' and MREQn = '0' and RDn = '0' and HALTn = '1' and A_cpu(15 downto 14) = "11" and D_ram_out(6) = '0') else '0';

----------------------------------------
-- Process combinatoire pour la génération ed NIMONn et VSYNC
----------------------------------------
-- Basé sur le schéma http://quix.us/timex/rigter/ZX97lite.html
-- Chapitre 6) VSYNC / NMI CIRCUIT
-------------------------------------------------------
-- D'apres le schema du ZX81 clone:
-- IORQ read et A0 = 0 et NMI_ONn = 1 => VSYNC = 1
-- IORQ write => VSYNC = 0
-- IORQ write et A0 = 0 => NMI_ONn = 0 (OUT_FEn)
-- IORQ write et A1 = 0 => NMI_ONn = 1 (OUT_FDn)
-- Par rapport <E0> VSYNCn:
--          OUT_FEn => On interdit de mettre VSYNC = 1
--          OUT_FDn => On autorise de mettre VSYNC = 1
-------------------------------------------------------

-- Set/Reset pour VSYNC
p_vsync : process(RESETn, CLK_3_25_M)
begin
    if RESETn = '0' then
        i_vsync <= '0';
    -- On synchronise quand même avec l'horloge poursuivre les conseils de vivado 
    elsif rising_edge(CLK_3_25_M) then
        -- Enable VSYNC (IN FE)
        if IORQn = '0' and A_cpu(0) = '0' and RDn = '0' and i_nmionn = '1' then
            i_vsync <= '1';
        -- Clear VSYNC (OUT NN)
        elsif IORQn = '0' and WRn = '0' then
            i_vsync <= '0';
        end if;
    end if;    
end process;

p_vsync_pulse_duration_counter : process(RESETn, CLK_3_25_M)
begin
    if RESETn = '0' or i_vsync = '0' then
        i_vsync_pulse_duration <= X"000";
        i_vsync_pulse_valid <= '0';
    -- On compte la durée du pulse de VSYNC pour savoir si c'est uyne vraie synchro trame ou pas
    -- (cas du ZX81 en mode pseudo-hires avec invaders ou pacman)
    elsif rising_edge(CLK_3_25_M) then
        i_vsync_pulse_duration <= i_vsync_pulse_duration + 1;
        if i_vsync_pulse_duration >= MIN_VSYNC_PULSE_DURATION then
            i_vsync_pulse_valid <= '1';
        end if;
    end if;
end process;

p_nmi : process(RESETn, CLK_3_25_M)
begin
    if RESETn = '0' then
        i_nmionn <= '1';
    -- On synchronise quand même avec l'horloge poursuivre les conseils de vivado        
    elsif rising_edge(CLK_3_25_M) then        
        -- Clear NMIn (OUT FD)
        if IORQn = '0' and WRn = '0' and A_cpu(1) = '0' then
            i_nmionn <= '1';
        -- Enable NMIn (OUT FE)
        elsif IORQn = '0' and WRn = '0' and A_cpu(0) = '0' then
            i_nmionn <= '0';
        end if;
    end if;
end process;

-----------------------------------------------------
-- Process pour le heart beat IORQn (allumage LED)
-----------------------------------------------------
p_iorq_hb : process (RESETn, CLK_3_25_M, IORQn)

variable iorq_counter : unsigned(15 downto 0);
variable i_iorq_heart_beat : std_logic;

begin
    if (RESETn = '0') then
        i_iorq_heart_beat := '0';
        iorq_counter := IORQ_PERIOD;
        iorqn_1 <= '1';
    -- Sur chaque front descendant de l'horloge 6.5 MHz
    elsif rising_edge(CLK_3_25_M) then
        iorqn_0 <= IORQn;
        iorqn_1 <= iorqn_0;
        -- IORQ heart beat qui inclut le VSYNC et aussi les lectures clavier + load cassette
        -- Compteur de heart beat pour faire clignoter la LED sur le CMOD S7. 
        -- Détection transtion 1 -> 0
        if iorqn_1 = '1' and iorqn_0 = '0' then
            iorq_counter := iorq_counter - 1;
            if  iorq_counter(15) = '1' then
                iorq_counter := IORQ_PERIOD;
                i_iorq_heart_beat := not i_iorq_heart_beat;
            end if;
        end if;
    end if;
    
    iorq_heart_beat <= i_iorq_heart_beat;
    
end process;
        
nop_detect_process: process (CLK_3_25_M)
begin
    if rising_edge(CLK_3_25_M) then
        -- Le signalde NOP est décalé de 2 péreiodes de 3,25 MHz
        -- pour se caler sur les cycels CPU T3 et T4
        i_nop_detect_0 <= i_nop_detect;
        i_nop_detect_1 <= i_nop_detect_0;
        -- Si NOP detect, on lit le caractère dans la RAM
        if i_nop_detect = '1' then
            char_reg <= D_ram_out;
        end if;
    end if;
end process;

-- Signal de sélection de l'adress de vid_pattern vers la ROM
-- Le signal est aligné sur les cycle T3 et T4 de l'excution en RAM pour l'affichage video
i_rom_addr_enable_for_vid_pattern <= i_nop_detect_0 or i_nop_detect_1;

A_vid_pattern <= A_cpu(15 downto 9) & char_reg(5 downto 0) & std_logic_vector(char_line_cntr(2 downto 0));
-- Signal utilise pour positionner l'adresse du pattern video à lire en ROM
VID_PATTERN_ROM_ADDR_SELECT <= i_rom_addr_enable_for_vid_pattern;

TAPE_OUT <= not i_vsync;

-- Explications issue de la page http://www.user.dccnet.com/wrigter/index_files/ZX81WAIT.htm
-- En slow mode, le Z80 est interrompu toutes les 64 us par la NMI. La procédure d'interruption (en 0x0066)
-- compte le nombre de lignes restantes pour commencer l'afficahge vidéo.
-- Lorsque le nombre de ligne est atteint, le CPU exécute une instruction HALT et attend la prochaine NMI
-- Lorsque celle-ci arrive, le CPU continue son exécution à l'adresse 0x007A. Ce code, stoppe la NMI (OUT FD, A)
-- et démare "l'exécution" en RAM vidéo (JP (IX)).
-- Cependant, cette phase a besoin d'être synchonisée avec la fin du pulse de NMI afin de démarrer l'envoi
-- de la vidéo préciésement à ce moment.
-- C'est la fonction de la porte OR ci-dessous.
-- Si on sort de HALTn et que NMIn = 0 (NMI pulse en court), on insère des cycles de WAIT afin d'attendre la fin du pulse de NMI
-- et relacher le CPU sur le cycle T3 (après les cycles de WAIT) et charger le registre à décalage vidéo sur le cycle T4 juste après...
i_nmin <= i_nmionn or i_hsyncn;
NMIn <= i_nmin;
WAITn <= not HALTn or i_nmin;

end Behavioral;
