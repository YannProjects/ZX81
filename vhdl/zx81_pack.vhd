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
constant RAM_ADDRWIDTH : integer := 11;
-- 16K
-- constant RAM_ADDRWIDTH : integer := 14;

--- Constantes pour la generation du HSYNC e back/front porch:
--- Pulse front / back porch:
--- ------                        ---------
---       |                       |
---       -------------------------
--- HSYNCn:
--- -------------            -------------
---              |           |
---              -------------
---
--- Nombre d'impulsion correspondant <E0> la dur<E9>e du pulse de HSYNC
constant HSYNC_PULSE_ON_DURATION : natural := 30; -- @ 6,5 MHz
--- Back port to front port pulse duration (entre le d<E9>but de la zone de back porch et la fin de la zon de front porch
--- qui encadre les top lignes)
constant FB_PORCH_OFF_DURATION : natural := 384; -- @ 6,5 MHz

-- Pour le heart beat
constant IORQ_PERIOD : unsigned(15 downto 0) := X"1770";

-- Nombre de pixel non affichés entre le trop ligne et lé début de l'affichage
constant PIXEL_OFFSET_FROM_LINE_START : unsigned(13 downto 0) := B"00" & X"06D"; -- 109

end;


package body ZX81_Pack is
end;
