library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
entity riscv_test is

  port(
    KEY      : in std_logic_vector(3 downto 0);
    SW       : in std_logic_vector(17 downto 0);
    clock_50 : in std_logic;

    LEDR : out std_logic_vector(17 downto 0);
    LEDG : out std_logic_vector(7 downto 0);
    HEX7 : out std_logic_vector(6 downto 0);
    HEX6 : out std_logic_vector(6 downto 0);
    HEX5 : out std_logic_vector(6 downto 0);
    HEX4 : out std_logic_vector(6 downto 0);
    HEX3 : out std_logic_vector(6 downto 0);
    HEX2 : out std_logic_vector(6 downto 0);
    HEX1 : out std_logic_vector(6 downto 0);
    HEX0 : out std_logic_vector(6 downto 0));


end entity riscv_test;

architecture rtl of riscv_test is
  component vblox1 is
    	port (
		clk_clk                : in  std_logic                     := '0';             --             clk.clk
		program_counter_export : out std_logic_vector(31 downto 0);                    -- program_counter.export
		reset_reset_n          : in  std_logic                     := '0';             --           reset.reset_n
		from_host_export       : in  std_logic_vector(31 downto 0) := (others => '0')  --       from_host.export
	);
  end component vblox1;

  component sevseg_conv is

    port (
      input  : in  std_logic_vector(3 downto 0);
      output : out std_logic_vector(6 downto 0));

  end component sevseg_conv;

  signal hex_input : std_logic_vector(31 downto 0);
  signal pc        : std_logic_vector(31 downto 0);
  signal th        : std_logic_vector(31 downto 0);
  signal fh        : std_logic_vector(31 downto 0);
  signal clk       : std_logic;
  signal reset     : std_logic;

begin
  clk   <= clock_50;
  reset <= key(1);

  fh <= std_logic_vector(resize(signed(sw), fh'length));

  LEDR <= fh(17 downto 0);
  rv : component vblox1
    port map (
      clk_clk                => clk,
      reset_reset_n          => reset,
      from_host_export       => fh,
      program_counter_export => pc);

--  hex_input(15 downto 0)  <= pc(15 downto 0);
--  hex_input(31 downto 16) <= th(15 downto 0);
	hex_input <=pc;
  ss0 : component sevseg_conv
    port map (
      input  => hex_input(3 downto 0),
      output => HEX0);
  ss1 : component sevseg_conv
    port map (
      input  => hex_input(7 downto 4),
      output => HEX1);
  ss2 : component sevseg_conv
    port map (
      input  => hex_input(11 downto 8),
      output => HEX2);
  ss3 : component sevseg_conv
    port map (
      input  => hex_input(15 downto 12),
      output => HEX3);
  ss4 : component sevseg_conv
    port map (
      input  => hex_input(19 downto 16),
      output => HEX4);
  ss5 : component sevseg_conv
    port map (
      input  => hex_input(23 downto 20),
      output => HEX5);
  ss6 : component sevseg_conv
    port map (
      input  => hex_input(27 downto 24),
      output => HEX6);
  ss7 : component sevseg_conv
    port map (
      input  => hex_input(31 downto 28),
      output => HEX7);

  LEDR             <= SW;
  LEDG(6 downto 0) <= (others => '1');
  LEDG(7)          <= reset;
end;
