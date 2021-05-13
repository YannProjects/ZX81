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
-- Additional Comments:
-- 
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
           
           M1n : in STD_LOGIC;
           RDn : in STD_LOGIC;
           WRn : in STD_LOGIC;
           HALTn : in STD_LOGIC;
           IORQn : in STD_LOGIC;
           NMIn : out STD_LOGIC;
           MREQn : in STD_LOGIC;
           RFRSHn : in std_logic;
           NOP_Detect : out std_logic;

           CSYNCn : out std_logic;
           SEROUT : out std_logic;
           iorq_heart_beat : out std_logic;
           
           KBDn : in STD_LOGIC_VECTOR (4 downto 0); -- Keyboard input
           TAPE_IN : in STD_LOGIC;
           USA_UK : in STD_LOGIC
         );
end vid_state_machine;

architecture Behavioral of vid_state_machine is

    type sm_video_state is (wait_for_new_cpu_cycle, wait_for_m1_read, wait_for_m1_rfrsh, wait_for_m1_mreq);
    signal i_hsyncn, i_vsync, i_nmionn, i_porch_gate: std_logic;
    signal line_cntr: natural range 0 to 7;

    signal debug_state_m : sm_video_state;
    
begin
  
hsync_process: process (clk, RSTn)

variable porch_gate_and_hsyncn_counter: natural range 0 to 1023;
variable new_line : std_logic;
 
begin
    if (RSTn = '0') then
        porch_gate_and_hsyncn_counter := 0;
        line_cntr <= 0;
        i_hsyncn <= '1';
        -- Signal utiliser pour forcer la sortie video au niveau 0
        -- pour les front porch et back porch sur chaque top ligne.
        -- Le signal i_porch_gate "encadre" le signal HSYNC avant (2 µs) et après le top ligne (5 µs).
        -- Voir http://f5ad.free.fr/ATV-QSP_F5AD_Le_signal_video.htm pour les valeurs
        i_porch_gate <= '1';
        new_line := '0';
    -- Sur chaque front descendant de l'horloge 6.5 MHz
    elsif falling_edge(clk) then
        -- Generateur de HSYNC
        porch_gate_and_hsyncn_counter := porch_gate_and_hsyncn_counter + 1;
        -- 384 cycles d'horloge à 6.5 MHz = 59 µs
        -- Duree pulse HSYNC = (414 - 384) @6.5 MHz = 4,6 µs 
        if i_vsync = '1' then
             -- Compteur de ligne utilisé pour indexé les pattern vdéo en R 
             line_cntr <= 0;
        end if;

        -- Back /Front porch OFF
        if porch_gate_and_hsyncn_counter >= (FB_PORCH_OFF_DURATION + FRONT_PORCH_ON_DURATION + HSYNC_PULSE_ON_DURATION + BACK_PORCH_ON_DURATION) then
            porch_gate_and_hsyncn_counter := 0;
            i_porch_gate <= '1';
        -- HSYNCn OFF
        elsif porch_gate_and_hsyncn_counter >= (FB_PORCH_OFF_DURATION + FRONT_PORCH_ON_DURATION + HSYNC_PULSE_ON_DURATION) then
            i_hsyncn <= '1';
            new_line := '1';
        -- HSYNCn ON   
        elsif porch_gate_and_hsyncn_counter >= (FB_PORCH_OFF_DURATION + FRONT_PORCH_ON_DURATION) then
            i_hsyncn <= '0';
            if new_line = '1' then
                line_cntr <= (line_cntr + 1) mod 8;
                new_line := '0';
            end if;
        -- Back /Front porch ON
        elsif porch_gate_and_hsyncn_counter >= (FB_PORCH_OFF_DURATION) then
            i_porch_gate <= '0';                      
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
  

        
video_state_machine_process: process (clk, RSTn)
    variable state_m : sm_video_state := wait_for_new_cpu_cycle;
    variable i_nop_detect, invert_video : std_logic := '0';
    variable char_reg, vid_pattern : std_logic_vector(7 downto 0);
    variable iorq_counter : integer := 0;
    variable iorq_heart_beat_tmp : std_logic := '0';
    
begin
    if (RSTn = '0') then
        state_m := wait_for_new_cpu_cycle;
        i_nop_detect := '0';
        char_reg := X"00";
        vid_pattern := X"00";
        iorq_heart_beat <= '0';
        i_vsync <= '1';
    -- Sur chaque front descendant de l'horloge 6.5 MHz
    elsif falling_edge(clk) then       
        -- Shift out most significant bit (video out)
        -- La vidéo est inversé. Sur le schéma du ZX97 Lite, il y a un montage émetteur commun qui
        -- inverse le signal. Pas dans mon cas où c'est un montage collecteur commun non inverseur
        -- => On inverse le signal directement
        -- Il est gaté avec le signal de back/front porch qui encadre le signal HSYNCn
        SEROUT <= not (vid_pattern(7)) and i_porch_gate;
        vid_pattern := vid_pattern(6 downto 0) & '0';
        case state_m is
             when wait_for_new_cpu_cycle =>
                -- Identification du cycle CPU en cours:
                -- Si M1 = 0 => c'est un cycle d'execution et il faut traiter le cas
                -- de l'execution des NOP et de la lecture / rechargement du pattern video
                -- Si IORQn = 0 => cycle I/O. En cas de lecture, on renvoie les entrees du clavier
                --                            En cas d'ecriture, on change l'etat du VSYNC
                -- Sinon, c'est un cycle de lecture ou ecriture, on positionne les adresses
                -- correspondantes en RAM ou RAM en fonction de l'adresse du CPU.  
                -- Cycle d'execution CPU
                if M1n = '0' then
                    -- Cycle M1 et que ce n'est pas une sortie de cycle HALT
                    if HALTn = '1' then
                        state_m := wait_for_m1_read;
                    else
                        state_m := wait_for_m1_rfrsh;
                    end if;
                -- Cycle I/O RD ou WR
                elsif IORQn = '0' then
                    -- IORQ heart beat qui inclut le VSYCN et aussi les lectures clavier + load cassette
                    -- Compteur de heart beat pour faire clignoter la LED sur le CMOD S7. 
                    iorq_counter := iorq_counter + 1;
                    if  iorq_counter >= IORQ_PERIOD then
                        iorq_counter := 0;
                        iorq_heart_beat_tmp := not iorq_heart_beat_tmp;
                    end if;
                    -------------------------------------------------------
                    -- D'apres le schema du ZX81 clone:
                    -- IORQ read et A0 = 0 et NMI_ONn = 1 => VSYNC = 1
                    -- IORQ write => VSYNC = 0
                    -- IORQ write et A0 = 0 => NMI_ONn = 0 (OUT_FEn)
                    -- IORQ write et A1 = 0 => NMI_ONn = 1 (OUT_FDn)
                    -- Par rapport à VSYNCn:
                    --          OUT_FEn => On interdit de mettre VSYNC = 1
                    --          OUT_FDn => On autorise de mettre VSYNC = 1
                    -------------------------------------------------------
                    --
                    -- IN FE detection           
                    if (A_cpu(0) = '0' and RDn = '0') then        
                        -- A remplacer par KBDn(0 to 4) ?
                        D_cpu_in <= TAPE_IN & USA_UK & '0' & KBDn(0) & KBDn(1) & KBDn(2) & KBDn(3) & KBDn(4);
                        if i_nmionn = '1' then
                            i_vsync <= '1';
                        end if;
                    elsif WRn = '0' then
                        i_vsync <= '0';

                        -- OUT FE, OUT FD detection
                        if (A_cpu(0) = '0') then
                            i_nmionn <= '0';
                        elsif (A_cpu(1) = '0') then
                            i_nmionn <= '1';
                        end if;
                    end if;
                -- Decodage adresses
                elsif MREQn = '0' then
                    -- Cycle de lecture RAM / ROM
                    if A_cpu(14) = '0' and A_cpu(15) = '0' then
                        D_cpu_IN <= D_rom_out;
                    -- Adressage de la RAM                            
                    elsif A_cpu(14) = '1' and A_cpu(15) = '0' then
                        D_cpu_IN <= D_ram_out;
                    end if;
                end if;
             -- Cycle d'execution M1
             when wait_for_m1_read =>
                if (RDn = '0' and MREQn = '0') then
                    -- Adressage de la ROM
                    if A_cpu(14) = '0' and A_cpu(15) = '0' then
                        D_cpu_IN <= D_rom_out;
                    -- Adressage de la RAM                            
                    elsif A_cpu(14) = '1' and A_cpu(15) = '0' then
                        D_cpu_IN <= D_ram_out;
                    -- NOP execution          
                    elsif A_cpu(14) = '1' and A_cpu(15) = '1' then
                        char_reg := D_ram_out;
                        -- NOP uniquement si le bit 6 = 0 (sinon c'est une instruction de HALT et on la laisse passer)
                        if char_reg(6) = '0' then
                            i_nop_detect := '1';
                            D_cpu_IN <= X"00";
                        else
                            D_cpu_IN <= D_ram_out;
                        end if;
                        -- Si le bit 7 est à 1, c'est l'inversion video
                        if char_reg(7) = '1' then
                            invert_video := '1';
                        end if;
                    end if;
                    state_m := wait_for_m1_rfrsh;
                end if;
             when wait_for_m1_rfrsh =>
                if RFRSHn = '0' then
                    if i_nop_detect = '1' then
                        -- Si c'est un cycle de NOP, on lit le pattern video à partir de la ROM
                        -- en construisant l'adresse à partir du caractère à afficher et du numero
                        -- de ligne en cours.
                        A_vid_pattern <= A_cpu(15 downto 9) & char_reg(5 downto 0) & std_logic_vector(to_unsigned(line_cntr,3));
                    end if;
                    state_m := wait_for_m1_mreq;
                end if;
             when wait_for_m1_mreq =>                    
                if MREQn = '0' then
                    if i_nop_detect = '1' then
                        if (invert_video = '0') then
                            vid_pattern := D_rom_out;
                        else
                            vid_pattern := not D_rom_out;
                        end if;
                    end if;
                    invert_video := '0';
                    i_nop_detect := '0';
                    state_m := wait_for_new_cpu_cycle;                       
                end if;
             when others =>
                    state_m := wait_for_new_cpu_cycle;
            end case;
    end if;
    
    NOP_Detect <= i_nop_detect;
    debug_state_m <= state_m;
    iorq_heart_beat <= iorq_heart_beat_tmp;
    
end process;

CSYNCn <= i_hsyncn and not i_vsync;
NMIn <= i_nmionn or i_hsyncn;
D_ram_in <= D_cpu_out;

end Behavioral;