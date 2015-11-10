library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;
library work;
use work.utils.all;


entity shifter is

  generic (
    REGISTER_SIZE : natural
    );
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

begin  -- architecture rtl

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


entity divider is
  generic (
    REGISTER_SIZE : natural
    );
  port(
    clk         : in  std_logic;
    enable      : in  boolean;
    numerator   : in  unsigned(REGISTER_SIZE-1 downto 0);
    denominator : in  unsigned(REGISTER_SIZE-1 downto 0);
    quotient    : out unsigned(REGISTER_SIZE-1 downto 0);
    remainder   : out unsigned(REGISTER_SIZE-1 downto 0);
    done        : out std_logic
    );
end entity;

architecture rtl of divider is
  type FSM_state is (START, DIVIDING, FINISH);
  signal state : FSM_state := FINISH;
  signal count : natural range REGISTER_SIZE-1 downto 0;
begin  -- architecture rtl

  --P := N
  --D := D << n              * P and D need twice the word width of N and Q
  --for i = n-1..0 do        * for example 31..0 for 32 bits
  --  if P >= 0 then
  --    q[i] := +1
  --    P := 2*P - D
  --  else
  --    q[i] := -1
  --    P := 2*P + D
  --  end if
  --end

-- Where: N = Numerator, D = Denominator, n = #bits, P = Partial remainder, q(i) = bit #i of quotient
  div_proc : process(clk)
    variable R : unsigned(REGISTER_SIZE -1 downto 0);
    variable Q : unsigned(REGISTER_SIZE-1 downto 0);
    alias D    : unsigned(REGISTER_SIZE-1 downto 0) is denominator;
    alias N    : unsigned(REGISTER_SIZE-1 downto 0) is numerator;
  begin
    if RISING_EDGE(clk) then
      case state is
        when START =>
          Q    := (others => '0');
          R    := (others => '0');
          R(0) := N(N'left);
          if R >= D then
            R         := R - D;
            Q(Q'left) := '1';
          end if;
          if enable then
            state <= DIVIDING;
            count <= Q'left - 1;
          end if;
        when DIVIDING =>
          assert enable report "enable went low during divide" severity error;
          R(REGISTER_SIZE-1 downto 1) := R(REGISTER_SIZE-2 downto 0);
          R(0)                        := N(count);
          if R >= D then
            R        := R - D;
            Q(count) := '1';
          end if;
          if count /= 0 then
            count <= count - 1;
          else
            done  <= '1';
            state <= FINISH;
          end if;
        when FINISH =>
          done  <= '0';
          state <= START;
      end case;
      remainder <= R;
      quotient  <= Q;

    end if;  -- clk
  end process;

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
    SIGN_EXTENSION_SIZE : integer;
    MULTIPLY_ENABLE     : boolean);

  port (
    clk             : in  std_logic;
    stall_in        : in  std_logic;
    valid           : in  std_logic;
    rs1_data        : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    rs2_data        : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    instruction     : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    sign_extension  : in  std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
    program_counter : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_out        : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_enable     : out std_logic;
    stall_out       : out std_logic
    );

end entity arithmetic_unit;

architecture rtl of arithmetic_unit is

  constant SHIFTER_USE_MULTIPLIER : boolean := MULTIPLY_ENABLE;
  --constant SHIFTER_USE_MULTIPLIER : boolean := false;
  --op codes
  constant OP     : std_logic_vector(6 downto 0) := "0110011";
  constant OP_IMM : std_logic_vector(6 downto 0) := "0010011";
  constant LUI    : std_logic_vector(6 downto 0) := "0110111";
  constant AUIPC  : std_logic_vector(6 downto 0) := "0010111";


  constant MUL_OP    : std_logic_vector(2 downto 0) := "000";
  constant MULH_OP   : std_logic_vector(2 downto 0) := "001";
  constant MULHSU_OP : std_logic_vector(2 downto 0) := "010";
  constant MULHU_OP  : std_logic_vector(2 downto 0) := "011";
  constant DIV_OP    : std_logic_vector(2 downto 0) := "100";
  constant DIVU_OP   : std_logic_vector(2 downto 0) := "101";
  constant REM_OP    : std_logic_vector(2 downto 0) := "110";
  constant REMU_OP   : std_logic_vector(2 downto 0) := "111";

  constant ADD_OP  : std_logic_vector(2 downto 0) := "000";
  constant SLL_OP  : std_logic_vector(2 downto 0) := "001";
  constant SLT_OP  : std_logic_vector(2 downto 0) := "010";
  constant SLTU_OP : std_logic_vector(2 downto 0) := "011";
  constant XOR_OP  : std_logic_vector(2 downto 0) := "100";
  constant SR_OP   : std_logic_vector(2 downto 0) := "101";
  constant OR_OP   : std_logic_vector(2 downto 0) := "110";
  constant AND_OP  : std_logic_vector(2 downto 0) := "111";
  constant MUL_F7  : std_logic_vector(6 downto 0) := "0000001";

  constant OP_IMM_IMMEDIATE_SIZE : integer := 12;
  constant UP_IMM_IMMEDIATE_SIZE : integer := 20;

  alias func3  : std_logic_vector(2 downto 0) is instruction(14 downto 12);
  alias func7  : std_logic_vector(6 downto 0) is instruction(31 downto 25);
  alias opcode : std_logic_vector(6 downto 0) is instruction(6 downto 0);

  signal is_immediate    : std_logic;
  signal data1           : unsigned(REGISTER_SIZE-1 downto 0);
  signal data2           : unsigned(REGISTER_SIZE-1 downto 0);
  signal data_result     : unsigned(REGISTER_SIZE-1 downto 0);
  signal immediate_value : unsigned(REGISTER_SIZE-1 downto 0);

  signal shifter_multiply : signed(REGISTER_SIZE downto 0);


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


  signal m_op1_msk : std_logic;
  signal m_op2_msk : std_logic;
  signal m_op1     : signed(REGISTER_SIZE downto 0);
  signal m_op2     : signed(REGISTER_SIZE downto 0);
  signal mult_srca : signed(REGISTER_SIZE downto 0);
  signal mult_srcb : signed(REGISTER_SIZE downto 0);
  signal mult_dest : signed((REGISTER_SIZE+1)*2-1 downto 0);

  signal unsigned_div : std_logic;
  signal div_op1      : unsigned(REGISTER_SIZE-1 downto 0);
  signal div_op2      : unsigned(REGISTER_SIZE-1 downto 0);
  signal div_result   : signed(REGISTER_SIZE-1 downto 0);
  signal rem_result   : signed(REGISTER_SIZE-1 downto 0);
  signal quotient     : unsigned(REGISTER_SIZE-1 downto 0);
  signal remainder    : unsigned(REGISTER_SIZE-1 downto 0);

  --min signed value
  signal min_s : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal zero : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal neg1 : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal neg_op1   : std_logic;
  signal neg_op2   : std_logic;
  signal div_neg   : std_logic;
  signal div_done  : std_logic;
  signal div_stall : std_logic;

  signal div_en       : boolean;
  signal div_zero     : boolean;
  signal div_overflow : boolean;


  component shifter is
    generic (
      REGISTER_SIZE : natural);
    port(
      shift_amt     : in  unsigned(log2(REGISTER_SIZE)-1 downto 0);
      shifted_value : in  signed(REGISTER_SIZE downto 0);
      left_result   : out unsigned(REGISTER_SIZE-1 downto 0);
      right_result  : out unsigned(REGISTER_SIZE-1 downto 0));
  end component shifter;
  component divider is
    generic (
      REGISTER_SIZE : natural
      );
    port(
      clk         : in std_logic;
      enable      : in boolean;
      numerator   : in unsigned(REGISTER_SIZE-1 downto 0);
      denominator : in unsigned(REGISTER_SIZE-1 downto 0);

      quotient  : out unsigned(REGISTER_SIZE-1 downto 0);
      remainder : out unsigned(REGISTER_SIZE-1 downto 0);
      done      : out std_logic
      );
  end component;

begin  -- architecture rtl

  is_immediate <= not instruction(5);
  immediate_value <= unsigned(sign_extension(REGISTER_SIZE-OP_IMM_IMMEDIATE_SIZE-1 downto 0)&
                              instruction(31 downto 20));
  data1 <= unsigned(rs1_data);
  data2 <= unsigned(rs2_data) when is_immediate = '0' else immediate_value;
  shift_amt_mul_gen : if SHIFTER_USE_MULTIPLIER generate
    shift_amt <= unsigned(data2(log2(REGISTER_SIZE)-1 downto 0)) when instruction(14) = '0'else
                 32-unsigned(data2(log2(REGISTER_SIZE)-1 downto 0));

  end generate shift_amt_mul_gen;
  shift_amt_gen : if not SHIFTER_USE_MULTIPLIER generate
    shift_amt <= unsigned(data2(log2(REGISTER_SIZE)-1 downto 0));
  end generate shift_amt_gen;

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


  shifter_multiply <=
    "0"&x"00000001" when shift_amt = x"00"else
    "0"&x"00000002" when shift_amt = x"01"else
    "0"&x"00000004" when shift_amt = x"02"else
    "0"&x"00000008" when shift_amt = x"03"else
    "0"&x"00000010" when shift_amt = x"04"else
    "0"&x"00000020" when shift_amt = x"05"else
    "0"&x"00000040" when shift_amt = x"06"else
    "0"&x"00000080" when shift_amt = x"07"else
    "0"&x"00000100" when shift_amt = x"08"else
    "0"&x"00000200" when shift_amt = x"09"else
    "0"&x"00000400" when shift_amt = x"0A"else
    "0"&x"00000800" when shift_amt = x"0B"else
    "0"&x"00001000" when shift_amt = x"0C"else
    "0"&x"00002000" when shift_amt = x"0D"else
    "0"&x"00004000" when shift_amt = x"0E"else
    "0"&x"00008000" when shift_amt = x"0F"else
    "0"&x"00010000" when shift_amt = x"10"else
    "0"&x"00020000" when shift_amt = x"11"else
    "0"&x"00040000" when shift_amt = x"12"else
    "0"&x"00080000" when shift_amt = x"13"else
    "0"&x"00100000" when shift_amt = x"14"else
    "0"&x"00200000" when shift_amt = x"15"else
    "0"&x"00400000" when shift_amt = x"16"else
    "0"&x"00800000" when shift_amt = x"17"else
    "0"&x"01000000" when shift_amt = x"18"else
    "0"&x"02000000" when shift_amt = x"19"else
    "0"&x"04000000" when shift_amt = x"1A"else
    "0"&x"08000000" when shift_amt = x"1B"else
    "0"&x"10000000" when shift_amt = x"1C"else
    "0"&x"20000000" when shift_amt = x"1D"else
    "0"&x"40000000" when shift_amt = x"1E"else
    "0"&x"80000000";






  alu_proc : process(clk) is
    variable func        : std_logic_vector(2 downto 0);
    variable mul_result  : unsigned(REGISTER_SIZE-1 downto 0);
    variable base_result : unsigned(REGISTER_SIZE-1 downto 0);
    variable subtract    : std_logic;
  begin
    if rising_edge(clk) then
      func     := instruction(14 downto 12);
      subtract := instruction(30) and not is_immediate;
      case func is
        when ADD_OP =>
          if subtract = '1' then
            base_result := unsigned(sub(REGISTER_SIZE-1 downto 0));
          else
            base_result := data1 + data2;
          end if;
        when SLL_OP =>
          if SHIFTER_USE_MULTIPLIER then
            base_result := unsigned(mult_dest(REGISTER_SIZE-1 downto 0));
          else
            base_result := lshifted_result;
          end if;

        when SLT_OP =>
          base_result := slt_val;
        when SLTU_OP =>
          base_result := slt_val;
        when XOR_OP =>
          base_result := data1 xor data2;
        when SR_OP =>
          if SHIFTER_USE_MULTIPLIER then
            if shift_amt = x"00" then
              base_result := unsigned(shifted_value(REGISTER_SIZE-1 downto 0));
            else
              base_result := unsigned(mult_dest(REGISTER_SIZE*2-1 downto REGISTER_SIZE));
            end if;
          else
            base_result := rshifted_result;
          end if;
        when OR_OP =>
          base_result := data1 or data2;
        when AND_OP =>
          base_result := data1 and data2;
        when others => null;
      end case;
      case func is
        when MUL_OP =>
          mul_result := unsigned(mult_dest(REGISTER_SIZE-1 downto 0));
        when MULH_OP=>
          mul_result := unsigned(mult_dest(REGISTER_SIZE*2-1 downto REGISTER_SIZE));
        when MULHSU_OP =>
          mul_result := unsigned(mult_dest(REGISTER_SIZE*2-1 downto REGISTER_SIZE));
        when MULHU_OP =>
          mul_result := unsigned(mult_dest(REGISTER_SIZE*2-1 downto REGISTER_SIZE));
        when DIV_OP =>
          if div_zero then
            mul_result := unsigned(neg1);
          elsif div_overflow then
            mul_result := unsigned(min_s);
          else
            mul_result := unsigned(div_result);
          end if;
        when DIVU_OP =>
          if div_zero then
            --this conforms with test, not standard
            mul_result := unsigned(neg1);
          else
            mul_result := unsigned(div_result);
          end if;
        when REM_OP =>
          if div_zero then
            mul_result := unsigned(rs1_data);
          elsif div_overflow then
            mul_result := unsigned(zero);
          else
            mul_result := unsigned(rem_result);
          end if;
        when others =>
          if div_zero then
            mul_result := unsigned(rs1_data);
          else
            mul_result := unsigned(rem_result);
          end if;
      end case;

      if stall_in = '0' then
        case OPCODE is
          when OP     => data_enable <= valid;
          when OP_IMM => data_enable <= valid;
          when LUI    => data_enable <= valid;
          when AUIPC  => data_enable <= valid;
          when others => data_enable <= '0';
        end case;
        if opcode = LUI or opcode = AUIPC then
          data_out <= std_logic_vector(upper_immediate);
        elsif func7 = mul_f7 and not is_immediate = '1' and MULTIPLY_ENABLE then
          data_out <= std_logic_vector(mul_result);
        else
          data_out <= std_logic_vector(base_result);
        end if;
      end if;
    end if;  --clock
  end process;

  m_op1_msk <= '0' when instruction(13 downto 12) = "11" else '1';
  m_op2_msk <= not instruction(13);
  m_op1     <= signed((m_op1_msk and rs1_data(data1'left)) & data1);
  m_op2     <= signed((m_op2_msk and rs2_data(data2'left)) & data2);

  mult_srca <= signed(m_op1) when func7 = mul_f7  or not SHIFTER_USE_MULTIPLIER else shifter_multiply;
  mult_srcb <= signed(m_op2) when func7 = mul_f7  or not SHIFTER_USE_MULTIPLIER else shifted_value;

  mult_dest <= mult_srca * mult_srcb;

  unsigned_div <= instruction(12);
  neg_op1      <= not unsigned_div when signed(rs1_data) < 0 else '0';
  neg_op2      <= not unsigned_div when signed(rs2_data) < 0 else '0';
  div_neg      <= neg_op1 xor neg_op2;

  div_op1 <= unsigned(rs1_data) when neg_op1 = '0' else unsigned(-signed(rs1_data));
  div_op2 <= unsigned(rs2_data) when neg_op2 = '0' else unsigned(-signed(rs2_data));

                                        --min signed value
  min_s(min_s'left)            <= '1';
  min_s(min_s'left-1 downto 0) <= (others => '0');
  zero                         <= (others => '0');
  neg1                         <= (others => '1');


  div_zero     <= rs2_data = zero;
  div_overflow <= rs1_data = min_s and rs2_data = neg1;
  div_en       <= (func7 = mul_f7 and opcode = OP and instruction(14) = '1')and not div_zero;
  div : component divider
    generic map (
      REGISTER_SIZE => REGISTER_SIZE)
    port map (
      clk         => clk,
      enable      => div_en,
      numerator   => div_op1,
      denominator => div_op2,
      quotient    => quotient,
      remainder   => remainder,
      done        => div_done);
  div_result <= signed(quotient)  when div_neg = '0' else -signed(quotient);
  rem_result <= signed(remainder) when neg_op1 = '0' else -signed(remainder);

  div_stall <= not div_done when div_en else '0';
  stall_out <= div_stall when MULTIPLY_ENABLE else '0';
end architecture;
