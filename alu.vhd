library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;
library work;
use work.utils.all;


entity shifter is

  generic (
    REGISTER_SIZE : natural);
  port(
    shift_amt     : in  unsigned(log2(REGISTER_SIZE)-1 downto 0);
    shifted_value : in  signed(REGISTER_SIZE downto 0);
    left_result   : out unsigned(REGISTER_SIZE-1 downto 0);
    right_result  : out unsigned(REGISTER_SIZE-1 downto 0));
end entity shifter;

architecture rtl of shifter is

  constant SHIFT_AMT_SIZE : natural := shift_amt'length;
  signal left_tmp         : signed(REGISTER_SIZE downto 0);
  signal right_tmp        : signed(REGISTER_SIZE downto 0);

--  signal multiply_val : signed(REGISTER_SIZE downto 0);
begin  -- architecture rtl
  --with shift_amt select
  --  multiply_val <=
  --  SHIFT_LEFT(to_signed(1,REGISTER_SIZE+1) ,0 ) when to_signed(0, shift_amt'length),
  --  SHIFT_LEFT(to_signed(1,REGISTER_SIZE+1) ,1 ) when to_signed(1, shift_amt'length),
  --  SHIFT_LEFT(to_signed(1,REGISTER_SIZE+1) ,2 ) when to_signed(2, shift_amt'length),
  --  SHIFT_LEFT(to_signed(1,REGISTER_SIZE+1) ,3 ) when to_signed(3, shift_amt'length),
  --  SHIFT_LEFT(to_signed(1,REGISTER_SIZE+1) ,4 ) when to_signed(4, shift_amt'length),
  --  SHIFT_LEFT(to_signed(1,REGISTER_SIZE+1) ,5 ) when to_signed(5, shift_amt'length),
  --  SHIFT_LEFT(to_signed(1,REGISTER_SIZE+1) ,6 ) when to_signed(6, shift_amt'length),
  --  SHIFT_LEFT(to_signed(1,REGISTER_SIZE+1) ,7 ) when to_signed(7, shift_amt'length),
  --  SHIFT_LEFT(to_signed(1,REGISTER_SIZE+1) ,8 ) when to_signed(8, shift_amt'length),
  --  SHIFT_LEFT(to_signed(1,REGISTER_SIZE+1) ,9 ) when to_signed(9, shift_amt'length),
  --  SHIFT_LEFT(to_signed(1, REGISTER_SIZE+1),10) when to_signed(10, shift_amt'length),
  --  SHIFT_LEFT(to_signed(1, REGISTER_SIZE+1),11) when to_signed(11, shift_amt'length),
  --  SHIFT_LEFT(to_signed(1, REGISTER_SIZE+1),12) when to_signed(12, shift_amt'length),
  --  SHIFT_LEFT(to_signed(1, REGISTER_SIZE+1),13) when to_signed(13, shift_amt'length),
  --  SHIFT_LEFT(to_signed(1, REGISTER_SIZE+1),14) when to_signed(14, shift_amt'length),
  --  SHIFT_LEFT(to_signed(1, REGISTER_SIZE+1),15) when to_signed(15, shift_amt'length),
  --  SHIFT_LEFT(to_signed(1, REGISTER_SIZE+1),16) when to_signed(16, shift_amt'length),
  --  SHIFT_LEFT(to_signed(1, REGISTER_SIZE+1),17) when to_signed(17, shift_amt'length),
  --  SHIFT_LEFT(to_signed(1, REGISTER_SIZE+1),18) when to_signed(18, shift_amt'length),
  --  SHIFT_LEFT(to_signed(1, REGISTER_SIZE+1),19) when to_signed(19, shift_amt'length),
  --  SHIFT_LEFT(to_signed(1, REGISTER_SIZE+1),20) when to_signed(20, shift_amt'length),
  --  SHIFT_LEFT(to_signed(1, REGISTER_SIZE+1),21) when to_signed(21, shift_amt'length),
  --  SHIFT_LEFT(to_signed(1, REGISTER_SIZE+1),22) when to_signed(22, shift_amt'length),
  --  SHIFT_LEFT(to_signed(1, REGISTER_SIZE+1),23) when to_signed(23, shift_amt'length),
  --  SHIFT_LEFT(to_signed(1, REGISTER_SIZE+1),24) when to_signed(24, shift_amt'length),
  --  SHIFT_LEFT(to_signed(1, REGISTER_SIZE+1),25) when to_signed(25, shift_amt'length),
  --  SHIFT_LEFT(to_signed(1, REGISTER_SIZE+1),26) when to_signed(26, shift_amt'length),
  --  SHIFT_LEFT(to_signed(1, REGISTER_SIZE+1),27) when to_signed(27, shift_amt'length),
  --  SHIFT_LEFT(to_signed(1, REGISTER_SIZE+1),28) when to_signed(28, shift_amt'length),
  --  SHIFT_LEFT(to_signed(1, REGISTER_SIZE+1),29) when to_signed(29, shift_amt'length),
  --  SHIFT_LEFT(to_signed(1, REGISTER_SIZE+1),30) when to_signed(30, shift_amt'length),
  --  SHIFT_LEFT(to_signed(1, REGISTER_SIZE+1),31) when others;
--  left_tmp     <= RESIZE(shifted_value*multiply_val,REGISTER_SIZE+1);

  left_tmp     <= SHIFT_LEFT(shifted_value, to_integer(shift_amt));
  right_tmp    <= SHIFT_RIGHT(shifted_value, to_integer(shift_amt));
  right_result <= unsigned(right_tmp(REGISTER_SIZE-1 downto 0));

  left_result <= unsigned(left_tmp(REGISTER_SIZE-1 downto 0));

end architecture rtl;

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
    clk             : in  std_logic;
    stall           : in  std_logic;
    valid           : in  std_logic;
    rs1_data        : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    rs2_data        : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    instruction     : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    sign_extension  : in  std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
    program_counter : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_out        : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_enable     : out std_logic
    );

end entity arithmetic_unit;

architecture rtl of arithmetic_unit is

  --op codes
  constant OP     : std_logic_vector(6 downto 0) := "0110011";
  constant OP_IMM : std_logic_vector(6 downto 0) := "0010011";
  constant LUI    : std_logic_vector(6 downto 0) := "0110111";
  constant AUIPC  : std_logic_vector(6 downto 0) := "0010111";



  constant ADD_OP  : std_logic_vector(2 downto 0) := "000";
  constant SLL_OP  : std_logic_vector(2 downto 0) := "001";
  constant SLT_OP  : std_logic_vector(2 downto 0) := "010";
  constant SLTU_OP : std_logic_vector(2 downto 0) := "011";
  constant XOR_OP  : std_logic_vector(2 downto 0) := "100";
  constant SR_OP   : std_logic_vector(2 downto 0) := "101";
  constant OR_OP   : std_logic_vector(2 downto 0) := "110";
  constant AND_OP  : std_logic_vector(2 downto 0) := "111";

  constant OP_IMM_IMMEDIATE_SIZE : integer := 12;
  constant UP_IMM_IMMEDIATE_SIZE : integer := 20;

  alias func3  : std_logic_vector(2 downto 0) is instruction(14 downto 12);
  alias opcode : std_logic_vector(6 downto 0) is instruction(6 downto 0);

  signal is_immediate    : std_logic;
  signal data1           : unsigned(REGISTER_SIZE-1 downto 0);
  signal data2           : unsigned(REGISTER_SIZE-1 downto 0);
  signal data_result     : unsigned(REGISTER_SIZE-1 downto 0);
  signal immediate_value : unsigned(REGISTER_SIZE-1 downto 0);

  signal shift_amt       : unsigned(log2(REGISTER_SIZE)-1 downto 0);
  signal shifted_value   : signed(REGISTER_SIZE downto 0);
  signal rshifted_result : unsigned(REGISTER_SIZE-1 downto 0);
  signal lshifted_result : unsigned(REGISTER_SIZE-1 downto 0);
  signal op1             : signed(REGISTER_SIZE downto 0);
  signal op2             : signed(REGISTER_SIZE downto 0);
  signal sub             : signed(REGISTER_SIZE downto 0);
  signal slt_val         : unsigned(REGISTER_SIZE-1 downto 0);

  signal upp_imm_sel      : std_logic;
  signal upper_immediate1 : signed(REGISTER_SIZE-1 downto 0);
  signal upper_immediate  : signed(REGISTER_SIZE-1 downto 0);
  component shifter is

    generic (
      REGISTER_SIZE : natural);
    port(
      shift_amt     : in  unsigned(log2(REGISTER_SIZE)-1 downto 0);
      shifted_value : in  signed(REGISTER_SIZE downto 0);
      left_result   : out unsigned(REGISTER_SIZE-1 downto 0);
      right_result  : out unsigned(REGISTER_SIZE-1 downto 0));
  end component shifter;

begin  -- architecture rtl

  is_immediate <= not instruction(5);
  immediate_value <= unsigned(sign_extension(REGISTER_SIZE-OP_IMM_IMMEDIATE_SIZE-1 downto 0)&
                              instruction(31 downto 20));
  data1 <= unsigned(rs1_data);
  data2 <= unsigned(rs2_data) when is_immediate = '0' else immediate_value;

  shift_amt     <= unsigned(data2(log2(REGISTER_SIZE)-1 downto 0));
  shifted_value <= signed((instruction(30) and rs1_data(rs1_data'left)) & rs1_data);

  sh : component shifter
    generic map (
      REGiSTER_SIZE => REGISTER_SIZE)
    port map (
      shift_amt     => shift_amt,
      shifted_value => shifted_value,
      left_result   => lshifted_result,
      right_result  => rshifted_result);

--combine slt
  op1     <= signed((not instruction(12) and data1(data1'left)) & data1);
  op2     <= signed((not instruction(12) and data2(data2'left)) & data2);
  sub     <= op1 - op2;
  slt_val <= to_unsigned(1, REGISTER_SIZE) when sub(sub'left) = '1' else to_unsigned(0, REGISTER_SIZE);

  upp_imm_sel <= '1' when opcode = LUI or opcode = AUIPC else '0';

  upper_immediate1(31 downto 12) <= signed(instruction(31 downto 12));
  upper_immediate1(11 downto 0)  <= (others => '0');
  upper_immediate                <= upper_immediate1 when instruction(5) = '1' else upper_immediate1 + signed(program_counter);

  alu_proc : process(clk) is
    variable func        : std_logic_vector(2 downto 0);
    variable data_result : unsigned(REGISTER_SIZE-1 downto 0);
    variable subtract    : std_logic;
  begin
    if rising_edge(clk) then
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
          data_result := lshifted_result;
        when SLT_OP =>
          data_result := slt_val;
        when SLTU_OP =>
          data_result := slt_val;
        when XOR_OP =>
          data_result := data1 xor data2;
        when SR_OP =>
          data_result := rshifted_result;
        when OR_OP =>
          data_result := data1 or data2;
        when AND_OP =>
          data_result := data1 and data2;
        when others => null;
      end case;
      if stall = '0' then
        case OPCODE is
          when OP     => data_enable <= valid;
          when OP_IMM => data_enable <= valid;
          when LUI    => data_enable <= valid;
          when AUIPC  => data_enable <= valid;
          when others => data_enable <= '0';
        end case;
        if opcode = LUI or opcode = AUIPC then
          data_out <= std_logic_vector(upper_immediate);
        else
          data_out <= std_logic_vector(data_result);
        end if;
      end if;
  end if;  --clock
end process;
end architecture;
