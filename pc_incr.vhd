library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;


entity pc_incr is

  generic (
    REGISTER_SIZE    : positive;
    INSTRUCTION_SIZE : positive);
  port (
    pc          : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    instr       : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    valid_instr : in  std_logic;
    next_pc     : out std_logic_vector(REGISTER_SIZE-1 downto 0));
end entity pc_incr;

architecture rtl of pc_incr is
  alias opcode : std_logic_vector(6 downto 0) is instr(6 downto 0);

  constant B_IMM_SIZE          : integer := 13;
  constant SIGN_EXTENSION_SIZE : integer := REGISTER_SIZE -B_IMM_SIZE;

  constant SIGN_EXTENSION : signed(SIGN_EXTENSION_SIZE-1 downto 0) := (others => '1');

  constant BRANCH_OP : std_logic_vector(6 downto 0) := "1100011";
  constant JAL_OP    : std_logic_vector(6 downto 0) := "1101111";

  signal brch_imm  : signed(REGISTER_SIZE-1 downto 0);
  signal jal_imm   : signed(REGISTER_SIZE-1 downto 0);
  signal immediate : signed(REGISTER_SIZE-1 downto 0);

begin  -- architecture pc_insr

  --predict backwards taken,fowrwads not taken
  brch_imm <= SIGN_EXTENSION &
              signed(instr(31) & instr(7) &
                     instr(30 downto 25) & instr(11 downto 8)&"0") when instr(31) = '1'
              else to_signed(4, REGISTER_SIZE);
  jal_imm <= resize(signed(instr(31) & instr(19 downto 12) &
                           instr(20) & instr(30 downto 21)&"0"),
                    REGISTER_SIZE);
  with opcode select
    immediate <=
    brch_imm                    when BRANCH_OP,
    jal_imm                     when JAL_OP,
    to_signed(4, REGISTER_SIZE) when others;

  next_pc    <= std_logic_vector(signed(pc) + immediate) when valid_instr = '1' else pc;



end architecture rtl;

--last_pc
--this_pc
--last_instr
--ready
