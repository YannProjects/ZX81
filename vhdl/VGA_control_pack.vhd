----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.07.2021 22:28:45
-- Design Name: 
-- Module Name: VGA_control_pack - Behavioral
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
use ieee.std_logic_arith.all;
-- use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

Package VGA_control_pack is

constant CTRL_REG_ADDR : std_logic_vector(31 downto 0) := X"00000000";
constant STAT_REG_ADDR : std_logic_vector(31 downto 0) := X"00000004";
constant HTIM_REG_ADDR : std_logic_vector(31 downto 0) := X"00000008";
constant VTIM_REG_ADDR : std_logic_vector(31 downto 0) := X"0000000C";
constant HVLEN_REG_ADDR : std_logic_vector(31 downto 0) := X"00000010";
constant VBARa_REG_ADDR : std_logic_vector(31 downto 0) := X"00000014";
constant VBARb_REG_ADDR : std_logic_vector(31 downto 0) := X"00000018";
constant CLUT_REG_ADDR_1 : std_logic_vector(31 downto 0) := X"00000800";
constant CLUT_REG_ADDR_2 : std_logic_vector(31 downto 0) := X"00000804";

component vga_control_top is
    Port ( 
        RESET : in STD_LOGIC;
        CLK_52M : in std_logic;
        VGA_CLK : in std_logic;
        VIDEO_ADDR : in std_logic_vector(13 downto 0);
        VIDEO_DATA : in std_logic_vector(7 downto 0);
        WR_CYC : in std_logic;
        VGA_CONTROL_INIT_DONE : out std_logic;
        HSYNC : out std_logic;
        VSYNC : out std_logic;
        CSYNC : out std_logic;
        BLANK : out std_logic;
        R,G,B : out std_logic_vector(7 downto 0)        -- RGB color signals
    );
end component;


end VGA_control_pack;

package body VGA_control_pack is
end;









