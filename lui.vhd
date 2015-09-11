library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;

entity upper_immediate is
  generic (
    REGISTER_SIZE    : positive;
    INSTRUCTION_SIZE : positive);
  port (
    clk        : in std_logic;
    valid      : in std_logic;
    instr      : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    pc_current : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_out   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_en    : out std_logic);
end entity upper_immediate;


architecture rtl of upper_immediate is
  signal imm   : unsigned(REGISTER_SIZE-1 downto 0);
  alias opcode : std_logic_vector(6 downto 0) is instr(6 downto 0);

  constant LUI   : std_logic_vector(6 downto 0) := "0110111";
  constant AUIPC : std_logic_vector(6 downto 0) := "0010111";

begin  -- architecture rtl
  imm(31 downto 12) <= unsigned(instr(31 downto 12));
  imm(11 downto 0)  <= (others => '0');
  process(clk)
  begin
    if clk'event and clk = '1' then     -- rising clock edge
      case opcode is
        when LUI =>
          data_en  <= valid;
          data_out <= std_logic_vector(imm);
        when AUIPC =>
          data_en  <= valid;
          data_out <= std_logic_vector(unsigned(pc_current) + imm);
        when others =>
          data_en  <= '0';
          data_out <= (others => 'X');
      end case;
    end if;  -- clk
  end process;

end architecture rtl;
