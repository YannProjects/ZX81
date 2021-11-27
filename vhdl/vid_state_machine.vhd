----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09.08.2020 17:18:30
-- Design Name: 
-- Module Name: vid_state_machine - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- 
-- 27-11-2021: Suppression partie video composite pour ne garder que la partie VGA
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
-- library UNISIM;
-- use UNISIM.VComponents.all;
use work.ZX81_Pack.all;

entity vid_state_machine is
    Port ( clk : in STD_LOGIC;
           RSTn : in STD_LOGIC;
           A_cpu : in std_logic_vector (15 downto 0); -- CPU address bus to ULA. Input from ULA side
           A_vid_pattern : out std_logic_vector (15 downto 0); -- Address bus to RAM/ROM memories. Output from ULA side
           -- Separation bus donnees RAM/ROM
           -- L'idée est que l'ULA se charge de transformer les données avant de les renvoyer au CPU:
           -- NOP, lecture pattern caractères en ROM,...         
           D_cpu_IN : out STD_LOGIC_VECTOR (7 downto 0); -- CPU data bus IN. Output from ULA side
           D_cpu_OUT : in STD_LOGIC_VECTOR (7 downto 0); -- CPU data bus OUT. Input from ULA side
           D_ram_in : out STD_LOGIC_VECTOR (7 downto 0); -- RAM input data bus. Output from ULA side
           D_ram_out : in STD_LOGIC_VECTOR (7 downto 0); -- RAM output data bus. Input for ULA side
           D_rom_out : in STD_LOGIC_VECTOR (7 downto 0); -- ROM ouput data bus. Input for ULA side
           
           -- Adresse et data vidéo pour le controlleur VGA
           vga_addr : out std_logic_vector(13 downto 0);
           vga_data : out std_logic_vector(7 downto 0);  
           vga_wr_cyc : out STD_LOGIC; 
           
           M1n : in STD_LOGIC;
           RDn : in STD_LOGIC;
           WRn : in STD_LOGIC;
           HALTn : in STD_LOGIC;
           IORQn : in STD_LOGIC;
           NMIn : out STD_LOGIC;
           MREQn : in STD_LOGIC;
           RFRSHn : in std_logic;
           NOP_Detect : out std_logic;

           SEROUT : out std_logic;
           iorq_heart_beat : out std_logic;
           
           KBDn : in STD_LOGIC_VECTOR (4 downto 0); -- Keyboard input
           TAPE_IN : in STD_LOGIC;
           USA_UK : in STD_LOGIC
         );
end vid_state_machine;

architecture Behavioral of vid_state_machine is

    type sm_video_state is (wait_for_nop_detection, wait_for_m1_rfrsh, wait_for_vid_data);
    signal i_hsyncn, i_vsync, i_nmionn, i_porch_gate: std_logic;
    signal char_line_cntr : unsigned(2 downto 0);
    signal char_reg : std_logic_vector(7 downto 0);

    signal debug_state_m : sm_video_state;
    signal pixel_cnt_line_start, i_vga_addr_line_start, pixel_offset_dbg : unsigned(13 downto 0);
    
    signal porch_gate_and_hsyncn_counter: natural;
    
    signal iorqn_0, iorqn_1 : std_logic;
    signal i_nop_detect, i_nop_trigger_0, i_nop_trigger_1 : std_logic;
    
    signal state_m : sm_video_state := wait_for_nop_detection;
    signal i_vga_data : std_logic_vector(7 downto 0);
    signal i_wr_cyc : std_logic := '0';
    signal i_vga_addr : unsigned(12 downto 0);
   
begin

---------------------------------------------------------------------
-- Process pour la génération du HSYNC et de la gate vidéo
-- Aussi, génération cu compteur de pixel par rapport au début de ligne et du compteur de lignes
---------------------------------------------------------------------
hsync_and_gate_process: process (clk, RSTn)

variable porch_gate_and_hsyncn_counter: natural := 0;
variable i_porch_gate_next_value, i_hsyncn_next_value : std_logic;
 
begin
    if (RSTn = '0') then
        porch_gate_and_hsyncn_counter := 0;
        char_line_cntr <= "000";
        i_hsyncn <= '1';
        -- Signal utiliser pour forcer la sortie video au niveau 0
        -- pour les front porch et back porch sur chaque top ligne.
        -- Le signal i_porch_gate "encadre" le signal HSYNC avant (2 µs) et après le top ligne (5 µs).
        -- Voir http://f5ad.free.fr/ATV-QSP_F5AD_Le_signal_video.htm pour les valeurs
        i_porch_gate <= '1';
    -- Sur chaque front descendant de l'horloge 6.5 MHz
    elsif rising_edge(clk) then
        -- 384 cycles d'horloge à 6.5 MHz = 59 µs
      -- Duree pulse HSYNC = (414 - 384) @6.5 MHz = 4,6 µs 
        if i_vsync = '1' then
            -- Si VSYNC = 1, il faut resetter le compteur de lignes pour garder la synchronisation avec
            -- le pulse de VSYNC
            char_line_cntr <= "000";
            porch_gate_and_hsyncn_counter := 0;
            i_vga_addr_line_start <= (others => '0');
        else
            pixel_cnt_line_start <= pixel_cnt_line_start + 1;
            -- Generateur de HSYNC
            porch_gate_and_hsyncn_counter := porch_gate_and_hsyncn_counter + 1;
            case porch_gate_and_hsyncn_counter is
                -- Back /Front porch ON
                when FB_PORCH_OFF_DURATION =>
                    i_porch_gate <= '0';
                -- HSYNCn ON 
                when FB_PORCH_OFF_DURATION + FRONT_PORCH_ON_DURATION =>
                    i_hsyncn <= '0';
                    char_line_cntr <= char_line_cntr + 1;
                    pixel_cnt_line_start <= (others => '0');
                    -- i_vga_addr_line_start <= i_vga_addr_line_start + 64;
                    i_vga_addr_line_start <= i_vga_addr_line_start + X"20";
                -- HSYNCn OFF
                when FB_PORCH_OFF_DURATION + FRONT_PORCH_ON_DURATION + HSYNC_PULSE_ON_DURATION => 
                    i_hsyncn <= '1';
                -- Back /Front porch OFF
                when FB_PORCH_OFF_DURATION + FRONT_PORCH_ON_DURATION + HSYNC_PULSE_ON_DURATION + BACK_PORCH_ON_DURATION =>
                    porch_gate_and_hsyncn_counter := 0;
                    i_porch_gate <= '1';
                when others =>
                    null;
            end case;
        end if;
    end if;
end process;

-- Processs utilise pour supprimer les pulse parasites de l'entrée MIC
-- Si le niveau du pulse reste le même pendant plus de 100 µs, on valide le niveau, sinon, on ne fait rien.
-- 100 µs @ 6,5 Mhz =  650
-- mic_cleaner: process (clk, RSTn)
-- 
-- variable pulse_duration: natural range 0 to 1023;
-- variable prev_tape_in_raw: std_logic := '0';
-- 
-- begin
--     if (RSTn = '0') then
--         CLEAN_TAPE_IN <= '0';
--         pulse_duration := 0;
--         prev_tape_in_raw := '0';
--     -- Sur chaque front descendant de l'horloge 6.5 MHz
--     elsif falling_edge(clk) then
--       if TAPE_IN /= prev_tape_in_raw then
--         -- The input just changed.  Reset the timeout.
--         pulse_duration := PULSE_DURATION_THRESHOLD;
--       elsif pulse_duration /= 0 then
--         -- Input stable, but timer not yet expired.  Keep timing.
--         pulse_duration := pulse_duration - 1;
--       else
--         -- Input stable, and counter has expired.  Update the output.
--         CLEAN_TAPE_IN <= prev_tape_in_raw;
--       end if;
--       -- Keep track of the most recent input.
--       prev_tape_in_raw := TAPE_IN;
--     end if;    
-- end process;

    
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
p_vsync : process(clk)
begin
    if rising_edge(clk) then
        -- Enable VSYNC (IN FE)
        if A_cpu(0) = '0' and RDn = '0' and IORQn = '0' and i_nmionn = '1' then
            i_vsync <= '1';
        -- Clear VSYNC (OUT NN)
        elsif IORQn = '0' and WRn = '0' then
            i_vsync <= '0';
        end if;
    end if;
end process;

p_nmi : process(clk)
begin
    if rising_edge(clk) then
        -- Clear NMIn (OUT FD)
        if IORQn = '0' and WRn = '0' and A_cpu(1) = '0' then
            i_nmionn <= '1';
        -- Enable NMIn (OUT FE)
        elsif IORQn = '0' and WRn = '0' and A_cpu(0) = '0' then
            i_nmionn <= '0';
        end if;
    end if;
end process;

----------------------------------------
-- Process pour le heart beat IORQn
----------------------------------------
p_iorq_hb : process (RSTn, clk, IORQn)

variable iorq_counter : unsigned(15 downto 0);
variable i_iorq_heart_beat : std_logic;

begin
    if (RSTn = '0') then
        i_iorq_heart_beat := '0';
        iorq_counter := IORQ_PERIOD;
        iorqn_1 <= '1';
    -- Sur chaque front descendant de l'horloge 6.5 MHz
    elsif rising_edge(clk) then
        iorqn_0 <= IORQn;
        iorqn_1 <= iorqn_0;
        -- IORQ heart beat qui inclut le VSYCN et aussi les lectures clavier + load cassette
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
    
video_state_machine_process: process (clk, RSTn)

variable vid_pattern : std_logic_vector(7 downto 0);
variable byte_offset, pixel_offset : unsigned(13 downto 0); 


begin
    if (RSTn = '0') then
        state_m <= wait_for_nop_detection;
    -- Sur chaque front descendant de l'horloge 6.5 MHz
    elsif rising_edge(clk) then       
        vid_pattern := vid_pattern(6 downto 0) & '0';

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
                    vid_pattern := not D_rom_out;
                else
                    vid_pattern := D_rom_out;
                end if;

                -- 109 pixel par rapport au début de la ligne
                pixel_offset := pixel_cnt_line_start - PIXEL_OFFSET_FROM_LINE_START;
                byte_offset := "000000" & pixel_offset(10 downto 3);
                -- Signaux pour le controlleur VGA
                vga_addr <= std_logic_vector(i_vga_addr_line_start - X"400" + byte_offset);
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

NMIn <= i_nmionn or i_hsyncn;
D_ram_in <= D_cpu_out;
SEROUT <= not i_vsync;

end Behavioral;
