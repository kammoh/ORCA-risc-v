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
  component riscV is
    generic (
      REGISTER_SIZE        : integer;
      INSTRUCTION_MEM_SIZE : integer;
      DATA_MEMORY_SIZE     : integer);
    port(clk             : in  std_logic;
         reset           : in  std_logic;
         program_counter : out std_logic_vector(REGISTER_SIZE-1 downto 0));
  end component riscV;
  component sevseg_conv is

    port (
      input  : in  std_logic_vector(3 downto 0);
      output : out std_logic_vector(6 downto 0));

  end component sevseg_conv;
  signal count     : unsigned(31 downto 0);
  signal hex_input : std_logic_vector(31 downto 0);
  signal clk       : std_logic;
  signal reset     : std_logic;

begin
  clk   <= clock_50;
  reset <= not key(1);

  rv : component riscv
    generic map (
      REGISTER_SIZE        => 32,
      INSTRUCTION_MEM_SIZE => 1024,
      DATA_MEMORY_SIZE     => 2048)
    port map (
      clk             => clk,
      reset           => reset,
      program_counter => hex_input);

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

  LEDR <= SW;
  LEDG(6 downto 0) <= (others => '1');
  LEDG(7) <= reset;
end;
