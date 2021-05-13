----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 29.07.2020 11:50:50
-- Design Name: 
-- Module Name: Clocks_gen - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Clocks_gen is
    Port ( main_clk : in STD_LOGIC;
           resetn : in STD_LOGIC;
           clk_3_25m : out STD_LOGIC);
end Clocks_gen;

architecture Based_on_IP of Clocks_gen is

signal int_clk_3_25m : std_logic;

begin

    clk_divider: process (main_clk, resetn)
    begin
        if resetn = '0' then
            int_clk_3_25m <= '0';
        elsif rising_edge(main_clk) then
            int_clk_3_25m <= not int_clk_3_25m;
        end if;
    end process;

clk_3_25m <= int_clk_3_25m;

end Based_on_IP;

--
-- Choix de la configuration de la generation des horloges
--
-- configuration first_try of Clocks_gen is
--     for Behavioral
--     end for;
-- end first_try; 

