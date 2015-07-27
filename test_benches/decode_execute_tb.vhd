
library ieee;
use ieee.std_logic_1164.all;
use ieee.NUMERIC_STD.all;
entity decode_execute_tb is
end entity;

architecture rtl of decode_execute_tb is
  constant REGISTER_SIZE		 : integer := 32;
  constant REGISTER_NAME_SIZE	 : integer := 5;
  constant INSTRUCTION_SIZE	 : integer := 32;
  constant SIGN_EXTENSION_SIZE : integer := 20;

  component decode_execute is
	 generic(
		REGISTER_SIZE		 : positive;
		REGISTER_NAME_SIZE : positive;
		INSTRUCTION_SIZE	 : positive);
	 port(
		clk			: in std_logic;
		reset			: in std_logic;
		PC_next		: in std_logic_vector(REGISTER_SIZE-1 downto 0);
		PC_current	: in std_logic_vector(REGISTER_SIZE-1 downto 0);
		instruction : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
		valid_input : in std_logic;
		wb_sel_in	: in std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
		wb_data_in	: in std_logic_vector(REGISTER_SIZE-1 downto 0);
		wb_en_in		: in std_logic;


		wb_sel_out				 : out std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
		wb_data_out				 : out std_logic_vector(REGISTER_SIZE-1 downto 0);
		wb_en_out				 : out std_logic;
		predict_corr			 : out std_logic_vector(REGISTER_SIZE-1 downto 0);
		predict_corr_en		 : out std_logic;
		stall_previous_stages : out std_logic);
  end component;

  signal clk			: std_logic;
  signal reset			: std_logic;
  signal pc_next		: std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal pc_current	: std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal instruction : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
  signal valid_input : std_logic;
  signal wb_sel_in	: std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal wb_data_in	: std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal wb_en_in		: std_logic;

  signal wb_sel_out				 : std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
  signal wb_data_out				 : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal wb_en_out				 : std_logic;
  signal predict_corr			 : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal predict_corr_en		 : std_logic;
  signal stall_previous_stages : std_logic;

  constant OP_IMM : unsigned(6 downto 0) := "0010011";
begin
  -- instantiate the design-under-test
  dut : component decode_execute
	 generic map(REGISTER_SIZE		  => REGISTER_SIZE,
					 REGISTER_NAME_SIZE => REGISTER_NAME_SIZE,
					 INSTRUCTION_SIZE	  => INSTRUCTION_SIZE)

	 port map(clk						  => clk,
				 reset					  => reset,
				 PC_next					  => PC_next,
				 PC_current				  => PC_current,
				 instruction			  => instruction,
				 valid_input			  => valid_input,
				 wb_sel_in				  => wb_sel_in,
				 wb_data_in				  => wb_data_in,
				 wb_en_in				  => wb_en_in,
				 wb_sel_out				  => wb_sel_in,
				 wb_data_out			  => wb_data_in,
				 wb_en_out				  => wb_en_in,
				 predict_corr			  => predict_corr,
				 predict_corr_en		  => predict_corr_en,
				 stall_previous_stages => stall_previous_stages);

  clk_proc : process
  begin
	 clk <= '1';
	 wait for 1 ns;
	 clk <= '0';
	 wait for 1 ns;
  end process;


  main_proc : process(clk)
	 variable state : natural := 1;
  begin

	 --hold in reset for a few cycles
	 if clk'event and clk = '1' then
		case state is
		  when 1 =>
			 reset		 <= '1';
			 PC_next		 <= x"0000_0000";
			 PC_current	 <= x"0000_0000";
			 instruction <= x"0000_0000";
			 valid_input <= '0';
		  when 2 =>
		  -- stay in reset
		  when 3 =>
			 reset		 <= '0';
			 valid_input <= '1';
			 -- ADDI r1,r0,1
			 instruction <= std_logic_vector(to_unsigned(1, 12) & "00000" & "000" & "00001" & OP_IMM);
		  when 4 =>
			 --ADDI r1,r1,1
			 instruction <= std_logic_vector(to_unsigned(1, 12) & "00001" & "000" & "00001" & OP_IMM);
		  when 5 =>
			 --ADDI r2,r1,2
			 instruction <= std_logic_vector(to_unsigned(2, 12) & "00001" & "000" & "00010" & OP_IMM);
		  when 6 =>
 			 --ADDI r3,r1,3
			 instruction <= std_logic_vector(to_unsigned(3, 12) & "00001" & "000" & "00011" & OP_IMM);
		  when 7 =>
 			 --ADDI r1,r1,1
			 instruction <= std_logic_vector(to_unsigned(1, 12) & "00001" & "000" & "00001" & OP_IMM);
		  when others => null;

		end case;
		state := state + 1;
	 end if;


  end process;

end rtl;
