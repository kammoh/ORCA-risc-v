library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;


entity register_file is
  generic(
    REGISTER_SIZE      : positive;
    REGISTER_NAME_SIZE : positive
    );
  port(
    clk              : in std_logic;
    stall            : in std_logic;
    valid_input      : in std_logic;
    rs1_sel          : in std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
    rs2_sel          : in std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
    writeback_sel    : in std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
    writeback_data   : in std_logic_vector(REGISTER_SIZE -1 downto 0);
    writeback_enable : in std_logic;

    rs1_data : out std_logic_vector(REGISTER_SIZE -1 downto 0);
    rs2_data : out std_logic_vector(REGISTER_SIZE -1 downto 0)

    );
end;

architecture rtl of register_file is
  type register_list is array(31 downto 0) of std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal registers : register_list := (others => (others => '0'));

  constant ZERO : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) := (others => '0');

  signal we           : std_logic;
  signal out1         : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal out2         : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal fwd1         : std_logic;
  signal fwd2         : std_logic;
  signal data_latched : std_logic_vector(REGISTER_SIZE-1 downto 0);
begin

  we <= '1' when writeback_enable = '1' and writeback_sel /= ZERO and stall = '0' else '0';

  register_proc : process (clk) is
  begin
    if rising_edge(clk) then
      if we = '1' then
        registers(to_integer(unsigned(writeback_sel))) <= writeback_data;
      end if;
      out1 <= registers(to_integer(unsigned(rs1_sel)));
      out2 <= registers(to_integer(unsigned(rs2_sel)));
      if we = '1' and std_match(writeback_sel, rs1_sel) then
        fwd1 <= '1';
      else
        fwd1 <= '0';
      end if;
      if we = '1' and std_match(writeback_sel , rs2_sel) then
        fwd2 <= '1';
      else
        fwd2 <= '0';
      end if;
    end if;  --rising edge
  end process;
  process(clk) is
  begin
    if rising_edge(clk) then
      data_latched <= writeback_data;
    end if;
  end process;

  rs1_data <= data_latched when fwd1 = '1' else out1;
  rs2_data <= data_latched when fwd2 = '1' else out2;
end architecture;
