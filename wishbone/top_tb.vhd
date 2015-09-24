library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_tb is
end entity;

architecture rtl of top_tb is

  component top is
    port(clk   : in std_logic;
         reset : in std_logic);
  end component;

  signal reset : std_logic;
  signal clk   : std_logic := '1';

begin

  process
  begin
    clk <= not clk;
    wait for (83.33 ns)/2;
  end process;

  process
  begin
    reset <= '1';
    wait for (83.33 ns)*5;
    reset <= '0';
    wait for 10000 ms;
  end process;

  tp : component top
    port map( clk => clk,
          reset => reset);
end architecture;
