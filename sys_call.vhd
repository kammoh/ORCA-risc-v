library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity system_calls is

  generic (
    REGISTER_SIZE    : natural;
    INSTRUCTION_SIZE : natural);

  port (
    clk         : in std_logic;
    reset       : in std_logic;
    valid       : in std_logic;
    instruction : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    pc_current  : in std_logic_vector(REGISTER_SIZE -1 downto 0);
    pc_next     : in std_logic_vector(REGISTER_SIZE-1 downto 0);

    finished_instr : in std_logic;

    wb_data   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    wb_en     : out std_logic;
    interrupt : out std_logic);

end entity system_calls;

architecture rtl of system_calls is
  alias csr    : std_logic_vector(11 downto 0) is instruction(31 downto 20);
  alias source : std_logic_vector(4 downto 0) is instruction(19 downto 15);
  alias zimm   : std_logic_vector(4 downto 0) is instruction(19 downto 15);
  alias func3  : std_logic_vector(2 downto 0) is instruction(14 downto 12);
  alias dest   : std_logic_vector(4 downto 0) is instruction(11 downto 7);
  alias opcode : std_logic_vector(6 downto 0) is instruction(6 downto 0);

  signal bad_instruction : std_logic;

  signal cycles        : unsigned(63 downto 0);
  signal instr_retired : unsigned(63 downto 0);

  --CSR constants
  constant CSR_CYCLE   : std_logic_vector(11 downto 0) := x"C00";
  constant CSR_TIME    : std_logic_vector(11 downto 0) := x"C01";
  constant CSR_INSTRET : std_logic_vector(11 downto 0) := x"C02";

  constant CSR_CYCLEH   : std_logic_vector(11 downto 0) := x"C80";
  constant CSR_TIMEH    : std_logic_vector(11 downto 0) := x"C81";
  constant CSR_INSTRETH : std_logic_vector(11 downto 0) := x"C82";

begin  -- architecture rtl

  counter_increment : process (clk) is
  begin  -- process
    if rising_edge(clk) then
      if reset = '1' then
        cycles        <= (others => '0');
        instr_retired <= (others => '0');
      else
        cycles <= cycles +1;
        if finished_instr = '1' then
          instr_retired <= instr_retired +1;
        end if;
      end if;

    end if;
  end process;

  output_proc : process(clk) is
  begin
    if rising_edge(clk) then
      wb_en <= '1';
      case CSR is
        when CSR_CYCLE =>
          wb_data <= std_logic_vector(cycles(REGISTER_SIZE-1 downto 0));
        when CSR_TIME =>
          wb_data <= std_logic_vector(cycles(REGISTER_SIZE-1 downto 0));
        when CSR_INSTRET =>
          wb_data <= std_logic_vector(instr_retired(REGISTER_SIZE-1 downto 0));
        when CSR_CYCLEH =>
          wb_data <= std_logic_vector(cycles(63 downto 64-REGISTER_SIZE));
        when CSR_TIMEH =>
          wb_data <= std_logic_vector(cycles(63 downto 64-REGISTER_SIZE));
        when CSR_INSTRETH =>
          wb_data <= std_logic_vector(instr_retired(63 downto 64-REGISTER_SIZE));
        when others =>
          wb_data   <= (others => 'X');
          wb_en <= '0';
      end case;
    end if;
  end process;


end architecture rtl;
