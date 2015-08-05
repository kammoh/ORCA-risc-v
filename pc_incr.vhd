library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;


entity pc_incr is

  generic (
    REGISTER_SIZE    : positive;
    INSTRUCTION_SIZE : positive);
  port (
    pc      : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    instr   : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    next_pc : out std_logic_vector(REGISTER_SIZE-1 downto 0));
end entity pc_incr;

architecture rtl of pc_incr is

begin  -- architecture pc_insr
  pc_incr_proc : process (pc, instr) is

    constant B_IMM_SIZE          : integer := 13;
    constant SIGN_EXTENSION_SIZE : integer := REGISTER_SIZE -B_IMM_SIZE;

    --only ever need negative sign extension, because we assume forward
    --branches not taken
    constant SIGN_EXTENSION : signed(SIGN_EXTENSION_SIZE-1 downto 0) := (others => '1');
    constant BRANCH_OP      : std_logic_vector(6 downto 0)           := "1100011";
    constant JAL_OP         : std_logic_vector(6 downto 0)           := "1101111";

    variable imm_val    : signed(REGISTER_SIZE-1 downto 0);  --ammount to add
    variable current_pc : signed(REGISTER_SIZE-1 downto 0);
  begin  -- process pc_incr_proc

    current_pc := signed(pc);

    --if backward direction branch, predict taken, othrewise just increment pc
    case instr(6 downto 0) is
      when BRANCH_OP =>
        if instr(31) = '1' then         -- backward_branch
          imm_val := SIGN_EXTENSION &
                     signed(instr(31) & instr(7) &
                            instr(30 downto 25) & instr(11 downto 8)&"0");
        else
          imm_val := to_signed(4, 32);
        end if;
      when JAL_OP =>
        imm_val := resize(signed(instr(31) & instr(19 downto 12) &
                                 instr(20) & instr(30 downto 21)),
                          REGISTER_SIZE);
      when others =>
        imm_val := to_signed(4, 32);
    end case;
    next_pc <= std_logic_vector(current_pc+imm_val);

  end process pc_incr_proc;


end architecture rtl;

--last_pc
--this_pc
--last_instr
--ready
