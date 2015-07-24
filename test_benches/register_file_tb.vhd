
library ieee;
use ieee.std_logic_1164.all;

entity register_file_tb is
end entity;

architecture rtl of register_file_tb is
  component register_file is
	 generic(
		REGISTER_SIZE		 : positive;
		REGISTER_NAME_SIZE : positive
		);
	 port(
		clk				  : in  std_logic;
		rs1_sel			  : in  std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
		rs2_sel			  : in  std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
		writeback_sel	  : in  std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
		writeback_data	  : in  std_logic_vector(REGISTER_SIZE -1 downto 0);
		writeback_enable : in  std_logic;
		rs1_data			  : out std_logic_vector(REGISTER_SIZE -1 downto 0);
		rs2_data			  : out std_logic_vector(REGISTER_SIZE -1 downto 0)
		);
  end component;

  signal clk				  : std_logic;
  signal rs1_sel			  : std_logic_vector(5 -1 downto 0);
  signal rs2_sel			  : std_logic_vector(5 -1 downto 0);
  signal writeback_sel	  : std_logic_vector(5 -1 downto 0);
  signal writeback_data	  : std_logic_vector(32 -1 downto 0);
  signal writeback_enable : std_logic;
  signal rs1_data			  : std_logic_vector(32 - 1 downto 0);
  signal rs2_data			  : std_logic_vector(32 -1 downto 0);
  signal SW					  : std_logic_vector(7 downto 0);
  signal LEDR				  : std_logic_vector(3 downto 0);
begin
  -- instantiate the design-under-test
  dut : component register_file
	 generic map(REGISTER_SIZE		  => 32,
					 REGISTER_NAME_SIZE => 5)
	 port map(clk					 => clk,
			  rs1_sel			 => rs1_sel,
			  rs2_sel			 => rs2_sel,
			  writeback_sel	 => writeback_sel,
			  writeback_data	 => writeback_data,
			  writeback_enable => writeback_enable,
			  rs1_data			 => rs1_data,
			  rs2_data			 => rs2_data);

  process
  begin

	 clk					<= '0';
	 wait for 5 ns;
	 clk					<= '1';
	 rs1_sel				<= "00000";
	 rs2_sel				<= "00000";
	 writeback_sel		<= "00001";
	 writeback_data	<= x"1111_1111";
	 writeback_enable <= '1';
	 wait for 5 ns;

	 clk					<= '0';
	 wait for 5 ns;
	 clk					<= '1';
	 rs1_sel				<= "00010";
	 rs2_sel				<= "00001";
	 writeback_sel		<= "00010";
	 writeback_data	<= x"2222_2222";
	 writeback_enable <= '1';
	 wait for 5 ns;

	 	 clk					<= '0';
	 wait for 5 ns;
	 clk					<= '1';
	 rs1_sel				<= "00000";
	 rs2_sel				<= "00010";
	 writeback_sel		<= "00000";
	 writeback_data	<= x"3333_3333";
	 writeback_enable <= '1';
	 wait for 5 ns;

  end process;

end rtl;
