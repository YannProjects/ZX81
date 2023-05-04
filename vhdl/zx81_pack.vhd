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

--- Constantes pour la generation du HSYNC et back/front porch:
constant HSYNC_PULSE_ON_DURATION : integer := 15; -- @ 3,25 MHz
--- Back port to front port pulse duration (entre le debut de la zone de back porch et la fin de la zone de front porch
--- qui encadre les top lignes)
constant FB_PORCH_OFF_DURATION : integer := 192; -- @ 6,5 MHz pour la generation du HSYNC de l'ULA
constant PIXEL_LINE_OFFSET : integer := 32; -- Offset en pixel sur la ligne pour le demarrage de l'affichage VGA
constant MIN_VSYNC_PULSE_DURATION : integer := 60;

constant FRAME_LINE_START: integer := 46; -- Offset de  lignes de  pixels vers le haut
constant FRAME_LINE_STOP: integer := FRAME_LINE_START; -- Offset de  lignes de  pixels vers le haut

-- ZX81 screen resolution
constant HRES: integer := 32*8;
constant VRES: integer := 24*8;

-- Pour le heart beat
constant VSYNC_COUNTER_PERIOD : integer := 12;


end;


package body ZX81_Pack is
end;
