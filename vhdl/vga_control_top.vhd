----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 15.07.2021 10:42:27
-- Design Name: 
-- Module Name: vga_control_top - Behavioral
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
library work;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_arith.all;
-- use ieee.numeric_std.shift_left;
use work.VGA_control_pack.all;

library UNISIM;
use UNISIM.VComponents.all;
use work.ZX81_Pack.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity vga_control_top is
    Port ( 
        i_RESET : in STD_LOGIC;
        i_CLK_52M : in std_logic;
        i_CLK_6_5M : in std_logic;
        i_VGA_CLK : in std_logic;
        o_VGA_CONTROL_INIT_DONE : out std_logic;
        i_ula_hsync : in std_logic;
        i_ula_vsync : in std_logic;
        i_ula_vid_data : in std_logic;
        -- VGA control signals
        o_HSYNC : out std_logic;
        o_VSYNC : out std_logic;
        o_BLANK : out std_logic;
        o_R, o_G, o_B : out std_logic_vector(7 downto 0)        -- RGB color signals
    );
end vga_control_top;

-- Composant permettant d'accéder au controlleur VGA.
-- On écrit les données vidéo du ZX81 dans une RAM de 49152 bits (32*8*24*8).
-- Les données sont écrites bit par bit et lues par groupe de 2 bits, dupliqués et transformés en 2 octets (0x00, 0x01)
-- pour l'affichage en N&B du controlleur VGA
-- Les pixels et les lignes sont aussi dupliquées pour s'adapter à la résolution VGA de 512 x 384
-- Le lignes sont dupliquées en supprimant le bit 9 de l'adresse master du controller VGA
architecture Behavioral of vga_control_top is

    -- Controller VGA Opencores
    component vga_enh_top is
	port(
		wb_clk_i   : in std_logic;                         -- wishbone clock input
		wb_rst_i   : in std_logic;                         -- synchronous active high reset
		rst_i  : in std_logic;                  -- asynchronous active low reset
		wb_inta_o  : out std_logic;                        -- interrupt request output

		-- slave signals
		wbs_adr_i : in std_logic_vector(11 downto 0);          -- addressbus input (only 32bit databus accesses supported)
		wbs_dat_i : in std_logic_vector(31 downto 0);  -- Slave databus output
		wbs_dat_o : out std_logic_vector(31 downto 0); -- Slave databus input
		wbs_sel_i : in std_logic_vector(3 downto 0);   -- byte select inputs
		wbs_we_i  : in std_logic;                      -- write enabel input
		wbs_stb_i : in std_logic;                      -- vga strobe/select input
		wbs_cyc_i : in std_logic;                      -- valid bus cycle input
		wbs_ack_o : out std_logic;                     -- bus cycle acknowledge output
		wbs_rty_o : out std_logic;                     -- bus cycle retry output
		wbs_err_o : out std_logic;                     -- bus cycle error output
		
		-- master signals
		wbm_adr_o : out std_logic_vector(31 downto 0);              -- addressbus output
		wbm_dat_i : in std_logic_vector(31 downto 0);      -- Master databus input
		wbm_sel_o : out std_logic_vector(3 downto 0);       -- byte select outputs
		wbm_we_o  : out std_logic;                           -- write enable output
		wbm_stb_o : out std_logic;                          -- strobe output
		wbm_cyc_o : out std_logic;                          -- valid bus cycle output
		wbm_cti_o : out std_logic_vector(2 downto 0);       -- cycle type bus
		wbm_bte_o : out std_logic_vector(1 downto 0);       -- burst type extensions
		wbm_ack_i : in std_logic;                           -- bus cycle acknowledge input
		wbm_err_i : in std_logic;                           -- bus cycle error input

		-- VGA signals
		clk_p_i     : in std_logic;                            -- pixel clock
		clk_p_o     : out std_logic;                            -- pixel clock
		hsync_pad_o : out std_logic;                          -- horizontal sync
		vsync_pad_o : out std_logic;                          -- vertical sync
		csync_pad_o : out std_logic;                          -- composite sync
		blank_pad_o : out std_logic;                          -- blanking signal
		r_pad_o,g_pad_o,b_pad_o : out std_logic_vector(7 downto 0)        -- RGB color signals
	);
    end component vga_enh_top;
    
	-- Mémoire dual port de taille 32 x 24 x 2 (les lignes sont dédoublées) x 8 bits
    component blk_mem_gen_vga_2 is
    port (
        clka : in std_logic;
        wea : in std_logic_vector(0 DOWNTO 0);
        addra : in std_logic_vector(15 downto 0);
        dina : in std_logic_vector(0 DOWNTO 0);
        clkb : in std_logic;
        addrb : in std_logic_vector(14 downto 0);
        doutb : out std_logic_vector(1 downto 0)
    );
    end component;    

	type states is (wait_init, chk_stop, gen_cycle, wait_for_ack, idle);
	type vector_type is 
    record
        adr   : std_logic_vector(31 downto 0); -- wishbone address output
        dat   : std_logic_vector(31 downto 0); -- wishbone data output (write) or input compare value (read)
        stop  : std_logic;                     -- last field, stop wishbone activities
    end record;
    
    type vector_list is array(0 to 8) of vector_type;

	-- signal declarations
	signal state : states;
	signal icnt, init_timer : natural := 0;
	signal vga_controller_ok : std_logic;	
	
    -- wishbone host
	signal s_cyc_o, s_we_o : std_logic;
	signal s_adr_o                  : std_logic_vector(31 downto 0);
	signal s_dat_o, s_dat_i         : std_logic_vector(31 downto 0);
	signal s_sel_o                  : std_logic_vector(3 downto 0);
	signal s_ack_i, s_err_i         : std_logic;
	signal s_stb_vga_o              : std_logic;
	
    -- vga master
	signal vga_core_addr                  : std_logic_vector(31 downto 0);
	signal vga_core_data                  : std_logic_vector(31 downto 0);
	signal vga_core_stb, vga_core_cyc     : std_logic;
	signal vga_core_ack                   : std_logic;
    
    signal pixel_line_counter : integer;
    signal vsync_pulse_duration, frame_line_cntr : integer;
    signal vid_shift_register, ula_vid_data : std_logic_vector(15 downto 0);
    signal vid_mem_wr : std_logic;
    signal horizontal_start, vertical_start, vsync_frame_detect : std_logic;
    signal vga_pixel_buffer_adr : unsigned(15 downto 0);
    signal vga_mem_addr : std_logic_vector(14 downto 0);
    signal ula_hsync0, ula_hsync1 : std_logic;
    signal pixel_data : std_logic_vector(1 downto 0);
	
	shared variable vectors : vector_list :=
    (
        -- Mode Resolution Refresh Pulse Back porch Active time Front porch Line Total
        --              rate  MHz       usec    pix     pix     pix     pix     pix
        -- QVGA 320x240 60 Hz
        -- VGA 640x480  60 Hz 25.175    3.81    96      45      646     13      800
        -- VGA 640x480  72 Hz 31.5      1.27    40      125     646     21      832
        -- SVGA 800x600 56 Hz 36        2       72      125     806     21      1024
        -- SVGA 800x600 60 Hz 40        3.2     128     85      806     37      1056        <<<===
        -- SVGA 800x600 72 Hz 50        2.4     120     61      806     53      1040

        -- program vga controller
        (VBARa_REG_ADDR,x"00000000", '0'), --   program video base address 0 register (VBARa)
        (VBARb_REG_ADDR,x"00100000", '0'), --   program video base address 0 register (VBARb). Pas utilisé
        -- Pour le cas du ZX81, le mode choisit et une résolution de 640 x 480 avec un affichage de:
        -- Thsync : 96 pixels
        -- Thgdel (back porch) : 112 pixels
        -- Thgate : 512 pixels
        -- Front porch = 800 - (96+112+512) = 80 pixels
        (HTIM_REG_ADDR,x"5F6F01FF", '0'), -- program horizontal timing register
        -- Pour les lignes, il y a en tout 525 lignes
        -- => Sync pulse = 2 lignes
        -- => active time = 384 lignes (il faut une ligne de moins car sinon, on dépasse la mémoire ???)
        -- => back porch = 30
        -- => front porch = 600 - (2+30+384) = 184 lignes
        (VTIM_REG_ADDR,x"013D017F", '0'), -- program vertical timing register
        (HVLEN_REG_ADDR,x"031F020C", '0'), -- program horizontal/vertical length register (800 x 525 pour une resolution de 640 x 480 60 Hz).
        
        -- On n'utilise que 2 couleurs: la première en index 0 et la dernière en index 255 sur la CLUT 0 (CLUT 1 pas utilisée)
        -- CLUT_REG_ADDR_1: Couleur de fond
        -- CLUT_REG_ADDR_2: Couleur de premier plan
        -- 0x00E0E0E0 : R G B sur un octet. Par rapport au circuit, seuls les 3 bits de poids fort sont utilisés:
        -- Blanc:  0x00E0E0E0
        -- Noir:   0x00000000
        -- Bleu:   0x000000E0
        -- Vert:   0x0000E000
        -- Rouge:  0x00E00000
        -- Violet: 0x00800080
        -- Jaune:  0x00e0e000
        (CLUT_REG_ADDR_1,x"00E0E0E0", '0'),
        (CLUT_REG_ADDR_2,x"00000000", '0'),
        (CTRL_REG_ADDR,x"00000901", '0'), --   program control register (VEN=1 (video enabled), PC=1 (pseudo-color), CD=11 (32 bits))                                                
        -- end list
        (x"00000000",x"00000000", '1')  --38 stop testbench
    );

begin

    -- Partie destinée à configurer le controlleur VGA
    -- Une fois le controlleur initialisé, on met VGA_CONTROL_INIT_DONE = 1 
    -- ce qui permettra de démarrer les autres composants (Z80, ULA,...).
	p_vga_controller_init : process(i_CLK_52M, i_RESET)
	begin
        if (i_RESET = '1') then
            state <= chk_stop;
            icnt <= 0;
            s_cyc_o <= '0';
            s_stb_vga_o <= '0';
            s_adr_o <= X"FFFFFFFF";
            s_dat_o <= (others => 'X');
            s_we_o  <= 'X';
            s_sel_o <= (others => 'X');
            vga_controller_ok <= '0';
            init_timer <= 0;
            
        elsif rising_edge(i_CLK_52M) then    
              case state is
                when wait_init =>
                    init_timer <= init_timer + 1;
                    if init_timer = 500 then
                        state <= chk_stop;
                    end if;
                when chk_stop =>
                    s_cyc_o <= '0';
                    s_stb_vga_o <= 'X';
                    s_adr_o <= (others => 'X');
                    s_dat_o <= (others => 'X');
                    s_we_o  <= 'X';
                    s_sel_o <= (others => 'X');
                    if (vectors(icnt).stop = '0') then
                        state <= gen_cycle;
                    else
                        state <= idle;
                    end if;
               when gen_cycle =>
                    s_cyc_o <= '1';
                    s_stb_vga_o <= '1';
                    s_adr_o <= vectors(icnt).adr;
                    s_dat_o <= vectors(icnt).dat;
                    s_we_o <= '1';
                    s_sel_o <= "1111";
                    state <= wait_for_ack;
               when wait_for_ack =>
                    if s_ack_i = '1' then
                        state <= chk_stop;
                        icnt <= icnt + 1;
                    end if;
               when idle =>
                    s_stb_vga_o <= '0';
                    s_cyc_o <= '0';
                    s_we_o  <= '0';
                    vga_controller_ok <= '1';
               end case;
        end if;
    end process;
    
    o_VGA_CONTROL_INIT_DONE <= vga_controller_ok;

	--
	-- hookup vga + clut core
	--
	-- Contrôleur VGA s'interfaçant avec le U3 (vid_mem)
	u1: vga_enh_top port map (
        wb_clk_i => i_CLK_52M, wb_rst_i => '0', rst_i => not i_RESET,
        
        -- Slave side (VGA controller initialisation)
        wbs_adr_i => s_adr_o(11 downto 0), wbs_dat_i => s_dat_o, wbs_dat_o => s_dat_i, 
        wbs_sel_i => s_sel_o, wbs_we_i => s_we_o, wbs_stb_i => s_stb_vga_o,
		wbs_cyc_i => s_cyc_o, wbs_ack_o => s_ack_i, wbs_err_o => s_err_i,
		
		-- Master side -> read video data by group of 32 bits (16 ULA pixels)
		wbm_adr_o => vga_core_addr, wbm_dat_i => vga_core_data, wbm_stb_o => vga_core_stb,
		wbm_cyc_o => vga_core_cyc, wbm_ack_i => vga_core_ack, wbm_err_i => '0',
		
		-- VGA outputs
		clk_p_i => i_VGA_CLK, hsync_pad_o => o_HSYNC, vsync_pad_o => o_VSYNC, blank_pad_o => o_BLANK,
		r_pad_o => o_R, g_pad_o => o_G, b_pad_o => o_B
	);
	
	-- Acquittement immediat
    vga_core_ack <= '1' when (vga_core_cyc = '1') and (vga_core_stb = '1') else '0';

    -- Les donnees sont ecrites bit par bit et lues par groupe de 2 bits et transformees en
    -- 2 octets (1 octet = 1 pixel avec comme valeur 0x00 ou 0x01)
    u2: blk_mem_gen_vga_2
        port map (clka => i_CLK_52M, wea(0) => vid_mem_wr, addra => std_logic_vector(vga_pixel_buffer_adr), dina => "" & i_ula_vid_data,
           clkb => not i_CLK_52M, addrb => vga_mem_addr, doutb => pixel_data);

    vga_core_data <= B"0000000" & pixel_data(0) &
                     B"0000000" & pixel_data(0) &
                     B"0000000" & pixel_data(1) &
                     B"0000000" & pixel_data(1);

    -- Suppression du bit 9 pour doubler les lignes (384 = 2*192).    
    vga_mem_addr <= vga_core_addr(17 downto 10) & vga_core_addr(8 downto 2);
    vid_mem_wr <= '1' when horizontal_start = '1' and vertical_start = '1' else '0';

    -- Pixel line counter
    p_build_vga_data : process(i_CLK_6_5M, i_RESET, vertical_start)
    begin
        if i_RESET = '1' or vertical_start = '0' then
            vga_pixel_buffer_adr <= (others => '0');
        elsif rising_edge(i_CLK_6_5M) then
            if horizontal_start = '1' and vertical_start = '1' then
                vga_pixel_buffer_adr <= vga_pixel_buffer_adr + "1";
            end if;
        end if;
    end process;

    p_vga_pixel_line_counter: process (i_CLK_6_5M, i_ula_hsync)
    begin
        if i_ula_hsync = '1' then
            -- On resette le nombre de pixel depuis le début de la ligne en cas de HSYNC
            pixel_line_counter <= 0;
        elsif rising_edge(i_CLK_6_5M) then
            pixel_line_counter <= pixel_line_counter + 1;
        end if;
    end process;
    
    horizontal_start <= '1' when pixel_line_counter >= PIXEL_LINE_OFFSET and pixel_line_counter < PIXEL_LINE_OFFSET + HRES else '0';
    
    p_vga_line_counter: process (i_CLK_6_5M, vsync_frame_detect)
    begin
        if vsync_frame_detect = '1' then
            frame_line_cntr <= 0;
        -- Sur chaque front descendant de l'horloge 3,25 MHz
        elsif rising_edge(i_CLK_6_5M) then
            ula_hsync0 <= i_ula_hsync;
            ula_hsync1 <= ula_hsync0;
            -- Line start
            if ula_hsync0 = '0' and ula_hsync1 = '1' then
                frame_line_cntr <= frame_line_cntr + 1;
            end if;
        end if;
    end process;
    
    vertical_start <= '1' when frame_line_cntr >= FRAME_LINE_START and frame_line_cntr < FRAME_LINE_START + VRES else '0';
    
    p_vsync_pulse_duration_counter : process(i_CLK_6_5M, i_ula_vsync)
    begin
        if i_ula_vsync = '0' then
            vsync_pulse_duration <= 0;
            vsync_frame_detect <= '0';
        -- On compte la durée du pulse de VSYNC pour savoir si c'est uyne vraie synchro trame ou pas
        -- (cas du ZX81 en mode pseudo-hires avec invaders ou pacman)
        elsif rising_edge(i_CLK_6_5M) then
            vsync_pulse_duration <= vsync_pulse_duration + 1;
            if vsync_pulse_duration >= MIN_VSYNC_PULSE_DURATION  then
                vsync_frame_detect <= '1';
            end if;
        end if;
    end process;

end architecture Behavioral;