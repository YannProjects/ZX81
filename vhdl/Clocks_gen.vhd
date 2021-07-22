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
           reset : in STD_LOGIC; -- Actif niveau haut
           clk_52m : out STD_LOGIC;
           clk_3_25m : out STD_LOGIC;
           clk_6_5m : out STD_LOGIC;
           vga_clk : out STD_LOGIC;
           pll_locked : out std_logic);
end Clocks_gen;

architecture Based_on_IP of Clocks_gen is
    
component clk_wiz_0 IS
port (
    clk_in1 : IN STD_LOGIC;
    clk_52m : OUT STD_LOGIC;
    clk_vga : OUT STD_LOGIC;
    locked : OUT STD_LOGIC
);
end component; 
     
signal i_clk_3_25m, i_clk_6_5m, i_clk_13m, i_clk_26m, i_clk_52m : std_logic;

begin

    -- Composant utilisé pour générer les horloges du ZX81 et du controlleur VGA:
    -- VGA_CLK: 25,1 MHz pour le controlleur VGA
    -- 6,5 MHz: ULA
    -- 3,25 MHz: Z80    
    clk_gen : clk_wiz_0
    port map (
        clk_in1 => main_clk,
        clk_52m => i_clk_52m,
        clk_vga => vga_clk,
        locked => pll_locked
    );

    clk_divider_1: process (i_clk_52m, reset)
    begin
        if reset = '1' then
            i_clk_26m <= '0';
        elsif rising_edge(i_clk_52m) then
            i_clk_26m <= not i_clk_26m;
        end if;
    end process;
    
    clk_divider_2: process (i_clk_26m, reset)
    begin
        if reset = '1' then
            i_clk_13m <= '0';
        elsif rising_edge(i_clk_26m) then
            i_clk_13m <= not i_clk_13m;
        end if;
    end process;
    
    clk_divider_3: process (i_clk_13m, reset)
    begin
        if reset = '1' then
            i_clk_6_5m <= '0';
        elsif rising_edge(i_clk_13m) then
            i_clk_6_5m <= not i_clk_6_5m;
        end if;
    end process;
    
    clk_divider_4: process (i_clk_6_5m, reset)
    begin
        if reset = '1' then
            i_clk_3_25m <= '0';
        elsif rising_edge(i_clk_6_5m) then
            i_clk_3_25m <= not i_clk_3_25m;
        end if;
    end process;            

    clk_3_25m <= i_clk_3_25m;
    clk_6_5m <= i_clk_6_5m;
    clk_52m <= i_clk_52m;

end Based_on_IP;

