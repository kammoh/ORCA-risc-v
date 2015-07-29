library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity instruction_fetch is
  generic (
	 REGISTER_SIZE			 : positive;
	 INSTRUCTION_SIZE		 : positive;
	 INSTRUCTION_MEM_SIZE : positive);
  port (
	 clk			: in std_logic;
	 reset		: in std_logic;
	 pc_corr		: in std_logic_vector(REGISTER_SIZE-1 downto 0);
	 pc_corr_en : in std_logic;

	 instr_out	 : out std_logic_vector(REGISTER_SIZE-1 downto 0);
	 pc_out		 : out std_logic_vector(REGISTER_SIZE-1 downto 0);
	 next_pc_out : out std_logic_vector(REGISTER_SIZE-1 downto 0));

end entity instruction_fetch;

architecture rtl of instruction_fetch is
  component pc_incr is

	 generic (
		REGISTER_SIZE	  : positive;
		INSTRUCTION_SIZE : positive);
	 port (
		pc			  : in std_logic_vector(REGISTER_SIZE-1 downto 0);
		instr		  : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
		pc_corr	  : in std_logic_vector(REGISTER_SIZE-1 downto 0);
		pc_corr_en : in std_logic;

		next_pc : out std_logic_vector(REGISTER_SIZE-1 downto 0));

  end component pc_incr;

  signal program_counter : std_logic_vector(REGISTER_SIZE -1 downto 0) := (others => '0');

  type memory_type is array(0 to INSTRUCTION_MEM_SIZE)
	 of std_logic_vector(REGISTER_SIZE-1 downto 0);

  function ARITH_INSTR (
	 immediate, rs1, rd : integer;
	 func					  : std_logic_vector(2 downto 0))
	 return std_logic_vector is
  begin
	 return std_logic_vector(to_unsigned(immediate, 12)) &
		std_logic_vector(to_unsigned(rs1, 5))& func &
		std_logic_vector(to_unsigned(rd, 5))&"0010011";
  end;

  function ADDI (
	 dest, srcreg, immediate : integer)
	 return std_logic_vector is
  begin
	 return ARITH_INSTR(immediate, srcreg, dest, "000");
  end;
  function SB (
	 src, base, offset : integer)
	 return std_logic_vector is
	 variable imm : unsigned(11 downto 0);
  begin
	 imm := to_unsigned(offset, 12);
	 return std_logic_vector(imm(11 downto 5) &to_unsigned(src, 5) &
									 to_unsigned(base, 5)&"000"&imm(4 downto 0)&"0100011");
  end;
  function LB (
	 dest, base, offset : integer)
	 return std_logic_vector is
	 variable imm : unsigned(11 downto 0);
  begin
	 imm := to_unsigned(offset, 12);
	 return std_logic_vector(imm & to_unsigned(base, 5)&"000"&to_unsigned(dest, 5)&"0000011");
  end;

  function BRANCH (
	 src1, src2, offset : integer;
	 func					  : unsigned(2 downto 0))
	 return std_logic_vector is
	 variable imm : unsigned(12 downto 0);
  begin
	 imm := to_unsigned(offset, 13);
	 return std_logic_vector(imm(12)&imm(10 downto 5)&to_unsigned(src2, 5)
									 &to_unsigned(src1, 5)& func &
									 imm(4 downto 1)& imm(11) & "1100011");
  end;
  function BEQ ( src1, src2, offset : integer)
	 return std_logic_vector is
  begin
	 return BRANCH(src1, src2, offset, "000");
  end;
  function BNE ( src1, src2, offset : integer)
	 return std_logic_vector is
  begin
	 return BRANCH(src1, src2, offset, "001");
  end;

  signal memory : memory_type := (
	 ADDI(1, 0, 16#6a#),						 --j
	 SB(1, 0, 10),
	 ADDI(2, 0, 16#6f#),						 --o
	 SB(2, 0, 11),
	 ADDI(3, 0, 16#65#),						 --e
	 SB(3, 0, 12),
	 ADDI(4, 0, 16#6c#),						 --l
	 SB(4, 0, 13),
	 SB(0, 0, 14),								 --\0
	 ADDI(1, 0, 10),
	 LB(2, 1, 0),  							 --instruction 44
	 ADDI(2, 2, -32),
	 SB(2, 1, 10),
	 BNE(2, 0, -12),
	 others => ADDI(0, 0, 0));

  signal instr	  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal next_pc : std_logic_vector(REGISTER_SIZE-1 downto 0);
begin	 -- architecture rtl

  instr_memory : process(clk)
	 variable pc : std_logic_vector(REGISTER_SIZE-1 downto 0);
  begin
	 if clk'event and clk = '1' then
		if pc_corr_en = '1' then
		  instr <= memory(to_integer("00"&unsigned(pc_corr(31 downto 2))));
		else
		  instr <= memory(to_integer("00"&unsigned(program_counter(31 downto 2))));
		end if;
	 end if;
  end process instr_memory;

  pc_logic : component pc_incr
	 generic map (
		REGISTER_SIZE	  => REGISTER_SIZE,
		INSTRUCTION_SIZE => INSTRUCTION_SIZE)
	 port map (
		pc			  => program_counter,
		instr		  => instr,
		pc_corr	  => pc_corr,
		pc_corr_en => pc_corr_en,
		next_pc	  => next_pc);

  output : process (clk, reset) is
  begin	-- process output
	 if reset = '1' then						 -- asynchronous reset (active high)
		program_counter <= (others => '0');
	 elsif clk'event and clk = '1' then	 -- rising clock edge
		instr_out <= instr;
		if pc_corr_en = '1' then
		  pc_out <= pc_corr;
		else
		  pc_out <= program_counter;
		end if;
		next_pc_out <= next_pc;

													 --update program_counter
		program_counter <= next_pc;
	 end if;
  end process output;


end architecture rtl;
