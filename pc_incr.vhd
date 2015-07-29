library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity pc_incr is

  generic (
	 REGISTER_SIZE		: positive;
	 INSTRUCTION_SIZE : positive);
  port (
	 pc			: in std_logic_vector(REGISTER_SIZE-1 downto 0);
	 instr		: in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
	 pc_corr		: in std_logic_vector(REGISTER_SIZE-1 downto 0);
	 pc_corr_en : in std_logic;

	 next_pc : out std_logic_vector(REGISTER_SIZE-1 downto 0));
end entity pc_incr;

architecture rtl of pc_incr is

begin	 -- architecture pc_insr
  pc_incr_proc : process (pc, instr, pc_corr, pc_corr_en) is

	 constant IMMEDIATE_SIZE		: integer := 13;
	 constant SIGN_EXTENSION_SIZE : integer := REGISTER_SIZE -IMMEDIATE_SIZE;

	 --only ever need negative sign extension, because we assume forward
	 --branches not taken
	 constant SIGN_EXTENSION : std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0) := (others => '1');
	 constant BRANCH_OP		 : std_logic_vector(6 downto 0)							 := "1100011";

	 variable imm_val		: unsigned(REGISTER_SIZE-1 downto 0);	--ammount to add
	 variable current_pc : unsigned(REGISTER_SIZE-1 downto 0);
  begin	-- process pc_incr_proc

	 imm_val := unsigned(sign_extension & instr(31) & instr(7) & instr(30 downto 25)& instr(11 downto 8) & "0");
	 if pc_corr_en = '1' then
		current_pc := unsigned(pc_corr);
	 else
		current_pc := unsigned(pc);
	 end if;

	 --if backward direction branch, predict taken, othrewise just increment pc
	 if instr(6 downto 0) = BRANCH_OP and instr(instr'left) = '1' then
		next_pc <= std_logic_vector(imm_val + current_pc);
	 else
		next_pc <= std_logic_vector(current_pc+4);
	 end if;
  end process pc_incr_proc;


end architecture rtl;

--last_pc
--this_pc
--last_instr
--ready
