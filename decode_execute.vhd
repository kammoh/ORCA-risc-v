library IEEE;
use IEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity decode_execute is
	generic(
		REGISTER_SIZE		 : positive;
		REGISTER_NAME_SIZE : positive;
		INSTRUCTION_SIZE	 : positive;
		)
		port(
			clk				  : in std_logic;
			PC_next			  : in std_logic_vector(REGISTER_SIZE-1 downto 0);
			PC__current		  : in std_logic_vector(REGISTER_SIZE-1 downto 0);
			instruction		  : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
			writeback_reg	  : in std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
			writeback_data	  : in std_logic_vector(REGISTER_SIZE-1 downto 0);
			writeback_enable : in std_logic;
			valid				  : in std_logic;
			);
end;

architecture behavioural of decode_execute is
	alias rd std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) is
		instruction(11 downto 6);
	alias rs1 std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) is
		instruction(19 downto 15);
	alias rs2 std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) is
		instruction(24 downto 20);

	alias opcode std_logic_vector(6 downto 0) is
		instruction(6 downto 0);
	type instr_type_t is (R, I, S, U, J);

	constant shortest_immediate integer	  := 12;
	constant sign_extenstion_size integer := REGISTER_SIZE -INSTRUCTION_SIZE + (REGISTER_SIZE -SHORTEST_IMMEDIATE);
	signal sign_extension std_logic_vector(SIGN_EXTENSTION_SIZE-1 downto 0);

	component register_file
		generic(
			REGISTER_SIZE		 : positive;
			REGISTER_NAME_SIZE : positive;
			);
		port(
			clk				  : in  std_logic;
			rs1_sel			  : in  std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
			rs2_sel			  : in  std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
			writeback_sel	  : in  std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
			writeback_data	  : in  std_logic_vector(REGISTER_SIZE -1 downto 0);
			writeback_enable : in  std_logic;
			rs1_data			  : out std_logic_vector(REGISTER_SIZE -1 downto 0);
			rs2_data			  : out std_logic_vector(REGISTER_SIZE -1 downto 0);
			);
	end component;
	component arithmetic_unit is
		generic (
			INSTRUCTION_SIZE	  : integer;
			REGISTER_SIZE		  : integer;
			SIGN_EXTENSION_SIZE : integer := 20);

		port (
			rs1_data			: in	std_logic_vector(REGISTER_SIZE-1 downto 0);
			rs2_data			: in	std_logic_vector(REGISTER_SIZE-1 downto 0);
			instruction		: in	std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
			sign_extension : in	std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
			data_out			: out std_logic_vector(REGISTER_SIZE-1 downto 0);
			data_enable		: out std_logic
			);
	end component arithmetic_unit;
begin
	register_file_1 : component register_file
		generic map (
			REGISTER_SIZE		 => REGISTER_SIZE,
			REGISTER_NAME_SIZE => REGISTER_NAME_SIZE);
	port map(
		clk				  => clk,
		rs1_sel			  => rs1,
		rs2_sel			  => rs1,
		writeback_sel	  => writeback_reg,
		writeback_data	  => writeback_data,
		writeback_enable => writeback_enable,
		rs1_data			  => rs1_data,
		rs2_data			  => rs2_data,
		);

	 for I in 0 to sign_extension'length generate
			sign_extension(i) <= instruction'left;
	 end generate;


	alu : component arithmetic_unit is
		generic map (
		  INSTRUCTION_SIZE	  => INSTRUCTION_SIZE,
		  REGISTER_SIZE		  => REGISTER_SIZE,
		  SIGN_EXTENSTION_SIZE => sign_extenstion_size)
		port map (
		  rs1_data		  => rs1_data,
		  rs2_data		  => rs2_data,
		  instruction	  => instruction,
		  sign_extension => sign_instruction,
		  data_out		  => alu_data_out,
		  date_enable	  => alu_data_enable);



	instruction_type_decode : process(instruction) is
		variable opcode std_logic_vector(6 downto 0);
		variable i_t instr_type_t;
		variable
																	--extension needed
	begin
		opcode := instruction(6 downto 0);
		case opcode is
			when b"0010011" => i_t := I;					--OP_IMM
			when b"0110111" => i_t := U;					--LUI
			when b"0010111" => i_t := U;					--AUIPC
			when b"1101111" => i_t := J;					--JAL
			when b"1100111" => i_t := I;					--JALR
			when b"1100011" => i_t := B;					--BRANCH
			when b"0000011" => i_t := I;					--LOAD
			when b"0100011" => i_t := S;					--STORE
									 when others i_t := R;	--LOAD
		end case;

		for I in 0 to 19 loop
			sign_ext(i) := instruction'left;
		end loop;

		case i_t is
			when I =>
				immediate_value <= sign_ext & instruction(30 downto 20);
			when S =>
				immediate_value <= sign_ext & instruction(30 downto 25) & instruction(11 downto 7);
			when B =>
				immediate_value <= sign_ext(18 downto 0) & instruction(7 downto 7) &
										 instruction(30 downto 25) & instruction(11 downto 8) & b"0";
			when U =>
				immediate_value <= instruction(31 downto 12) & b"0000_0000_0000";
			when J =>
				immediate_value <= sign_ext(11 downto 0) & instruction(19 downto 12) &
										 instruction(20 downto 20) & instruction(30 downto 21) & b"0";
				others => immmediate_value <= x"0000_0000";
		end case;

		instruction_type <= i_t;

	end process



end architecture;
