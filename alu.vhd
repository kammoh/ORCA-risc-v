library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;
library work;
use work.utils.all;
--use IEEE.std_logic_arith.all;

entity arithmetic_unit is

  generic (
    INSTRUCTION_SIZE    : integer;
    REGISTER_SIZE       : integer;
    SIGN_EXTENSION_SIZE : integer);

  port (
    clk            : in  std_logic;
    stall          : in  std_logic;
    rs1_data       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    rs2_data       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    instruction    : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    sign_extension : in  std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
    data_out       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_enable    : out std_logic
    );

end entity arithmetic_unit;

architecture rtl of arithmetic_unit is
  constant ADD_OP  : std_logic_vector(2 downto 0) := "000";
  constant SLL_OP  : std_logic_vector(2 downto 0) := "001";
  constant SLT_OP  : std_logic_vector(2 downto 0) := "010";
  constant SLTU_OP : std_logic_vector(2 downto 0) := "011";
  constant XOR_OP  : std_logic_vector(2 downto 0) := "100";
  constant SR_OP   : std_logic_vector(2 downto 0) := "101";
  constant OR_OP   : std_logic_vector(2 downto 0) := "110";
  constant AND_OP  : std_logic_vector(2 downto 0) := "111";

  constant OP_IMM_IMMEDIATE_SIZE : integer := 12;

  signal is_immediate    : std_logic;
  signal data1           : unsigned(REGISTER_SIZE-1 downto 0);
  signal data2           : unsigned(REGISTER_SIZE-1 downto 0);
  signal data_result     : unsigned(REGISTER_SIZE-1 downto 0);
  signal immediate_value : unsigned(REGISTER_SIZE-1 downto 0);

  signal shift_amt      : natural range 0 to REGISTER_SIZE-1;
  signal shifted_value  : signed(REGISTER_SIZE downto 0);
  signal shifted_result : signed(REGISTER_SIZE downto 0);
  signal op1            : signed(REGISTER_SIZE downto 0);
  signal op2            : signed(REGISTER_SIZE downto 0);
  signal sub            : signed(REGISTER_SIZE downto 0);
  signal slt_val        : unsigned(REGISTER_SIZE-1 downto 0);

begin  -- architecture rtl

  is_immediate <= not instruction(5);
  immediate_value <= unsigned(sign_extension(REGISTER_SIZE-OP_IMM_IMMEDIATE_SIZE-1 downto 0)&
                              instruction(31 downto 20));
  data1 <= unsigned(rs1_data);
  data2 <= unsigned(rs2_data) when is_immediate = '0' else immediate_value;

  shift_amt     <= to_integer(data2(log2(REGISTER_SIZE)-1 downto 0));
  shifted_value <= signed((instruction(30) and rs1_data(rs1_data'left)) & rs1_data);
  shifted_result <= signed(SHIFT_RIGHT(signed(shifted_value),
                                                shift_amt));
  --combine slt
  op1     <= signed((not instruction(12) and data1(data1'left)) & data1);
  op2     <= signed((not instruction(12) and data2(data2'left)) & data2);
  sub     <= op1 - op2;
  slt_val <= to_unsigned(1, REGISTER_SIZE) when sub(sub'left) = '1' else to_unsigned(0, REGISTER_SIZE);

  alu_proc : process(clk) is
    variable func        : std_logic_vector(2 downto 0);
    variable data_result : unsigned(REGISTER_SIZE-1 downto 0);
    variable subtract    : std_logic;
  begin
    if rising_edge(clk) then
      if stall = '0' then
        func     := instruction(14 downto 12);
        subtract := instruction(30) and not is_immediate;
        case func is
          when ADD_OP =>
            if subtract = '1' then
              data_result := unsigned(sub(REGISTER_SIZE-1 downto 0));
            else
              data_result := data1 + data2;
            end if;
          when SLL_OP =>
            data_result := SHIFT_LEFT(data1, shift_amt);
          when SLT_OP =>
            data_result := slt_val;
          when SLTU_OP =>
            data_result := slt_val;
          when XOR_OP =>
            data_result := data1 xor data2;
          when SR_OP =>
            data_result := unsigned(shifted_result(REGISTER_SIZE-1 downto 0));
          when OR_OP =>
            data_result := data1 or data2;
          when AND_OP =>
            data_result := data1 and data2;
          when others => null;
        end case;

        case instruction(6 downto 0) is
          when "0010011" => data_enable <= '1';
          when "0110011" => data_enable <= '1';
          when others    => data_enable <= '0';
        end case;
        data_out <= std_logic_vector(data_result);

      end if;  --stall
    end if;  --clock
  end process;
end architecture;
