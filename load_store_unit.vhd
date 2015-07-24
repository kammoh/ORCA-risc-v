library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;
--use IEEE.std_logic_arith.all;

entity load_store_unit is


  generic (
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
end entity load_store_unit; is

architecture rtl of load_store_unit is

  constant OP_IMM_IMMEDIATE_SIZE : integer := 12;

begin	 -- architecture rtl



end architecture;
