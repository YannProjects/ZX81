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
constant HSYNC_PULSE_ON_DURATION : integer := 15; -- @ 3,25 MHz
--- Back port to front port pulse duration (entre le d<E9>but de la zone de back porch et la fin de la zon de front porch
--- qui encadre les top lignes)
constant FB_PORCH_OFF_DURATION : integer := 192; -- @ 3,25 MHz
constant MIN_VSYNC_PULSE_DURATION : integer := 50;

constant NUMBER_OF_PIXELS_PER_LINE : integer := 640/2; -- 640 pixels par ligne par groupe de 2 bits
constant PIXEL_LINE_START : integer := 64/2;
constant PIXEL_LINE_STOP : integer := PIXEL_LINE_START + NUMBER_OF_PIXELS_PER_LINE;

constant FRAME_LINE_START: integer := 46*NUMBER_OF_PIXELS_PER_LINE; -- Offset de  lignes de  pixels vers le haut
constant FRAME_LINE_STOP: integer := FRAME_LINE_START; -- Offset de  lignes de  pixels vers le haut

-- Pour le heart beat
constant VSYNC_COUNTER_PERIOD : integer := 12;


end;


package body ZX81_Pack is
end;
