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
-- 20-May-2023: Simplifications
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
           i_RESETn : in STD_LOGIC;

           i_CLK_3_25_M : in std_logic;
           i_CLK_6_5_M : in std_logic;
           i_CLK_13_M : in std_logic;
           i_Cpu_Addr : in std_logic_vector (15 downto 0); -- CPU address bus to ULA. Input from ULA side
           -- Separation bus addresse CPU et RAM/ROM
           o_Mem_Addr : out std_logic_vector (15 downto 0); -- RAM/ROM address. Output from ULA side
           -- Separation bus donnees RAM/ROM           
           o_D_cpu_IN : out STD_LOGIC_VECTOR (7 downto 0); -- CPU data bus IN. Output from ULA side
           i_D_ram_out : in STD_LOGIC_VECTOR (7 downto 0); -- RAM output data bus. Input for ULA side
           i_D_rom_out : in STD_LOGIC_VECTOR (7 downto 0); -- ROM ouput data bus. Input for ULA side
           -- Adresse et data vidéo pour le controlleur VGA
           o_vga_addr : out std_logic_vector(17 downto 0);
           o_vga_data : out std_logic_vector(1 downto 0);
           o_vga_wr_cyc : out STD_LOGIC;
           -- 
           i_KBDn : in STD_LOGIC_VECTOR (4 downto 0);
           i_TAPE_IN : in STD_LOGIC;
           i_USA_UK : in STD_LOGIC;
           o_TAPE_OUT : out STD_LOGIC;
           o_vsync_heart_beat : out std_logic; -- Heart beat pour la sortie video
           i_RDn : in STD_LOGIC;
           i_WRn : in STD_LOGIC;
           i_HALTn : in STD_LOGIC;
           i_IORQn : in STD_LOGIC;
           o_NMIn : out STD_LOGIC;
           i_MREQn : in STD_LOGIC;
           i_RFRSHn : in std_logic;
           i_M1n : in STD_LOGIC;
           o_WAITn : out std_logic
         );
end ULA;

architecture Behavioral of ULA is

    signal hsyncn, hsyncn0, hsyncn1, vsync, csyncn : std_logic;
    signal nmionn : std_logic;
    signal char_line_cntr : unsigned(2 downto 0);
    signal csync_pulse_duration : integer;
    signal char_reg, d_cpu_in : std_logic_vector(7 downto 0);
    signal nop_detect, nop_detect_0: std_logic;
     
    signal vga_addr_frame_offset, vga_pixel_offset, vga_line_offset  : integer;
    signal vga_wr : std_logic;
    
    signal vsync_0, vsync_1, nmin : std_logic;
    signal vsync_frame_detect : std_logic;
        
    signal hsyncn_cnt, vsync_counter : integer;
    signal vid_shift_register : std_logic_vector(7 downto 0);
    signal reload_vid_pattern : std_logic;
    signal heart_beat : std_logic;

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

p_vid_shift_register: process (i_CLK_13_M, i_RESETn)
begin
    if i_RESETn = '0' then
        vid_shift_register <= (others => '0');
        vga_line_offset <= 0;
    elsif falling_edge(i_CLK_13_M) then
        -- Sélection de la partie avec MREQn = 0 (cycle T4) durant laquelle il faut recharger le pattern video
        -- Dans le schema original du ZX81, le registre à decalage est recharge en fin de cycle T4 de l'execution en RAM video.
        -- C'est ce qui est reproduit ici en rechargeant le registre en fin de cycle T4 avec les conditions:
        -- MREQn = '0' and CLK_3_25_M = '0' and CLK_6_5_M = '0'
        -- (sur le front montant de l'horloge 13 MHz). 
        if i_MREQn = '0' and i_CLK_3_25_M = '0' and i_CLK_6_5_M = '0' and reload_vid_pattern = '1' then
            -- On resette le signal utilise pour adresser une ligne ou celle du dessous avec la même valeur.
            vga_line_offset <= 0;
            -- Caractere en inversion video ?
            if (char_reg(7) = '0') then
                -- Les pixels sont doublés car on les écrit 2 fois:
                -- 1 fois à l'adresse A pendant le 1er cycle à 13 MHz et l'autre fois à l'adresse A + NUMBER_OF_PIXELS_PER_LINE (= nombre de pixels dans une ligne)
                -- lors du second cycle de 13 MHz. Cette solution permet de doubler les lignes verticalement.
                vid_shift_register <= d_cpu_in;
            else
                vid_shift_register <= not d_cpu_in;
            end if;
        else
            if vga_line_offset = 0 then
                -- Ligne du dessous (1 cycle de 13 MHz sur 2)
                vga_line_offset <= NUMBER_OF_PIXELS_PER_LINE;
            else
                -- Ligne courante (1 cycle de 13 MHz sur 2)
                vga_line_offset <= 0;
                vid_shift_register <= vid_shift_register(6 downto 0) & '0';
          end if;

        end if;
    end if;
end process;

p_vga_pixel_addr_counter: process (i_CLK_6_5_M, vsync, hsyncn, i_RESETn)
begin
    if i_RESETn = '0' or hsyncn = '0' or vsync = '1' then
        -- On resette le nombre de pixel depuis le début de la ligne en cas de HSYNCn ou VSYNC
        vga_pixel_offset <= 0;
    elsif rising_edge(i_CLK_6_5_M) then
        -- On débute le comptage des pixels de ligne a partir du moment ou on a atteind
        -- la fin du pulse de VSYNC
        -- A remplacer par le signal CSYNCn        
        if hsyncn_cnt < FB_PORCH_OFF_DURATION then
            -- On incremente de 2 pixels pour doubler le nombre de pixels de ligne
            vga_pixel_offset <= vga_pixel_offset + 1;
        end if;
    end if;
end process;

p_vga_line_addr_counter: process (i_CLK_3_25_M, vsync_frame_detect, i_RESETn)
begin
    if (i_RESETn = '0' or vsync_frame_detect = '1') then
        vga_addr_frame_offset <= 0;
    -- Sur chaque front descendant de l'horloge 3,25 MHz
    elsif rising_edge(i_CLK_3_25_M) then
        hsyncn1 <= hsyncn;
        hsyncn0 <= hsyncn1;
        -- Detection front descendant composite sync (= HSYNC + VSYNC) 
        -- Dans le cas des jeux PACMAN et INVADERS en mode pseudo-hires, il y a des pulses de VSYNC courts pou resetter le compteur
        -- char_line_cntr. Cependant, il faut continuer à incrémenter le compteur de lignes i_vga_addr_frame_offset.
        -- Dans le cas d'un front descendat CSYNCn, on incrémente le compteur de lignes 
        if hsyncn0 = '1' and hsyncn1 = '0' then
            vga_addr_frame_offset <= vga_addr_frame_offset + 2*NUMBER_OF_PIXELS_PER_LINE;
        end if;
    end if;
end process;

csyncn <= not vsync and hsyncn;


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

o_vga_addr <= std_logic_vector(to_unsigned(vga_addr_frame_offset + vga_pixel_offset + vga_line_offset - FRAME_LINE_START - PIXEL_LINE_START, o_vga_addr'length));
o_vga_data <= vid_shift_register(7) & vid_shift_register(7);
o_vga_wr_cyc <= hsyncn and not vsync when vga_addr_frame_offset >= FRAME_LINE_START and 
                                            vga_pixel_offset >= PIXEL_LINE_START and
                                            vga_pixel_offset < PIXEL_LINE_STOP 
                                       else '0';

---------------------------------------------------------------------
-- Process pour la génération du HSYNC et de la gate vidéo
-- Aussi, génération du compteur de lignes par rapport au debut de la trame
---------------------------------------------------------------------
hsync_and_gate_process: process (i_CLK_3_25_M, i_RESETn)

variable hsyncn_counter: integer;
 
begin
    if (i_RESETn = '0' or vsync = '1') then
        hsyncn_counter := 0;
        char_line_cntr <= (others => '0');
        hsyncn <= '1';
    -- Sur chaque front descendant de l'horloge 3,25 MHz
    elsif rising_edge(i_CLK_3_25_M) then
        hsyncn_counter := hsyncn_counter + 1;
        -- 192 cycles d'horloge à 3,25 MHz
        -- Duree pulse HSYNC = (207 - 192) @3,25 MHz = 4,6 µs 
        if hsyncn_counter >= FB_PORCH_OFF_DURATION and hsyncn_counter < FB_PORCH_OFF_DURATION + HSYNC_PULSE_ON_DURATION then  
            hsyncn <= '0';
        elsif hsyncn_counter = FB_PORCH_OFF_DURATION + HSYNC_PULSE_ON_DURATION then
            hsyncn <= '1';
            char_line_cntr <= char_line_cntr + 1;
            hsyncn_counter := 0;
        end if;
    end if;
    
    hsyncn_cnt <= hsyncn_counter;
end process;
    

-- Nouvelle version utilisant des fonctions combinatoires pour
-- le décodage des adresses.
p_cpu_data_in : process (i_Cpu_Addr, i_RDn, i_MREQn, i_IORQn, i_RFRSHn, i_D_ram_out, i_D_rom_out, i_TAPE_IN, i_USA_UK, i_KBDn)
begin
    -- MREQn = '0' and RFRSHn = '0' pour tenir compte du mode HiRes où l'on doit pouvoir lire des patterns
    -- video à partir de la RAM et pas seulement de la ROM.
    if (i_MREQn = '0' and i_RDn = '0') or (i_MREQn = '0' and i_RFRSHn = '0') then
        -- Cycle de lecture RAM / ROM
        case i_Cpu_Addr(15 downto 13) is
            -- Adressage de la ROM
            when "000" =>
                d_cpu_in <= i_D_rom_out;
            -- Adressage de la RAM 
            when "001"|"010"|"011"|"100"|"101" =>
                d_cpu_in <= i_D_ram_out;
            -- NOP execution ?
            when "110"|"111" =>
                -- NOP uniquement si le bit 6 = 0 (sinon c'est une instruction de HALT et on la laisse passer)
                if i_D_ram_out(6) = '0' then
                    d_cpu_in <= X"00";
                else
                    d_cpu_in <= i_D_ram_out;
                end if;
             when others =>
                    d_cpu_in <= (others => 'X');
        end case;
    elsif (i_IORQn = '0' and i_Cpu_Addr(0) = '0' and i_RDn = '0') then
        -- IO inputs
        d_cpu_in <= i_TAPE_IN & i_USA_UK & '0' & i_KBDn(0) & i_KBDn(1) & i_KBDn(2) & i_KBDn(3) & i_KBDn(4);
    end if;
end process;

o_D_cpu_in <= d_cpu_in;

-- Detection NOP =>  on stockera le pattern video sera lu dans la ROM dans la RAM VGA
nop_detect <= '1' when (i_M1n = '0' and i_MREQn = '0' and i_RDn = '0' and i_HALTn = '1' and i_Cpu_Addr(15 downto 14) = "11" and i_D_ram_out(6) = '0') else '0';

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
p_vsync : process(i_RESETn, i_CLK_3_25_M)
begin
    if i_RESETn = '0' then
        vsync <= '0';
    -- On synchronise quand même avec l'horloge poursuivre les conseils de vivado 
    elsif rising_edge(i_CLK_3_25_M) then
        -- Enable VSYNC (IN FE)
        if i_IORQn = '0' and i_Cpu_Addr(0) = '0' and i_RDn = '0' and nmionn = '1' then
            vsync <= '1';
        -- Clear VSYNC (OUT NN)
        elsif i_IORQn = '0' and i_WRn = '0' then
            vsync <= '0';
        end if;
    end if;    
end process;

p_vsync_pulse_duration_counter : process(i_RESETn, i_CLK_3_25_M)
begin
    if i_RESETn = '0' or csyncn = '1' then
        csync_pulse_duration <= 0;
        vsync_frame_detect <= '0';
    -- On compte la durée du pulse de VSYNC pour savoir si c'est uyne vraie synchro trame ou pas
    -- (cas du ZX81 en mode pseudo-hires avec invaders ou pacman)
    elsif rising_edge(i_CLK_3_25_M) then
        csync_pulse_duration <= csync_pulse_duration + 1;
        if csync_pulse_duration >= MIN_VSYNC_PULSE_DURATION then
            vsync_frame_detect <= '1';
        end if;
    end if;
end process;

p_nmi : process(i_RESETn, i_CLK_3_25_M)
begin
    if i_RESETn = '0' then
        nmionn <= '1';
    -- On synchronise quand même avec l'horloge poursuivre les conseils de vivado        
    elsif rising_edge(i_CLK_3_25_M) then        
        -- Clear NMIn (OUT FD)
        if i_IORQn = '0' and i_WRn = '0' and i_Cpu_Addr(1) = '0' then
            nmionn <= '1';
        -- Enable NMIn (OUT FE)
        elsif i_IORQn = '0' and i_WRn = '0' and i_Cpu_Addr(0) = '0' then
            nmionn <= '0';
        end if;
    end if;
end process;

-----------------------------------------------------
-- Process pour le heart beat (allumage LED)
-----------------------------------------------------
p_vsync_hb : process (i_RESETn, i_CLK_3_25_M, i_IORQn)

begin
    if (i_RESETn = '0') then
        heart_beat <= '0';
        vsync_counter <= VSYNC_COUNTER_PERIOD;
    -- Sur chaque front descendant de l'horloge 6.5 MHz
    elsif rising_edge(i_CLK_3_25_M) then
        vsync_0 <= vsync_frame_detect;
        vsync_1 <= vsync_0;
        -- Compteur de heart beat pour faire clignoter la LED sur le CMOD S7. 
        -- Détection transtion 1 -> 0
        if vsync_1 = '1' and vsync_0 = '0' then
            vsync_counter <= vsync_counter - 1;
            if  vsync_counter = 0 then
                vsync_counter <= VSYNC_COUNTER_PERIOD;
                heart_beat <= not heart_beat;
            end if;
        end if;
    end if;
    
    o_vsync_heart_beat <= heart_beat;
    
end process;
        
nop_detect_process: process (i_CLK_3_25_M)
begin
    if rising_edge(i_CLK_3_25_M) then
        -- Le signalde NOP est décalé de 2 périodes de 3,25 MHz
        -- pour se caler sur les cycles CPU T3 et T4
        nop_detect_0 <= nop_detect;
        -- Le signal est aligné sur les cycle T3 et T4 de l'execution en RAM pour l'affichage video
        reload_vid_pattern <= nop_detect_0;
        -- Si NOP detect, on lit le caractère dans la RAM
        if nop_detect = '1' then
            char_reg <= i_D_ram_out;
        end if;
    end if;
end process;

-- Dans le cas où il y a une détection de NOP, l'adresse à utiliser est celle construite pour accéder au pattern video.
-- Dans les autres cas c'est une adresse utilisée par le Z80.
o_Mem_Addr <= i_Cpu_Addr(15 downto 9) & char_reg(5 downto 0) & std_logic_vector(char_line_cntr) when reload_vid_pattern = '1' else i_Cpu_Addr;

o_TAPE_OUT <= not vsync;

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
nmin <= nmionn or hsyncn;
o_NMIn <= nmin;
o_WAITn <= not i_HALTn or nmin;

end Behavioral;
