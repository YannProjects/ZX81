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
-- library UNISIM;
-- use UNISIM.VComponents.all;
use work.ZX81_Pack.all;

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
           -- Adresse et data vidéo pour le controlleur VGA
           vga_addr : out std_logic_vector(12 downto 0);
           vga_data : out std_logic_vector(7 downto 0);
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
           NOP_Detect : out std_logic;
           M1n : in STD_LOGIC;
           WAITn : out std_logic;
           RESETn : in STD_LOGIC
         );
end ULA;

architecture Behavioral of ULA is

    type sm_video_state is (wait_for_nop_detection, wait_for_m1_rfrsh, wait_for_vid_data);
    
    signal i_hsyncn, i_vsync, i_nmionn: std_logic;
    signal i_hsyncn_detect_0, i_hsyncn_detect_1 : std_logic;
    signal char_line_cntr : unsigned(2 downto 0);
    signal char_reg : std_logic_vector(7 downto 0);
    
    signal i_nop_detect, i_nop_detect_0, i_nop_detect_1 : std_logic;
    signal i_vga_line_counter, i_vga_char_offset : std_logic_vector(12 downto 0);
    
    signal iorqn_0, iorqn_1, i_nmin : std_logic;
    signal i_nop_trigger_0, i_nop_trigger_1 : std_logic;
    
    signal state_m : sm_video_state := wait_for_nop_detection;
    signal i_vga_data : std_logic_vector(7 downto 0);
    signal i_wr_cyc : std_logic := '0';
   
begin

---------------------------------------------------------------------
-- Process pour la génération du HSYNC et de la gate vidéo
-- Aussi, génération cu compteur de pixel par rapport au début de ligne et du compteur de lignes
---------------------------------------------------------------------
hsync_and_gate_process: process (CLK_6_5_M, RESETn)

variable hsyncn_counter: natural := 0;
 
begin
    if (RESETn = '0') then
        hsyncn_counter := 0;
        char_line_cntr <= "000";
        i_hsyncn <= '1';
    -- Sur chaque front descendant de l'horloge 6.5 MHz
    elsif rising_edge(CLK_6_5_M) then
        -- 384 cycles d'horloge à 6.5 MHz = 59 µs
        -- Duree pulse HSYNC = (414 - 384) @6.5 MHz = 4,6 µs 
        if i_vsync = '1' then
            -- Si VSYNC = 1, il faut resetter le compteur de lignes pour garder la synchronisation avec
            -- le pulse de VSYNC
            char_line_cntr <= "000";
            hsyncn_counter := 0;
        else
            -- Generateur de HSYNC
            hsyncn_counter := hsyncn_counter + 1;
            case hsyncn_counter is
                -- HSYNCn ON 
                when FB_PORCH_OFF_DURATION =>
                    i_hsyncn <= '0';
                    char_line_cntr <= char_line_cntr + 1;
                -- HSYNCn OFF
                when FB_PORCH_OFF_DURATION + HSYNC_PULSE_ON_DURATION =>
                    i_hsyncn <= '1';
                    hsyncn_counter := 0;
                when others =>
                    null;
            end case;
        end if;
    end if;
end process;
   
-- Nouvelle version utilisant des fonctions combinatoires pour
-- le décodage des adresses.
p_cpu_data_in : process (A_cpu, RDn, MREQn, IORQn, M1n)
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

-- Detection NOP
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
p_vsync : process(CLK_6_5_M)
begin
    if (RESETn = '0') then
        i_vsync <= '0';
    elsif rising_edge(CLK_6_5_M) then
        -- Enable VSYNC (IN FE)
        if IORQn = '0' and A_cpu(0) = '0' and RDn = '0' and i_nmionn = '1' then
            i_vsync <= '1';
        -- Clear VSYNC (OUT NN)
        elsif IORQn = '0' and WRn = '0' then
            i_vsync <= '0';
        end if;
    end if;
end process;

p_nmi : process(CLK_6_5_M)
begin
    if (RESETn = '0') then
        i_nmionn <= '1';
    elsif rising_edge(CLK_6_5_M) then
        -- Clear NMIn (OUT FD)
        if IORQn = '0' and WRn = '0' and A_cpu(1) = '0' then
            i_nmionn <= '1';
        -- Enable NMIn (OUT FE)
        elsif IORQn = '0' and WRn = '0' and A_cpu(0) = '0' then
            i_nmionn <= '0';
        end if;
    end if;
end process;

-- Process pour le comptage des ligne pour l'affichage VGA
p_vga_line_counter : process(CLK_6_5_M, i_hsyncn, i_vsync)
begin
    if (RESETn = '0' or i_vsync = '1') then
        i_vga_line_counter <= (others => '0');
    -- Sur chaque front montant de l'horloge 6.5 MHz
    elsif rising_edge(CLK_6_5_M) then
        i_hsyncn_detect_0 <= i_hsyncn;
        i_hsyncn_detect_1 <= i_hsyncn_detect_0;
        -- Transition HSYNC 0 -> 1
        -- On compte tous les plulses de synchro horizontale à partir de la fin du A_cpu
        -- L'écran est en fait plus grand que la taille nécessaire (512 x 480 au lieu 512 x 384 avec les lignes et colonnes doublées).
        -- Ca permet de tenir compte du mode "FAST" et des variations du nombre de pulses de HSYNC avant l'affichage qui paraît varier
        -- en fonction des logiciels utilisés...
        -- Cette solution fonctionnne bien. Il faudrait juste rajouter un rafraichissement de l'écran au cas où un logiciel
        -- utilisant un nombre de HSYNC est utilisé après un autre utilisant une autre valeur. Mai, bon, on verra...
        if i_hsyncn_detect_0 = '1' and i_hsyncn_detect_1 = '0' then
            i_vga_line_counter <= i_vga_line_counter + X"20";
        end if;
    end if;
end process;

-- Process pour le comptage des pixels entre le début de la synchro ligne et le début de l'exécution en RAM A_cpu
-- (devrait correspondre au nombre de pixel entre la synchro ligne et lé début de l'afficahge...
p_vga_char_counter : process(CLK_6_5_M, i_hsyncn)
begin
    if (RESETn = '0' or i_hsyncn = '0') then
        i_vga_char_offset <= (others => '0');
    -- Sur chaque front descendant de l'horloge 6.5 MHz
    elsif rising_edge(CLK_6_5_M) then
        i_nop_detect_0 <= i_nop_detect;
        i_nop_detect_1 <= i_nop_detect_0;
        if i_nop_detect_0 = '1' and i_nop_detect_1 = '0' then
             i_vga_char_offset <= i_vga_char_offset + 1;
        end if;
    end if;
end process;


----------------------------------------
-- Process pour le heart beat IORQn
----------------------------------------
p_iorq_hb : process (RESETn, CLK_6_5_M, IORQn)

variable iorq_counter : unsigned(15 downto 0);
variable i_iorq_heart_beat : std_logic;

begin
    if (RESETn = '0') then
        i_iorq_heart_beat := '0';
        iorq_counter := IORQ_PERIOD;
        iorqn_1 <= '1';
    -- Sur chaque front descendant de l'horloge 6.5 MHz
    elsif rising_edge(CLK_6_5_M) then
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
    
video_state_machine_process: process (CLK_6_5_M, RESETn)

variable vid_pattern : std_logic_vector(7 downto 0);
variable byte_offset, pixel_offset : unsigned(13 downto 0); 


begin
    if (RESETn = '0') then
        state_m <= wait_for_nop_detection;
        vga_addr <= (others => '0');
    -- Sur chaque front descendant de l'horloge 6.5 MHz
    elsif rising_edge(CLK_6_5_M) then
        case state_m is
             when wait_for_nop_detection =>
                vga_wr_cyc <= '0';
                i_nop_trigger_0 <= i_nop_detect;
                i_nop_trigger_1 <= i_nop_trigger_0;
                -- Detection front montant i_nop_detect
                if i_nop_trigger_0 = '1' and i_nop_trigger_1 = '0' then
                    -- Char reg contient le caractère à afficher présent dans la RAM vidéo.
                    char_reg <= D_ram_out;
                    state_m <= wait_for_m1_rfrsh;
                else
                    state_m <= wait_for_nop_detection;
                end if;
                
             when wait_for_m1_rfrsh =>
                if RFRSHn = '0' then
                    -- Si c'est un cycle de NOP, on lit le pattern video à partir de la ROM
                    -- en construisant l'adresse à partir du caractère à afficher et du numero
                    -- de ligne en cours.
                    A_vid_pattern <= A_cpu(15 downto 9) & char_reg(5 downto 0) & std_logic_vector(char_line_cntr);
                    state_m <= wait_for_vid_data;
                else
                    state_m <= wait_for_m1_rfrsh;
                end if;
                   
             when wait_for_vid_data =>
                -- Lecture pattern vidéo
                if (char_reg(7) = '0') then
                    vid_pattern := D_rom_out;
                else
                    vid_pattern := not D_rom_out;
                end if;

                byte_offset := "000000" & pixel_offset(10 downto 3);
                -- Signaux pour le controlleur VGA
                vga_addr <= i_vga_line_counter - X"20" + i_vga_char_offset - X"1";
                vga_wr_cyc <= '1';
                vga_data <= vid_pattern;
                state_m <= wait_for_nop_detection;
                
             when others =>
                state_m <= wait_for_nop_detection;
            end case;
    end if;
    
    -- Le signal de detection de NOP doit s'étendre jusqu'au cycle de refresh pour permettre
    -- la lecture en ROM du pattern vidéo
    -- => On utilise i_nop_trigger_0 plutôt que i_nop_detect qui est étendu grâce à la machine d'état.
    NOP_Detect <= i_nop_trigger_0;

end process;

D_ram_in <= D_cpu_out;
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
