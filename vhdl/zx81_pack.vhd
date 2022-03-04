----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 25.02.2021 18:09:25
-- Design Name: 
-- Module Name: zx81_pack - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
--  Package file for ZX81 reborn
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

Package ZX81_Pack is

-- 2K
-- constant RAM_ADDRWIDTH : integer := 11;
-- 16K
constant RAM_ADDRWIDTH : integer := 14;

--- Constantes pour la generation du HSYNC et back/front porch:
constant HSYNC_PULSE_ON_DURATION : unsigned(11 downto 0) := X"00F"; -- @ 3,25 MHz
--- Back port to front port pulse duration (entre le d<E9>but de la zone de back porch et la fin de la zon de front porch
--- qui encadre les top lignes)
constant FB_PORCH_OFF_DURATION : unsigned(11 downto 0) := X"0C0"; -- @ 3,25 MHz

constant NUMBER_OF_PIXELS_PER_LINE : unsigned(19 downto 0) := X"00280"; -- 320 adresses contenant 2 bits
constant NUMBER_OF_PIXELS_PER_VGA_LINE : unsigned(19 downto 0) := X"00500"; -- 640
-- constant PIXEL_LINE_START : unsigned(19 downto 0) := X"00020"; -- 16 pixels
-- constant PIXEL_LINE_STOP : unsigned(19 downto 0) := PIXEL_LINE_START + NUMBER_OF_PIXELS_PER_LINE;  -- 16 + 320 pixels
constant PIXEL_LINE_START : unsigned(19 downto 0) := X"00040"; -- 16 pixels
constant PIXEL_LINE_STOP : unsigned(19 downto 0) := X"00120";  -- 16 + 320 pixels

-- Pour le heart beat
constant VSYNC_COUNTER_PERIOD : unsigned(15 downto 0) := X"000C";

constant MIN_VSYNC_PULSE_DURATION : unsigned := X"30";

constant LINE_OFFSET_FROM_FRAME_START: std_logic_vector(19 downto 0) := X"04380"; -- Offset de 45 lignes de 384 pixels vers le haut (384*45)
constant FRAME_LINE_START: unsigned(19 downto 0) := X"03200"; -- Offset de 40 lignes de 320 pixels vers le haut (320*40)
constant FRAME_LINE_STOP: unsigned(19 downto 0) := FRAME_LINE_START + X"19000"; -- Offset de 40 lignes de 320 pixels vers le haut (320*40)

end;


package body ZX81_Pack is
end;
