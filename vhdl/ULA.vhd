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
           CLK_13_M : in std_logic;
           Cpu_Addr : in std_logic_vector (15 downto 0); -- CPU address bus to ULA. Input from ULA side
           -- Separation bus addresse CPU et RAM/ROM
           Mem_Addr : out std_logic_vector (15 downto 0); -- RAM/ROM address. Output from ULA side
           -- Separation bus donnees RAM/ROM           
           D_cpu_IN : out STD_LOGIC_VECTOR (7 downto 0); -- CPU data bus IN. Output from ULA side
           D_ram_out : in STD_LOGIC_VECTOR (7 downto 0); -- RAM output data bus. Input for ULA side
           D_rom_out : in STD_LOGIC_VECTOR (7 downto 0); -- ROM ouput data bus. Input for ULA side
           -- Adresse et data vidéo pour le controlleur VGA
           vga_addr : out std_logic_vector(19 downto 0);
           vga_data : out std_logic_vector(1 downto 0);
           vga_wr_cyc : out STD_LOGIC;
           -- 
           KBDn : in STD_LOGIC_VECTOR (4 downto 0);
           TAPE_IN : in STD_LOGIC;
           USA_UK : in STD_LOGIC;
           TAPE_OUT : out STD_LOGIC;
           vsync_heart_beat : out std_logic; -- Heart beat pour la sortie video
           RDn : in STD_LOGIC;
           WRn : in STD_LOGIC;
           HALTn : in STD_LOGIC;
           IORQn : in STD_LOGIC;
           NMIn : out STD_LOGIC;
           MREQn : in STD_LOGIC;
           RFRSHn : in std_logic;
           M1n : in STD_LOGIC;
           WAITn : out std_logic;
           RESETn : in STD_LOGIC
         );
end ULA;

architecture Behavioral of ULA is

    signal i_csyncn, i_csyncn_0, i_csyncn_1 : std_logic;
    signal i_hsyncn, i_vsync : std_logic;
    signal i_nmionn : std_logic;
    signal char_line_cntr : unsigned(2 downto 0);
    signal i_csync_pulse_duration : integer;
    signal char_reg, i_d_cpu_in : std_logic_vector(7 downto 0);
    signal i_nop_detect, i_nop_detect_0: std_logic;
     
    signal i_vga_addr_frame_offset, i_vga_pixel_offset, i_vga_line_offset  : integer;
    signal i_vga_wr : std_logic;
    
    signal i_vsync_0, i_vsync_1, i_nmin : std_logic;
    signal i_vsync_frame_detect : std_logic;
        
    signal i_hsyncn_cnt : integer;
    signal i_vid_shift_register : std_logic_vector(15 downto 0);
    signal i_addr_enable_for_vid_pattern : std_logic;

    -- attribute mark_debug : string;
    -- attribute mark_debug of i_vsync : signal is "true";
    -- attribute mark_debug of i_hsyncn : signal is "true";
    -- attribute mark_debug of CLK_3_25_M : signal is "true";
    -- attribute mark_debug of CLK_6_5_M : signal is "true";
    -- attribute mark_debug of Addr : signal is "true";
    -- attribute mark_debug of D_cpu_IN : signal is "true";
    -- attribute mark_debug of M1n : signal is "true";
    -- attribute mark_debug of MREQn : signal is "true";
    -- attribute mark_debug of RFRSHn : signal is "true";
    -- attribute mark_debug of RDn : signal is "true";
    -- attribute mark_debug of char_line_cntr : signal is "true";
    -- attribute mark_debug of HALTn : signal is "true";
    -- attribute mark_debug of NMIn : signal is "true";
    -- attribute mark_debug of i_nmionn : signal is "true";
    -- attribute mark_debug of i_nop_detect : signal is "true";
    -- attribute mark_debug of vga_addr : signal is "true";
    -- attribute mark_debug of i_vga_addr_frame_offset : signal is "true";
    -- attribute mark_debug of i_vga_pixel_offset : signal is "true";
    -- attribute mark_debug of i_vga_line_offset : signal is "true";
    -- attribute mark_debug of vga_data : signal is "true";
    -- attribute mark_debug of vga_wr_cyc : signal is "true";

begin

p_vid_shift_register: process (CLK_13_M, RESETn)
begin
    if RESETn = '0' then
        i_vid_shift_register <= (others => '0');
        i_vga_line_offset <= 0;
    elsif rising_edge(CLK_13_M) then
        -- Sélection de la partie avec MREQn = 0 (cycle T4) durant laquelle il faut recharger le pattern video
        -- Dans le schema original du ZX81, le registre à decalage est recharge en fin de cycle T4 de l'execution en RAM video.
        -- C'est ce qui est reproduit ici en rechargeant le registre en fin de cycle T4 avec les conditions:
        -- MREQn = '0' and CLK_3_25_M = '0' and CLK_6_5_M = '0'
        -- (sur le front montant de l'horloge 13 MHz). 
        if MREQn = '0' and CLK_3_25_M = '0' and CLK_6_5_M = '0' and i_addr_enable_for_vid_pattern = '1' then
            -- On resette la variable utilisée pour adressée une ligne ou celle du dessous avec la même valeur.
            i_vga_line_offset <= 0;
            -- Caractere en inversion video ?
            if (char_reg(7) = '0') then
                -- Les pixels sont doublés car on les écrit 2 fois:
                -- 1 fois à l'adresse A pendant le 1er cycle à 13 MHz et l'autre fois à l'adresse A + NUMBER_OF_PIXELS_PER_LINE (= nombre de pixels dans une ligne)
                -- lors du second cycle de 13 MHz. Cette solution permet de doubler les lignes verticalement.
                i_vid_shift_register <= i_d_cpu_in(7) & i_d_cpu_in(7) &
                                        i_d_cpu_in(6) & i_d_cpu_in(6) &
                                        i_d_cpu_in(5) & i_d_cpu_in(5) &
                                        i_d_cpu_in(4) & i_d_cpu_in(4) &
                                        i_d_cpu_in(3) & i_d_cpu_in(3) &
                                        i_d_cpu_in(2) & i_d_cpu_in(2) &
                                        i_d_cpu_in(1) & i_d_cpu_in(1) &
                                        i_d_cpu_in(0) & i_d_cpu_in(0) ;
            else
                i_vid_shift_register <= not (i_d_cpu_in(7) & i_d_cpu_in(7) &
                                        i_d_cpu_in(6) & i_d_cpu_in(6) &
                                        i_d_cpu_in(5) & i_d_cpu_in(5) &
                                        i_d_cpu_in(4) & i_d_cpu_in(4) &
                                        i_d_cpu_in(3) & i_d_cpu_in(3) &
                                        i_d_cpu_in(2) & i_d_cpu_in(2) &
                                        i_d_cpu_in(1) & i_d_cpu_in(1) &
                                        i_d_cpu_in(0) & i_d_cpu_in(0)) ;
            end if;
        else
            if i_vga_line_offset = 0 then
                -- Ligne du dessous (1 cycle de 13 MHz sur 2)
                i_vga_line_offset <= NUMBER_OF_PIXELS_PER_LINE;
            else
                -- Ligne courante (1 cycle de 13 MHz sur 2)
                i_vga_line_offset <= 0;
            end if;
            i_vid_shift_register <= i_vid_shift_register(14 downto 0) & '0';
        end if;
    end if;
end process;

p_vga_pixel_addr_counter: process (CLK_6_5_M, i_vsync, i_hsyncn, RESETn)
begin
    if RESETn = '0' or i_hsyncn = '0' or i_vsync = '1' then
        -- On resette le nombre de pixel depuis le début de la ligne en cas de HSYNCn ou VSYNC
        i_vga_pixel_offset <= 0;
    elsif rising_edge(CLK_6_5_M) then
        -- On débute le comptage des pixels de ligne a partir du moment ou on a atteind
        -- la fin du pulse de VSYNC
        -- A remplacer par le signal CSYNCn        
        if i_hsyncn_cnt < FB_PORCH_OFF_DURATION then
            -- On incremente de 2 pixels pour doubler le nombre de pixels de ligne
            i_vga_pixel_offset <= i_vga_pixel_offset + 1;
        end if;
    end if;
end process;

p_vga_line_addr_counter: process (CLK_3_25_M, i_vsync_frame_detect, RESETn)
begin
    if (RESETn = '0' or i_vsync_frame_detect = '1') then
        i_vga_addr_frame_offset <= 0;
    -- Sur chaque front descendant de l'horloge 3,25 MHz
    elsif rising_edge(CLK_3_25_M) then
        i_csyncn_1 <= i_csyncn;
        i_csyncn_0 <= i_csyncn_1;
        -- Detection front descendant composite sync (= HSYNC + VSYNC) 
        -- Dans le cas des jeux PACMAN et INVADERS en mode pseudo-hires, il y a des pulses de VSYNC courts pou resetter le compteur
        -- char_line_cntr. Cependant, il faut continuer à incrémenter le compteur de lignes i_vga_addr_frame_offset.
        -- Dans le cas d'un front descendat CSYNCn, on incrémente le compteur de lignes 
        if i_csyncn_0 = '1' and i_csyncn_1 = '0' then
            i_vga_addr_frame_offset <= i_vga_addr_frame_offset + 2*NUMBER_OF_PIXELS_PER_LINE;
        end if;
    end if;
end process;

i_csyncn <= not i_vsync and i_hsyncn;


-- i_vga_addr_frame_offset: Adresse du début de la la ligne courante dans la trame
-- i_vga_pixel_offset: Offset du pixel dans la ligne
-- i_vga_line_offset: Variable utilisée pour adressée un ligne sur 2 (contient 0 ou NUMBER_OF_PIXELS_PER_LINE)
-- LINE_OFFSET_FROM_FRAME_START: Offset pour décaler l'image de 45 lignes vers le haut et mieux la centrer par rapport à l'affichage VGA
-- PIXEL_LINE_START: Offset dans la ligne du premier pixel à écrire
-- PIXEL_LINE_STOP: Offset dans la ligne du dernier pixel à écrire
-- Une ligne d'affichage du ZX81 contient 192 cycles d'horloge à 3,5 MHz donc 384 cycles à 6,5 MHz, soit un maximum de 384 pixels par lignes.
-- Si on double l'affichage pour utiliser la totalité de la ligne de 640x480, on arrive à 384 * 2 > 640 pixels, 
-- le mieux est d'éliminer les premiers et dernier pixels pour n'avoir que 640 pixels par ligne:
-- 2*384 - 640 = 128. J'ai donc mis 64 PIXEL_LINE_START ce qui correspond à 64 pixels de ligne VGA sur la partie gauche qui sont elimines de la ligne.

vga_addr <= std_logic_vector(to_unsigned(i_vga_addr_frame_offset + i_vga_pixel_offset + i_vga_line_offset - FRAME_LINE_START - PIXEL_LINE_START, vga_addr'length));
vga_data <= i_vid_shift_register(15) & i_vid_shift_register(15);
vga_wr_cyc <= i_hsyncn and not i_vsync when i_vga_addr_frame_offset >= FRAME_LINE_START and 
                                            i_vga_pixel_offset >= PIXEL_LINE_START and
                                            i_vga_pixel_offset < PIXEL_LINE_STOP 
                                       else '0';

---------------------------------------------------------------------
-- Process pour la génération du HSYNC et de la gate vidéo
-- Aussi, génération du compteur de lignes par rapport au debut de la trame
---------------------------------------------------------------------
hsync_and_gate_process: process (CLK_3_25_M, RESETn)

variable hsyncn_counter: integer;
 
begin
    if (RESETn = '0' or i_vsync = '1') then
        hsyncn_counter := 0;
        char_line_cntr <= (others => '0');
        i_hsyncn <= '1';
    -- Sur chaque front descendant de l'horloge 3,25 MHz
    elsif rising_edge(CLK_3_25_M) then
        hsyncn_counter := hsyncn_counter + 1;
        -- 192 cycles d'horloge à 3,25 MHz
        -- Duree pulse HSYNC = (207 - 192) @3,25 MHz = 4,6 µs 
        if hsyncn_counter >= FB_PORCH_OFF_DURATION and hsyncn_counter < FB_PORCH_OFF_DURATION + HSYNC_PULSE_ON_DURATION then  
            i_hsyncn <= '0';
        elsif hsyncn_counter = FB_PORCH_OFF_DURATION + HSYNC_PULSE_ON_DURATION then
            i_hsyncn <= '1';
            char_line_cntr <= char_line_cntr + 1;
            hsyncn_counter := 0;
        end if;
    end if;
    
    i_hsyncn_cnt <= hsyncn_counter;
    
end process;

-- Nouvelle version utilisant des fonctions combinatoires pour
-- le décodage des adresses.
p_cpu_data_in : process (Cpu_Addr, RDn, MREQn, IORQn, RFRSHn, D_ram_out, D_rom_out, TAPE_IN, USA_UK, KBDn)
begin
    -- MREQn = '0' and RFRSHn = '0' pour tenir compte du mode HiRes où l'on doit pouvoir lire des patterns
    -- video à partir de la RAM et pas seulement de la ROM.
    if (MREQn = '0' and RDn = '0') or (MREQn = '0' and RFRSHn = '0') then
        -- Cycle de lecture RAM / ROM
        case Cpu_Addr(15 downto 13) is
            -- Adressage de la ROM
            when "000" =>
                i_d_cpu_in <= D_rom_out;
            -- Adressage de la RAM 
            when "001"|"010"|"011"|"100"|"101" =>
                i_d_cpu_in <= D_ram_out;
            -- NOP execution ?
            when "110"|"111" =>
                -- NOP uniquement si le bit 6 = 0 (sinon c'est une instruction de HALT et on la laisse passer)
                if D_ram_out(6) = '0' then
                    i_d_cpu_in <= X"00";
                else
                    i_d_cpu_in <= D_ram_out;
                end if;
             when others =>
                    i_d_cpu_in <= (others => 'X');
        end case;
    elsif (IORQn = '0' and Cpu_Addr(0) = '0' and RDn = '0') then
        -- IO inputs
        i_d_cpu_in <= TAPE_IN & USA_UK & '0' & KBDn(0) & KBDn(1) & KBDn(2) & KBDn(3) & KBDn(4);
    -- else
    --     i_d_cpu_in <= (others => 'X');
    end if;
end process;

D_cpu_in <= i_d_cpu_in;

-- Detection NOP =>  on stockera le pattern video sera lu dans la ROM dans la RAM VGA
i_nop_detect <= '1' when (M1n = '0' and MREQn = '0' and RDn = '0' and HALTn = '1' and Cpu_Addr(15 downto 14) = "11" and D_ram_out(6) = '0') else '0';

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
        if IORQn = '0' and Cpu_Addr(0) = '0' and RDn = '0' and i_nmionn = '1' then
            i_vsync <= '1';
        -- Clear VSYNC (OUT NN)
        elsif IORQn = '0' and WRn = '0' then
            i_vsync <= '0';
        end if;
    end if;    
end process;

p_vsync_pulse_duration_counter : process(RESETn, CLK_3_25_M)
begin
    if RESETn = '0' or i_csyncn = '1' then
        i_csync_pulse_duration <= 0;
        i_vsync_frame_detect <= '0';
    -- On compte la durée du pulse de VSYNC pour savoir si c'est uyne vraie synchro trame ou pas
    -- (cas du ZX81 en mode pseudo-hires avec invaders ou pacman)
    elsif rising_edge(CLK_3_25_M) then
        i_csync_pulse_duration <= i_csync_pulse_duration + 1;
        if i_csync_pulse_duration >= MIN_VSYNC_PULSE_DURATION then
            i_vsync_frame_detect <= '1';
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
        if IORQn = '0' and WRn = '0' and Cpu_Addr(1) = '0' then
            i_nmionn <= '1';
        -- Enable NMIn (OUT FE)
        elsif IORQn = '0' and WRn = '0' and Cpu_Addr(0) = '0' then
            i_nmionn <= '0';
        end if;
    end if;
end process;

-----------------------------------------------------
-- Process pour le heart beat (allumage LED)
-----------------------------------------------------
p_vsync_hb : process (RESETn, CLK_3_25_M, IORQn)

variable i_vsync_counter : integer;
variable i_heart_beat : std_logic;

begin
    if (RESETn = '0') then
        i_heart_beat := '0';
        i_vsync_counter := VSYNC_COUNTER_PERIOD;
    -- Sur chaque front descendant de l'horloge 6.5 MHz
    elsif rising_edge(CLK_3_25_M) then
        i_vsync_0 <= i_vsync_frame_detect;
        i_vsync_1 <= i_vsync_0;
        -- Compteur de heart beat pour faire clignoter la LED sur le CMOD S7. 
        -- Détection transtion 1 -> 0
        if i_vsync_1 = '1' and i_vsync_0 = '0' then
            i_vsync_counter := i_vsync_counter - 1;
            if  i_vsync_counter = 0 then
                i_vsync_counter := VSYNC_COUNTER_PERIOD;
                i_heart_beat := not i_heart_beat;
            end if;
        end if;
    end if;
    
    vsync_heart_beat <= i_heart_beat;
    
end process;
        
nop_detect_process: process (CLK_3_25_M)
begin
    if rising_edge(CLK_3_25_M) then
        -- Le signalde NOP est décalé de 2 périodes de 3,25 MHz
        -- pour se caler sur les cycles CPU T3 et T4
        i_nop_detect_0 <= i_nop_detect;
        -- Le signal est aligné sur les cycle T3 et T4 de l'execution en RAM pour l'affichage video
        i_addr_enable_for_vid_pattern <= i_nop_detect_0;
        -- Si NOP detect, on lit le caractère dans la RAM
        if i_nop_detect = '1' then
            char_reg <= D_ram_out;
        end if;
    end if;
end process;

-- Dans le cas où il y a une détection de NOP, l'adresse à utiliser est celle construite pour accéder au pattern video.
-- Dans les autres cas c'est une adresse utilisée par le Z80.
Mem_Addr <= Cpu_Addr(15 downto 9) & char_reg(5 downto 0) & std_logic_vector(char_line_cntr) when i_addr_enable_for_vid_pattern = '1' else Cpu_Addr;

TAPE_OUT <= not i_vsync;

-- Explications issue de la page https://quix.us/timex/rigter/ZX97lite.html
-- En slow mode, le Z80 est interrompu toutes les 64 us par la NMI. La procédure d'interruption (en 0x0066)
-- compte le nombre de lignes restantes pour commencer l'affichage vidéo.
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
