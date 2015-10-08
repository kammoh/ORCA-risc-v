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

  constant USE_BRANCH_PREDICT : boolean := false;
begin  -- architecture pc_insr

  use_BP : if USE_BRANCH_PREDICT generate
    alias opcode : std_logic_vector(6 downto 0) is instr(6 downto 0);

    constant B_IMM_SIZE          : integer := 13;
    constant SIGN_EXTENSION_SIZE : integer := REGISTER_SIZE -B_IMM_SIZE;

    constant SIGN_EXTENSION : signed(SIGN_EXTENSION_SIZE-1 downto 0) := (others => '1');

    constant BRANCH_OP : std_logic_vector(6 downto 0) := "1100011";
    constant JAL_OP    : std_logic_vector(6 downto 0) := "1101111";

    signal brch_imm  : signed(REGISTER_SIZE-1 downto 0);
    signal jal_imm   : signed(REGISTER_SIZE-1 downto 0);
    signal immediate : signed(REGISTER_SIZE-1 downto 0);
    signal mux_sel   : std_logic_vector(1 downto 0);
  begin
    brch_imm <= SIGN_EXTENSION &
                signed(instr(31) & instr(7) &
                       instr(30 downto 25) & instr(11 downto 8)&"0") ;

    jal_imm <= resize(signed(instr(31) & instr(19 downto 12) &
                             instr(20) & instr(30 downto 21)&"0"),
                      REGISTER_SIZE);

    --predict backwards taken,fowrwads not taken
    mux_sel <= "00" when opcode = BRANCH_OP and instr(31)='1' else
               "01" when opcode = JAL_OP else
               "10";

    with mux_sel select
      immediate <=
      brch_imm                    when "00",
      jal_imm                     when "01",
      to_signed(4, REGISTER_SIZE) when others;

    next_pc <= std_logic_vector(signed(pc) + immediate) when valid_instr = '1' else pc;

  end generate use_BP;
  nuse_BP : if not USE_BRANCH_PREDICT generate

    next_pc <= std_logic_vector(signed(pc) + to_signed(4, REGISTER_SIZE)) when valid_instr = '1' else pc;

  end generate nuse_BP;



end architecture rtl;

--last_pc
--this_pc
--last_instr
--ready
