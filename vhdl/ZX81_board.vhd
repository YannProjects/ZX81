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
use unisim.vcomponents.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
-- library UNISIM;
-- use UNISIM.VComponents.all;

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
           
           R_VGA_0 : out STD_LOGIC;
           R_VGA_1 : out STD_LOGIC;
           R_VGA_2 : out STD_LOGIC;

           G_VGA_0 : out STD_LOGIC;
           G_VGA_1 : out STD_LOGIC;
           G_VGA_2 : out STD_LOGIC;
           
           B_VGA_0 : out STD_LOGIC;
           B_VGA_1 : out STD_LOGIC;
           B_VGA_2 : out STD_LOGIC;
           
           -- Signaux de debug
           -- Debug : out std_logic_vector(5 downto 0)
                      
           -- LEDs embarquées sur le CMOD S7
           -- LED_1 -> E2 : IORQn_Heart_Beat
           -- LED_2 -> K1 : Non utilisée
           -- LED_3 -> J1 : Non utilisée
           -- LED_4 -> E1 : Non utilisée
           Iorq_Heart_Beat : out std_logic;
           
           Dbg : out std_logic_vector(7 downto 0)
          
         );
end ZX81_board;

architecture Behavioral of ZX81_board is

    component dist_mem_gen_0 IS
    port (
        a : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
        spo : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
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
    signal i_busackn, i_m1n, i_mreqn, i_iorqn, i_tape_in : std_logic;
    signal i_rdn, i_wrn, i_wrram, i_rfrshn, i_haltn, i_nop_detect : std_logic;
    signal i_a_cpu, i_a_vid_pattern,i_a_rom : std_logic_vector (15 downto 0);
    signal i_d_cpu_out, i_d_cpu_in, i_d_ram_in, i_d_ram_out, i_d_rom_out : std_logic_vector (7 downto 0);
    signal i_clk_52m, i_clk_6_5m, i_clk_6_5mn, i_clk_6_5mn_buf, i_clk_3_25m : std_logic;
    signal i_resetn : std_logic;
    signal i_kbd_l_swap : std_logic_vector(4 downto 0);
    -- VGA
    signal i_vga_clock, i_pll_locked : std_logic;
    signal i_vga_addr: std_logic_vector(13 downto 0);
    signal i_vga_data: std_logic_vector(7 downto 0);
    signal i_vga_wr_cyc, i_vga_control_init_done : std_logic;
    
    signal R_VGA, G_VGA, B_VGA : std_logic_vector(7 downto 0);
    signal BLANK_VGA : std_logic;
    
    -- attribute mark_debug : string;
    -- attribute mark_debug of KBD_C : signal is "true";
    -- attribute mark_debug of KBD_L : signal is "true";
    -- attribute mark_debug of i_iorqn : signal is "true";
    -- attribute mark_debug of i_wrram : signal is "true";
    -- attribute mark_debug of i_d_ram_out : signal is "true";
    -- attribute mark_debug of i_a_cpu : signal is "true";
    -- attribute mark_debug of i_m1n : signal is "true";
    -- attribute mark_debug of i_tape_in : signal is "true";
    -- attribute mark_debug of i_d_cpu_in : signal is "true";
    -- attribute mark_debug of i_clk_3_25m : signal is "true";
    
    type sm_input_kbd is (debounce_push_button, envoi_code_clavier);
    
    signal push_button_state_m : sm_input_kbd := debounce_push_button;
    
    begin
        
        clk_gen_0 : entity work.Clocks_gen
        port map (
            main_clk => CLK_12M,
            clk_52m => i_clk_52m,
            clk_3_25m => i_clk_3_25m,
            clk_6_5m => i_clk_6_5m,
            vga_clk => i_vga_clock,
            rst => RESET,
            pll_locked => i_pll_locked
        );
        
        --
        -- Process temporaire utilisé pour remplacer le clavier du PCB v3 qui ne fonctionne pas
        -- A chauqe appui détecté sur le bouton B1, on simulé l'appui d'un touche qui correspond
        -- à un mot clé prédéfini
        p_push_button: process (i_clk_6_5m, i_resetn, PUSH_BUTTON, i_a_cpu, i_iorqn, i_rdn)
        
        variable compteur_debounce, code_index : integer; 
        
        begin
           if i_resetn = '0' then
                compteur_debounce := 0;
                code_index := 0;
                push_button_state_m <= debounce_push_button;
                i_kbd_l_swap <= B"11111";
           elsif rising_edge(i_clk_6_5m) then
                i_kbd_l_swap <= B"11111";
                case push_button_state_m is
                    when debounce_push_button =>                        
                        -- Appui sur bouton 1 détecté et lecture clavier
                        if PUSH_BUTTON = '1' and i_iorqn = '0' and i_rdn = '0' then
                            compteur_debounce := compteur_debounce + 1;
                            if compteur_debounce = 5 then
                                compteur_debounce := 0;
                                push_button_state_m <= envoi_code_clavier;
                            end if;
                        end if;
                    when envoi_code_clavier =>
                        if PUSH_BUTTON = '1' then
                            if i_iorqn = '0' and i_rdn = '0' then
                                -- J (=LOAD)
                                if code_index = 0 and i_a_cpu = X"BFFE" then
                                    i_kbd_l_swap <= B"11101";
                                -- "
                                elsif code_index = 1 and ((i_a_cpu = X"DFFE") or (i_a_cpu = X"FEFE")) then
                                    i_kbd_l_swap <= B"01111";
                                -- "
                                elsif code_index = 2 and ((i_a_cpu = X"DFFE") or (i_a_cpu = X"FEFE")) then
                                    i_kbd_l_swap <= B"01111";
                                -- N/L
                                elsif code_index = 3 and i_a_cpu = X"BFFE" then
                                    i_kbd_l_swap <= B"01111";
                                -------------------------------------------------
                                -- LIST
                                elsif code_index = 4 and i_a_cpu = X"BFFE" then
                                    i_kbd_l_swap <= B"11011";
                                -- N/L
                                elsif code_index = 5 and i_a_cpu = X"BFFE" then
                                    i_kbd_l_swap <= B"01111";
                                -------------------------------------------------
                                -- SAVE
                                elsif code_index = 6 and i_a_cpu = X"FDFE" then
                                    i_kbd_l_swap <= B"10111";
                                -- "
                                elsif code_index = 7 and ((i_a_cpu = X"DFFE") or (i_a_cpu = X"FEFE")) then
                                    i_kbd_l_swap <= B"01111";
                                -- A
                                elsif code_index = 8 and i_a_cpu = X"FDFE" then
                                    i_kbd_l_swap <= B"01111";
                                -- "
                                elsif code_index = 9 and ((i_a_cpu = X"DFFE") or (i_a_cpu = X"FEFE")) then
                                    i_kbd_l_swap <= B"01111";
                                -- N/L
                                elsif code_index = 10 and i_a_cpu = X"BFFE" then
                                    i_kbd_l_swap <= B"01111";                                                                                                
                                -------------------------------------------------
                                -- SAVE
                                elsif code_index = 11 and i_a_cpu = X"FDFE" then
                                    i_kbd_l_swap <= B"10111";
                                -- "
                                elsif code_index = 12 and ((i_a_cpu = X"DFFE") or (i_a_cpu = X"FEFE")) then
                                    i_kbd_l_swap <= B"01111";
                                -- A
                                elsif code_index = 13 and i_a_cpu = X"FDFE" then
                                    i_kbd_l_swap <= B"01111";
                                -- "
                                elsif code_index = 14 and ((i_a_cpu = X"DFFE") or (i_a_cpu = X"FEFE")) then
                                    i_kbd_l_swap <= B"01111";
                                -- N/L
                                elsif code_index = 15 and i_a_cpu = X"BFFE" then
                                    i_kbd_l_swap <= B"01111";                                                                                                
                                -------------------------------------------------
                                -- SAVE
                                elsif code_index = 16 and i_a_cpu = X"FDFE" then
                                    i_kbd_l_swap <= B"10111";
                                -- "
                                elsif code_index = 17 and ((i_a_cpu = X"DFFE") or (i_a_cpu = X"FEFE")) then
                                    i_kbd_l_swap <= B"01111";
                                -- A
                                elsif code_index = 18 and i_a_cpu = X"FDFE" then
                                    i_kbd_l_swap <= B"01111";
                                -- "
                                elsif code_index = 19 and ((i_a_cpu = X"DFFE") or (i_a_cpu = X"FEFE")) then
                                    i_kbd_l_swap <= B"01111";
                                -- N/L
                                elsif code_index = 20 and i_a_cpu = X"BFFE" then
                                    i_kbd_l_swap <= B"01111";                                                                                                
                                -------------------------------------------------
                                -- SAVE
                                elsif code_index = 21 and i_a_cpu = X"FDFE" then
                                    i_kbd_l_swap <= B"10111";
                                -- "
                                elsif code_index = 22 and ((i_a_cpu = X"DFFE") or (i_a_cpu = X"FEFE")) then
                                    i_kbd_l_swap <= B"01111";
                                -- A
                                elsif code_index = 23 and i_a_cpu = X"FDFE" then
                                    i_kbd_l_swap <= B"01111";
                                -- "
                                elsif code_index = 24 and ((i_a_cpu = X"DFFE") or (i_a_cpu = X"FEFE")) then
                                    i_kbd_l_swap <= B"01111";
                                -- N/L
                                elsif code_index = 25 and i_a_cpu = X"BFFE" then
                                    i_kbd_l_swap <= B"01111";                                                                                                
                                -------------------------------------------------
                                -- SAVE
                                elsif code_index = 26 and i_a_cpu = X"FDFE" then
                                    i_kbd_l_swap <= B"10111";
                                -- "
                                elsif code_index = 27 and ((i_a_cpu = X"DFFE") or (i_a_cpu = X"FEFE")) then
                                    i_kbd_l_swap <= B"01111";
                                -- A
                                elsif code_index = 28 and i_a_cpu = X"FDFE" then
                                    i_kbd_l_swap <= B"01111";
                                -- "
                                elsif code_index = 29 and ((i_a_cpu = X"DFFE") or (i_a_cpu = X"FEFE")) then
                                    i_kbd_l_swap <= B"01111";
                                -- N/L
                                elsif code_index = 30 and i_a_cpu = X"BFFE" then
                                    i_kbd_l_swap <= B"01111";                                                                                                
                                end if;
                                
                            end if;
                        else
                            code_index := code_index + 1;
                            push_button_state_m <= debounce_push_button;
                        end if;
                    when others =>
                        push_button_state_m <= debounce_push_button;
                end case;
           end if;
        end process;
    
    ---------------------------------------------------------------------
    -- Gestion du reset (à resynbchroniser avec une horloge pour éviter les
    -- métastabilités ?
    ---------------------------------------------------------------------
    i_resetn <= not RESET and i_pll_locked and i_vga_control_init_done;
         
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
              
    ula0 : entity work.ULA
    port map ( 
       CLK_6_5_M => i_clk_6_5mn_buf,
       A_cpu => i_a_cpu, -- CPU address bus
       A_vid_pattern => i_a_vid_pattern, -- RAM/ROM address bus
       D_cpu_IN => i_d_cpu_in, -- CPU data bus IN. Output from ULA side
       D_cpu_OUT => i_d_cpu_out, -- CPU data bus OUT. Input from ULA side
       D_ram_in => i_d_ram_in, -- RAM input data bus. Output from ULA side
       D_ram_out => i_d_ram_out, -- RAM output data bus. Input for ULA side
       D_rom_out => i_d_rom_out, -- ROM ouput data bus. Input for ULA side 
       vga_addr => i_vga_addr,
       vga_data => i_vga_data,    
       vga_wr_cyc => i_vga_wr_cyc, 
       KBDn => i_kbd_l_swap, -- <<==
       TAPE_IN => i_tape_in,
       USA_UK => '0',
       TAPE_OUT => MIC,
       Iorq_Heart_Beat => Iorq_Heart_Beat,
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
       clk => i_clk_6_5mn_buf,
       we => i_wrram,     -- Write actif sur niveau haut...
       spo => i_d_ram_out
    );
    
    vga_control0 : vga_control_top
    port map ( 
        RESET => RESET,
        CLK_52M => i_clk_52m,
        VGA_CLK => i_vga_clock,
        VIDEO_ADDR => i_vga_addr,
        VIDEO_DATA => i_vga_data,
        WR_CYC => i_vga_wr_cyc,
        VGA_CONTROL_INIT_DONE => i_vga_control_init_done,
        HSYNC => HSYNC_VGA,
        VSYNC => VSYNC_VGA,
        BLANK => BLANK_VGA,
        R => R_VGA,
        G => G_VGA,
        B => B_VGA
    );
    
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
   
    -- KBD_C(7) <= i_a_cpu(15);
    -- KBD_C(6) <= i_a_cpu(14);
    -- KBD_C(5) <= i_a_cpu(13);
    -- KBD_C(4) <= i_a_cpu(12);
    -- KBD_C(3) <= i_a_cpu(11);
    -- KBD_C(2) <= i_a_cpu(10);    
    -- KBD_C(5) <= i_a_cpu(12);
    -- KBD_C(4) <= i_a_cpu(13);
    -- KBD_C(3) <= i_a_cpu(10);
    -- KBD_C(2) <= i_a_cpu(11);
    -- KBD_C(1) <= i_a_cpu(9);
    -- KBD_C(0) <= i_a_cpu(8);
    
    i_clk_6_5mn <= not i_clk_6_5m;
    
    --------------------------------------
    -- Output 6_5 M buffering
    -----------------------------------
    clk_buf : BUFG
    port map (
       O => i_clk_6_5mn_buf,
       I => i_clk_6_5mn
     );

    i_tape_in <= not EAR;
    
    -- On ne garde que 3 bits sur les 8
    R_VGA_0 <= R_VGA(5) and not BLANK_VGA;
    R_VGA_1 <= R_VGA(6) and not BLANK_VGA;
    R_VGA_2 <= R_VGA(7) and not BLANK_VGA;
    -- On ne garde que 3 bits sur les 8
    G_VGA_0 <= G_VGA(5) and not BLANK_VGA;
    G_VGA_1 <= G_VGA(6) and not BLANK_VGA;
    G_VGA_2 <= G_VGA(7) and not BLANK_VGA;
    -- On ne garde que 3 bits sur les 8
    B_VGA_0 <= B_VGA(5) and not BLANK_VGA;
    B_VGA_1 <= B_VGA(6) and not BLANK_VGA;
    B_VGA_2 <= B_VGA(7) and not BLANK_VGA;
    
    -- i_kbd_l_swap(4) <= KBD_L(4);
    -- i_kbd_l_swap(3) <= KBD_L(3);
    -- i_kbd_l_swap(2) <= KBD_L(2);
    -- i_kbd_l_swap(1) <= KBD_L(1);
    -- i_kbd_l_swap(0) <= KBD_L(0);
    
    -- Debug
    Dbg(0) <= i_iorqn or i_rdn;
    Dbg(5 downto 1) <= i_kbd_l_swap(4 downto 0);
    Dbg(6) <= i_a_cpu(11);
    Dbg(7) <= i_a_cpu(12);
    
end Behavioral;
