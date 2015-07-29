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
  constant JAL    : unsigned(6 downto 0) := "1101111";
  constant JALR   : unsigned(6 downto 0) := "1100111";
  constant BRANCH : unsigned(6 downto 0) := "1100011";

  --func3
  constant BEQ  : std_logic_vector(2 downto 0) := "000";
  constant BNE  : std_logic_vector(2 downto 0) := "001";
  constant BLT  : std_logic_vector(2 downto 0) := "100";
  constant BGE  : std_logic_vector(2 downto 0) := "101";
  constant BLTU : std_logic_vector(2 downto 0) := "110";
  constant BGEU : std_logic_vector(2 downto 0) := "111";


begin  -- architecture rtl

  br_proc : process (clk, reset) is
    variable opcode        : unsigned(6 downto 0);
    variable imm_val       : unsigned(REGISTER_SIZE-1 downto 0);  --ammount to add
    variable next_pc       : unsigned(REGISTER_SIZE-1 downto 0);  --instruction after
                                                                  --the current
    variable calc_pc       : unsigned(REGISTER_SIZE-1 downto 0);
    variable branch_target : unsigned(REGISTER_SIZE-1 downto 0);
    variable is_branch     : std_logic;
  begin  -- process br_proc
    if rising_edge(clk) then
      if reset = '1' then
        bad_predict <= '0';
        data_out_en <= '0';
      else
        data_out_en <= '0';
        bad_predict <= '0';
        next_pc     := unsigned(current_pc)+4;
        opcode      := unsigned(instr(6 downto 0));

        calc_pc   := next_pc;
        is_branch := '1';
        case opcode is
          when BRANCH =>
            imm_val := unsigned(sign_extension(REGISTER_SIZE-13 downto 0) &
                                instr(7) & instr(30 downto 25) &instr(11 downto 8) & "0");

            branch_target := unsigned(current_pc) + imm_val;
            case instr(14 downto 12) is
              when BEQ =>
                if signed(rs1_data) = signed(rs2_data) then
                  calc_pc := branch_target;
                end if;
              when BNE =>
                if signed(rs1_data) /= signed(rs2_data) then
                  calc_pc := branch_target;
                end if;
              when BLT =>
                if signed(rs1_data) < signed(rs2_data) then
                  calc_pc := branch_target;
                end if;
              when BGE =>
                if signed(rs1_data) >= signed(rs2_data) then
                  calc_pc := branch_target;
                end if;
              when BLTU =>
                if unsigned(rs1_data) < unsigned(rs2_data) then
                  calc_pc := branch_target;
                end if;
              when BGEU =>
                if unsigned(rs1_data) /= unsigned(rs2_data) then
                  calc_pc := branch_target;
                end if;
              when others => null;
            end case;

          when JALR =>
            imm_val := unsigned(sign_extension(REGISTER_SIZE-12-1 downto 0) &
                                instr(31 downto 21) & "0");
            calc_pc     := imm_val + unsigned(rs1_data);
            data_out_en <= '1';
          when JAL =>
            imm_val := unsigned(sign_extension(REGISTER_SIZE-21 downto 0) &
                                instr(19 downto 12) & instr(20) & instr(30 downto 21) & "0");
            calc_pc     := imm_val + unsigned(current_pc);
            data_out_en <= '1';

          when others =>
            is_branch :=  '0';
        end case;

        if calc_pc /= unsigned(predicted_pc) then
          bad_predict <= is_branch;
        end if;
        new_pc   <= std_logic_vector(calc_pc);
        data_out <= std_logic_vector(next_pc);

      end if;  --reset

    end if;  --clk

  end process br_proc;

end architecture;
