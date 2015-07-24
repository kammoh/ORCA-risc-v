library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;
--use IEEE.std_logic_arith.all;

entity branch_unit is


  generic (
	 REGISTER_SIZE			: integer;
	 INSTRUCTION_SIZE		: integer;
	 SIGN_EXTENSION_SIZE : integer);

  port (
	 rs1_data		 : in	 std_logic_vector(REGISTER_SIZE-1 downto 0);
	 rs2_data		 : in	 std_logic_vector(REGISTER_SIZE-1 downto 0);
	 current_pc		 : in	 std_logic_vector(REGISTER_SIZE-1 downto 0);
	 predicted_pc	 : in	 std_logic_vector(REGISTER_SIZE-1 downto 0);
	 instr			 : in	 std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
	 sign_extension : in	 std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
	 --unconditional jumps store return address in rd, output return address
	 -- on data_out lines
	 data_out		 : out std_logic_vector(REGISTER_SIZE-1 downto 0);
	 data_out_en	 : out std_logic;
	 new_pc			 : out std_logic;		 --next pc
	 bad_predict	 : out std_logic_vector(REGISTER_SIZE-1 downto 0)
	 );
end entity branch_unit;

architecture rtl of branch_unit is

  constant OP_IMM_IMMEDIATE_SIZE : integer := 12;

  --op codes
  constant JAL		: unsigned := "1101111";
  constant JALR	: unsigned := "1100111";
  constant BRANCH : unsigned := "1100011";

  --func3
  constant BEQ	 : unsigned := "000";
  constant BNE	 : unsigned := "001";
  constant BLT	 : unsigned := "100";
  constant BGE	 : unsigned := "101";
  constant BLTU : unsigned := "110";
  constant BGEU : unsigned := "111";


begin	 -- architecture rtl

  p1 : process (rs1_data,
					 rs2_data,
					 current_pc,
					 predicted_pc,
					 instr,
					 sign_extension,
					 data_out,
					 data_out_en,
					 new_pc,
					 bad_predict) is
	 variable opcode			: unsigned(6 downto 0);
	 variable imm_val			: unsigned(REGISTER_SIZE-1 downto 0);	--ammount to add
	 variable next_pc			: unsigned(REGISTER_SIZE-1 downto 0);	--instruction after
																						--the current
	 variable calc_pc			: unsigned(REGISTER_SIZE-1 downto 0);
	 variable not_jmp			: std_logic;
	 variable branch_target : unsigned(REGISTER_SIZE-1 downto 0);
  begin	-- process p1

	 data_out_en <= '0';
	 next_pc		 := unsigned(current_pc)+4;
	 opcode		 := unsigned(instr(6 downto 0));

	 not_jmp := '0';
	 calc_pc := next_pc;
	 if opcode = BRANCH then
		imm_val := unsigned(sign_extension(sign_extension_size-1 downto sign_extension_size-12) &
								  instr(31) & instr(7) & instr(30 downto 25) &instr(11 downto 8) & "0");


		branch_target := unsigned(current_pc) + unsigned(imm_val);
		case unsigned(instr(14 downto 12)) is
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

	 elsif opcode = JALR then
		imm_val := unsigned(sign_extension(sign_extension_size-1 downto sign_extension_size-11) &
								  instr(31 downto 21) & "0");
		calc_pc		:= imm_val + unsigned(rs1_data);
		data_out_en <= '1';

	 elsif opcode = JAL then
		imm_val := unsigned(sign_extenstion(sign_extension_size-1 downto sign_extension_size-20) &
								  instr(19 downto 12) & instr(20) & instr(30 downto 21) & "0");
		calc_pc		:= imm_val + pc_current;
		data_out_en <= '1';
	 end if;


	 bad_predict <= '1' when calc_pc /= predicted_pc else '0';
	 new_pc		 <= calc_pc;
	 data_out	 <= next_pc;


  end process p1;

end architecture;
