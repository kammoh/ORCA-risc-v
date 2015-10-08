library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;
--use IEEE.std_logic_arith.all;

entity branch_unit is


  generic (
    REGISTER_SIZE       : integer;
    INSTRUCTION_SIZE    : integer;
    SIGN_EXTENSION_SIZE : integer);

  port (
    clk            : in  std_logic;
    stall          : in  std_logic;
    reset          : in  std_logic;
    rs1_data       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    rs2_data       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    current_pc     : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    predicted_pc   : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    instr          : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    sign_extension : in  std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
    --unconditional jumps store return address in rd, output return address
    -- on data_out lines
    data_out       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_out_en    : out std_logic;
    new_pc         : out std_logic_vector(REGISTER_SIZE-1 downto 0);  --next pc
    bad_predict    : out std_logic
    );
end entity branch_unit;

architecture rtl of branch_unit is

  constant OP_IMM_IMMEDIATE_SIZE : integer := 12;

  --op codes
  constant JAL    : std_logic_vector(6 downto 0) := "1101111";
  constant JALR   : std_logic_vector(6 downto 0) := "1100111";
  constant BRANCH : std_logic_vector(6 downto 0) := "1100011";

  --func3
  constant BEQ  : std_logic_vector(2 downto 0) := "000";
  constant BNE  : std_logic_vector(2 downto 0) := "001";
  constant BLT  : std_logic_vector(2 downto 0) := "100";
  constant BGE  : std_logic_vector(2 downto 0) := "101";
  constant BLTU : std_logic_vector(2 downto 0) := "110";
  constant BGEU : std_logic_vector(2 downto 0) := "111";

  alias func3  : std_logic_vector(2 downto 0) is instr(14 downto 12);
  alias opcode : std_logic_vector(6 downto 0) is instr(6 downto 0);

  --these are one bit larget than a register
  signal op1      : signed(REGISTER_SIZE downto 0);
  signal op2      : signed(REGISTER_SIZE downto 0);
  signal sub      : signed(REGISTER_SIZE downto 0);
  signal msb_mask : std_logic;

  signal jal_imm        : unsigned(REGISTER_SIZE-1 downto 0);
  signal jalr_imm       : unsigned(REGISTER_SIZE-1 downto 0);
  signal b_imm          : unsigned(REGISTER_SIZE-1 downto 0);
  signal branch_target  : unsigned(REGISTER_SIZE-1 downto 0);
  signal nbranch_target : unsigned(REGISTER_SIZE-1 downto 0);
  signal jalr_target    : unsigned(REGISTER_SIZE-1 downto 0);
  signal jal_target     : unsigned(REGISTER_SIZE-1 downto 0);
  signal target_pc      : unsigned(REGISTER_SIZE-1 downto 0);

  signal leq_flg : std_logic;
  signal eq_flg  : std_logic;

  signal branch_taken : std_logic;


begin  -- architecture rtl

  with func3 select
    msb_mask <=
    '0' when BLTU,
    '0' when BGEU,
    '1' when others;



  op1 <= signed((msb_mask and rs1_data(rs1_data'left)) & rs1_data);
  op2 <= signed((msb_mask and rs2_data(rs2_data'left)) & rs2_data);
  sub <= op1 - op2;

  eq_flg  <= '1' when op1 = op2 else '0';
  leq_flg <= sub(sub'left);

  --branch_taken <= '1' when ((func3 = beq and (eq_flg) = '1') or
  --                          (func3 = bne and (not eq_flg) = '1') or
  --                          (func3 = blt and (leq_flg and not eq_flg) = '1') or
  --                          (func3 = bge and (not leq_flg or eq_flg) = '1') or
  --                          (func3 = bltu and (leq_flg and not eq_flg) = '1') or
  --                          (func3 = bgeu and (not leq_flg or eq_flg) = '1')
  --                          ) else '0';

  with func3 select
    branch_taken <=
    eq_flg                 when beq,
    not eq_flg             when bne,
    leq_flg and not eq_flg when blt,
    not leq_flg or eq_flg  when bge,
    leq_flg and not eq_flg when bltu,
    not leq_flg or eq_flg  when bgeu,
    '0'                    when others;

  b_imm <= unsigned(sign_extension(REGISTER_SIZE-13 downto 0) &
                    instr(7) & instr(30 downto 25) &instr(11 downto 8) & "0");

  jalr_imm <= unsigned(sign_extension(REGISTER_SIZE-12-1 downto 0) &
                       instr(31 downto 21) & "0") ;
  jal_imm <= unsigned(RESIZE(signed(instr(31) & instr(19 downto 12) & instr(20) &
                                    instr(30 downto 21)&"0"),REGISTER_SIZE));


  branch_target  <= b_imm + unsigned(current_pc);
  nbranch_target <= to_unsigned(4, REGISTER_SIZE) + unsigned(current_pc);
  jalr_target    <= jalr_imm + unsigned(rs1_data);
  jal_target     <= jal_imm + unsigned(current_pc);

  with branch_taken & opcode select
    target_pc <=
    branch_target  when "1" & BRANCH,
    nbranch_target when "0" & BRANCH,
    jalr_target    when "0" & JALR,
    jalr_target    when "1" & JALR,
    jal_target     when others;

  --target_pc <= branch_target when branch_taken = '1' and opcode = BRANCH else
  --             jump_target when opcode = JALR else
  --             unsigned(current_pc) +to_unsigned(4, REGISTER_SIZE);

  br_proc : process (clk, reset) is
  begin  -- process br_proc
    if rising_edge(clk) then
      if reset = '1' then
        bad_predict <= '0';
        data_out_en <= '0';
      else
        if stall = '0' then
          data_out <= std_logic_vector(unsigned(current_pc) +
                                       to_unsigned(4, REGISTER_SIZE));

          if opcode = JAL or opcode = JALR then
            data_out_en <= '1';
          else
            data_out_en <= '0';
          end if;
          new_pc <= std_logic_vector(target_pc);
          if (opcode = BRANCH and target_pc /= unsigned(predicted_pc)) or opcode = JALR or opcode = JAL then
            bad_predict <= '1';
          else
            bad_predict <= '0';
          end if;
        end if;  --stall
      end if;  --reset
    end if;  --clk

  end process br_proc;

end architecture;
