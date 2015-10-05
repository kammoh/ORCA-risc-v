library ieee;
use IEEE.std_logic_1164.all;

entity top_tb is
end entity;


architecture rtl of top_tb is
  component top is
    port(
      clk   : in std_logic;
      reset : in std_logic;

      cts : in  std_logic;
      rts : out std_logic;
      txd : out std_logic;
      rxd : in  std_logic;


      R_LED  : out std_logic;
      G_LED  : out std_logic;
      B_LED  : out std_logic;
      HP_LED : out std_logic

      );
  end component;

  signal reset          : std_logic := '1';
  signal clk            : std_logic := '1';
  constant CLOCK_PERIOD : time      := 83.33 ns;
begin
  dut: component top
    port map(
      clk => clk,
      reset => reset,
      cts => '0',
      rxd => '0');

  process
  begin
    clk <= not clk;
    wait for CLOCK_PERIOD/2;
  end process;

  process
  begin
    wait for CLOCK_PERIOD*5;
    reset <= '0';
    wait;
  end process;


end architecture;
