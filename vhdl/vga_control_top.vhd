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
        RESET : in STD_LOGIC;
        CLK_52M : in std_logic;
        VGA_CLK : in std_logic;
        VIDEO_ADDR : in std_logic_vector(19 downto 0);
        VIDEO_DATA : in std_logic_vector(1 downto 0);
        WR_CYC : in std_logic;
        VGA_CONTROL_INIT_DONE : out std_logic;
        HSYNC : out std_logic;
        VSYNC : out std_logic;
        CSYNC : out std_logic;
        BLANK : out std_logic;
        R,G,B : out std_logic_vector(7 downto 0)        -- RGB color signals
    );
end vga_control_top;

-- Composant permettant d'accéder au controlleur VGA.
-- On écrit les données vidéo du ZX81 dans une RAM de 768 octets (32*24).
-- Chaque bit est transformé en une série d'octets lus par le controlleur VGA qui est configuré ôur un affichage en noir et blanc:
-- '1' => 0xFF
-- '0' => 0x00
-- Les pixels et les lignes sont aussi dupliquées pour s'adapter à la résolution VGA de 640 x 480
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

    component vid_mem is
    port(
        clk_i : in std_logic;
        adr_i_vga_c : std_logic_vector (31 downto 0);
        cyc_i_vga_c : in std_logic;
        stb_i_vga_c : in std_logic;
        ack_o_vga_c : out std_logic;
        dat_o_vga_c : out std_logic_vector(31 downto 0);
        adr_vid_i : in std_logic_vector (19 downto 0);
        dat_vid_i : in std_logic_vector(1 downto 0);
        wr_i : in std_logic	
    );
    end component vid_mem;

	type states is (wait_init, chk_stop, gen_cycle, wait_for_ack, idle);
	type vector_type is 
    record
        adr   : std_logic_vector(31 downto 0); -- wishbone address output
        dat   : std_logic_vector(31 downto 0); -- wishbone data output (write) or input compare value (read)
        stop  : std_logic;                     -- last field, stop wishbone activities
    end record;
    
    type vector_list is array(0 to 8) of vector_type;

	-- signal declarations
	signal rst_vga : std_logic := '1';
	signal state : states;
	signal icnt, init_timer : natural := 0;
	signal i_vga_controller_ok : std_logic;	
	
    -- wishbone host
	signal s_cyc_o, s_we_o : std_logic;
	signal s_adr_o                  : std_logic_vector(31 downto 0);
	signal s_dat_o, s_dat_i         : std_logic_vector(31 downto 0);
	signal s_sel_o                  : std_logic_vector(3 downto 0);
	signal s_ack_i, s_err_i         : std_logic;
	signal s_stb_vga_o : std_logic;
	
    -- vga master
	signal vga_adr_o                       : std_logic_vector(31 downto 0);
	signal vga_dat_i                       : std_logic_vector(31 downto 0);
	signal vga_stb_o, vga_cyc_o, vga_ack_i : std_logic;
	signal vga_sel_o                       : std_logic_vector(3 downto 0);
	signal vga_we_o                        : std_logic;
	
	signal i_video_addr_0, i_video_addr_1 : std_logic_vector(19 downto 0);
    signal i_video_data_0, i_video_data_1 : std_logic_vector(1 downto 0);
    signal i_wr_cyc_0, i_wr_cyc_1 : std_logic;
        
    attribute ASYNC_REG : string;
    attribute ASYNC_REG of i_video_addr_0, i_video_addr_1 : signal is "TRUE";
    attribute ASYNC_REG of i_video_data_0, i_video_data_1 : signal is "TRUE";
    attribute ASYNC_REG of i_wr_cyc_0, i_wr_cyc_1 : signal is "TRUE";
	
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
        -- Thgdel (back porch) : 240 pixels
        -- Thgate : 384 pixels
        -- Front porch = 800 - (96+240+384) = 80 pixels
        -- (HTIM_REG_ADDR,x"5F9F017F", '0'), -- program horizontal timing register (384*480)
        (HTIM_REG_ADDR,x"5F32027F", '0'), -- program horizontal timing register (640*480)
        -- Pour les lignes, il y a en tout 525 lignes
        -- => Sync pulse = 2 lignes
        -- => active time = 479 lignes (il faut une ligne de moins car sinon, on dépasse la mémoire ???)
        -- => back porch = 30
        -- => front porch = 600 - (2+30+479) = 89 lignes
        (VTIM_REG_ADDR,x"011D01DE", '0'), --   program vertical timing register
        (HVLEN_REG_ADDR,x"031F020C", '0'), --   program horizontal/vertical length register (800 x 525).
        
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
        (CLUT_REG_ADDR_2,x"000000E0", '0'),
        (CTRL_REG_ADDR,x"00000901", '0'), --   program control register (VEN=1 (video enabled), PC=1 (pseudo-color), CD=11 (32 bits))                                                
        -- end list
        (x"00000000",x"00000000", '1')  --38 stop testbench
    );

begin
    -- Partie destinée à confgurer le controlleur VGA
    -- Une fois le controlleur initialisé, on met VGA_CONTROL_INIT_DONE = 1 
    -- ce qui permettra de démarrer les autres composants (Z80, ULA,...).
    
	process(clk_52M, RESET)
	begin
        if (RESET = '1') then
            state <= chk_stop;
            icnt <= 0;
            s_cyc_o <= '0';
            s_stb_vga_o <= '0';
            s_adr_o <= X"FFFFFFFF";
            s_dat_o <= (others => 'X');
            s_we_o  <= 'X';
            s_sel_o <= (others => 'X');
            i_vga_controller_ok <= '0';
            init_timer <= 0;
            
        elsif rising_edge(clk_52M) then    
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
                    i_vga_controller_ok <= '1';
               end case;
        end if;
    end process;
	
	-- Resynchronisation des signaux pour éviter les métastabilités
	-- (frontière entre différents clock domains
	process(clk_52M)
    begin
        if rising_edge(clk_52M) then
            i_video_addr_1 <= VIDEO_ADDR;
            i_video_data_1 <= VIDEO_DATA;
            i_wr_cyc_1 <= WR_CYC;
            VGA_CONTROL_INIT_DONE <= i_vga_controller_ok;
        end if;
    end process;

	--
	-- hookup vga + clut core
	--
	-- Contrôleur VGA s'interfaçant avec le U3 (vid_mem)
	u1: vga_enh_top port map (
        wb_clk_i => CLK_52M, wb_rst_i => '0', rst_i => not RESET,
        
        wbs_adr_i => s_adr_o(11 downto 0), wbs_dat_i => s_dat_o, wbs_dat_o => s_dat_i, 
        wbs_sel_i => s_sel_o, wbs_we_i => s_we_o, wbs_stb_i => s_stb_vga_o,
		wbs_cyc_i => s_cyc_o, wbs_ack_o => s_ack_i, wbs_err_o => s_err_i,
		
		wbm_adr_o => vga_adr_o, wbm_dat_i => vga_dat_i, wbm_sel_o => vga_sel_o, wbm_stb_o => vga_stb_o,
		wbm_cyc_o => vga_cyc_o, wbm_ack_i => vga_ack_i, wbm_err_i => '0',
		
		clk_p_i => VGA_CLK, hsync_pad_o => HSYNC, vsync_pad_o => VSYNC, csync_pad_o => CSYNC, blank_pad_o => BLANK,
		r_pad_o => R, g_pad_o => G, b_pad_o => B	
	);
		
    -- Composant utilisé comme interface entre le ZX81 et le contrôleur VGA
    -- Les données vidéo sont écrites par l'ULA (bit par bit via le registre série) 
    -- et lues par le contrôleur VGA (1 octet par pixel, couleur (0x01) ou noir (0x00). 
	u3: vid_mem
    port map (clk_i => CLK_52M, adr_i_vga_c => vga_adr_o, cyc_i_vga_c => vga_cyc_o, 
                stb_i_vga_c => vga_stb_o, ack_o_vga_c => vga_ack_i,
                dat_o_vga_c => vga_dat_i, adr_vid_i => i_video_addr_1, dat_vid_i => i_video_data_1, wr_i => i_wr_cyc_1);

end architecture Behavioral;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.all;

entity vid_mem is
	port(
	    -- Horloge comunne pour le controlleur VGA et le host 
		clk_i : in std_logic;
		-- Adresse de lecture côté VGA controlleur
		adr_i_vga_c : in std_logic_vector (31 downto 0);
		-- CYC_I WB côté VGA controller
		cyc_i_vga_c : in std_logic;
		-- STB_I WB côté VGA controller
		stb_i_vga_c : in std_logic;
		-- ACK_O WB côté VGA controller
		ack_o_vga_c : out std_logic;
		-- Donnée RAM vidéo pour le controlleur VGA
		dat_o_vga_c : out std_logic_vector(31 downto 0);
		-- Adresse en écriture côté host
		adr_vid_i : std_logic_vector (19 downto 0);
		-- Données en entrées pour la RAM vidéo côté host
		dat_vid_i : in std_logic_vector(1 downto 0);
		-- Ecriture en RAM vidéo côté host
		wr_i : in std_logic	
	);
end entity vid_mem;

architecture behavioral of vid_mem is
		
	-- Mémoire dual port de taille 32 x 24 x 2 (les lignes sont dédoublées) x 8 bits
    component blk_mem_gen_vga_2 is
      port (
        clka : in std_logic;
        wea : in std_logic_vector(0 DOWNTO 0);
        addra : in std_logic_vector(17 downto 0);
        dina : in std_logic_vector(1 DOWNTO 0);
        clkb : in std_logic;
        addrb : in std_logic_vector(15 downto 0);
        doutb : out std_logic_vector(7 downto 0)
      );
    end component;
    
    -- Données vidéo ZX81 (8 bits, 1 pixel par bit)
    signal dat_o_ram_vga: std_logic_vector(7 downto 0);
    -- Données controlleur VGA (32 bits, 8 bits par pixel).
    signal adr_i_ram_vga: std_logic_vector(15 downto 0);
	
begin

    -- Les données sont écrites bit par bit et lues par groupe de 4 octets (1 octet = 1 pixel avec comme valeur 0x00 ou 0x01)
    u1: blk_mem_gen_vga_2
        port map (clka => not clk_i, wea(0) => wr_i, addra => adr_vid_i(17 downto 0), dina => dat_vid_i,
            clkb => not clk_i, addrb => adr_i_ram_vga, doutb => dat_o_ram_vga);
    
    -- La résolution choisit pour le controlleur VGA est de 640 * 480.
    -- On n'utilise que 192 pixels de zone utile sur les lignes horizontales
    -- Chaque octets stockés dans la RAM VGA défini 8 bits qui sont transformés en 2 groupe de 4 pixels côté controlleur VGA.
    -- ex.
    -- Contenu RAM VGA: 0xF0
    -- Valeurs lues par le controlleur VGA : 4 octets avec 0x01010101 (i.e.: 4 pixels couleurs) + 
    -- 4 octets avec 0x00000000 (i.e.: 4 pixels noirs)       
    adr_i_ram_vga <= adr_i_vga_c(18 downto 3);
    
    with adr_i_vga_c(2) select
        dat_o_vga_c <= 
            B"0000000" & dat_o_ram_vga(0) &
            B"0000000" & dat_o_ram_vga(1) &
            B"0000000" & dat_o_ram_vga(2) &
            B"0000000" & dat_o_ram_vga(3) when '0',

            B"0000000" & dat_o_ram_vga(4) &
            B"0000000" & dat_o_ram_vga(5) &
            B"0000000" & dat_o_ram_vga(6) &
            B"0000000" & dat_o_ram_vga(7) when '1',                                    
            
            X"00000000" when others;
    
    -- Acquittement immédiat
    ack_o_vga_c <= '1' when (cyc_i_vga_c = '1') and (stb_i_vga_c = '1') else '0';

end architecture Behavioral;
