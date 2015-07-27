library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;


entity register_file is
  generic(
	 REGISTER_SIZE		  : positive;
	 REGISTER_NAME_SIZE : positive
	 );
  port(
	 clk					: in	std_logic;
	 rs1_sel				: in	std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
	 rs2_sel				: in	std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
	 writeback_sel		: in	std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
	 writeback_data	: in	std_logic_vector(REGISTER_SIZE -1 downto 0);
	 writeback_enable : in	std_logic;
	 rs1_data			: out std_logic_vector(REGISTER_SIZE -1 downto 0);
	 rs2_data			: out std_logic_vector(REGISTER_SIZE -1 downto 0)
	 );
end;

architecture rtl of register_file is
  type register_list is array(31 downto 0) of std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal registers : register_list;
begin
  register_proc : process (clk) is
  begin
	 if falling_edge(clk) then

													 --read before bypass
		rs1_data <= registers(to_integer(unsigned(rs1_sel)));
		rs2_data <= registers(to_integer(unsigned(rs2_sel)));
		if writeback_enable = '1' and
		  writeback_sel /= std_logic_vector(to_unsigned(0,REGISTER_NAME_SIZE)) then

		  registers(to_integer(unsigned(writeback_sel))) <= writeback_data;
		  if rs1_sel = writeback_sel then
			 rs1_data <= writeback_data;
		  end if;
		  if rs2_sel = writeback_sel then
			 rs2_data <= writeback_data;
		  end if;
		end if;
		registers(0) <=std_logic_vector(to_unsigned(0,REGISTER_SIZE));
	 end if;
  end process;
end architecture;
