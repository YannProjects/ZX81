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

-- Pour le heart beat
constant IORQ_PERIOD : unsigned(15 downto 0) := X"1770";

constant MIN_VSYNC_PULSE_DURATION : unsigned := X"30"; 

constant MIN_VGA_PIXEL_OFFSET : unsigned(11 downto 0) := X"04E";
-- constant MAX_VGA_PIXEL_OFFSET : unsigned(11 downto 0) := MIN_VGA_PIXEL_OFFSET + X"FF";
constant MAX_VGA_PIXEL_OFFSET : unsigned(11 downto 0) := X"0C0"; -- 192 pixels @ 3,5 MHz

end;


package body ZX81_Pack is
end;
