library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;
--use IEEE.std_logic_arith.all;

entity arithmetic_unit is

  generic (
	 INSTRUCTION_SIZE		: integer;
	 REGISTER_SIZE			: integer;
	 SIGN_EXTENSION_SIZE : integer);

  port (
	 rs1_data		 : in	 std_logic_vector(REGISTER_SIZE-1 downto 0);
	 rs2_data		 : in	 std_logic_vector(REGISTER_SIZE-1 downto 0);
	 instruction	 : in	 std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
	 sign_extension : in	 std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
	 data_out		 : out std_logic_vector(REGISTER_SIZE-1 downto 0);
	 data_enable	 : out std_logic
	 );

end entity arithmetic_unit;

architecture rtl of arithmetic_unit is
  constant ADD_OP	 : std_logic_vector(2 downto 0) := "000";
  constant SLL_OP	 : std_logic_vector(2 downto 0) := "001";
  constant SLT_OP	 : std_logic_vector(2 downto 0) := "010";
  constant SLTU_OP : std_logic_vector(2 downto 0) := "011";
  constant XOR_OP	 : std_logic_vector(2 downto 0) := "100";
  constant SR_OP	 : std_logic_vector(2 downto 0) := "101";
  constant OR_OP	 : std_logic_vector(2 downto 0) := "110";
  constant AND_OP	 : std_logic_vector(2 downto 0) := "111";

  constant OP_IMM_IMMEDIATE_SIZE : integer := 12;

begin	 -- architecture rtl



  p1:process(rs1_data, rs2_data, instruction, sign_extension) is
	 variable func					: std_logic_vector(2 downto 0);
	 variable is_immediate		: std_logic;
	 variable data1				: unsigned(REGISTER_SIZE-1 downto 0);
	 variable data2				: unsigned(REGISTER_SIZE-1 downto 0);
	 variable data_result		: unsigned(REGISTER_SIZE-1 downto 0);
	 variable arithmetic_shift : std_logic;
	 variable subtract			: std_logic;


	 variable pretrunc_imm :
		std_logic_vector(sign_extension_size + OP_IMM_IMMEDIATE_SIZE-1 downto 0);
  begin
	 is_immediate := not instruction(5);
	 data1		  := unsigned(rs1_data);
	 data2		  := unsigned(rs2_data);
	 pretrunc_imm := sign_extension & instruction(31 downto 20);
	 func			  := instruction(14 downto 12);

	 arithmetic_shift := instruction(30);
	 subtract			:= not instruction(30);

	 if is_immediate = '1' then
		data2		:= unsigned(pretrunc_imm(31 downto 0));
		subtract := '0';						 --never do subtract on immediate
	 end if;

	 case func is
		when ADD_OP =>
		  if sub = '1' then
			 data_result := data1 - data2;
		  else
			 data_result := data1 + data2;
		  end if;
		when SLL_OP =>
		  data_result := SHIFT_LEFT(data1, to_integer(data2(5 downto 0)));
		when SLT_OP =>
		  if data1 < data1 then
			 data_result := to_unsigned(1, REGISTER_SIZE);
		  else
			 data_result := to_unsigned(0, REGISTER_SIZE);
		  end if;
		when SLTU_OP =>
		  if data1 < data1 then
			 data_result := to_unsigned(1, REGISTER_SIZE);
		  else
			 data_result := to_unsigned(0, REGISTER_SIZE);
		  end if;
		when XOR_OP =>
		  data_result := data1 xor data2;
		when SR_OP =>
		  if arithmetic_shift = '1' then
			 data_result := unsigned(SHIFT_RIGHT(signed(data1),
														 to_integer(unsigned(data2(5 downto 0)))
														 ));
		  else
			 data_result := SHIFT_RIGHT(data1,
											 to_integer(unsigned(data2(5 downto 0))
															));
		  end if;
		when OR_OP =>
		  data_result := data1 or data2;
		when AND_OP =>
		  data_result := data1 and data2;
		when others => null;
	 end case;

	 case instruction(6 downto 0) is
		when "0010011" => data_enable <= '1';
		when "0110011" => data_enable <= '1';
		when others		=> data_enable <= '0';
	 end case;
	 data_out <= std_logic_vector(data_result);
  end process;
end architecture;
