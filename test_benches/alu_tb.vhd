library ieee;
use ieee.std_logic_1164.all;

entity arithmetic_unit_tb is
end entity;

architecture rtl of arithmetic_unit_tb is
  constant REGISTER_SIZE       : integer := 32;
  constant INSTRUCTION_SIZE    : integer := 32;
  constant SIGN_EXTENSION_SIZE : integer := 20;
  component arithmetic_unit is

    generic (
      INSTRUCTION_SIZE    : integer;
      REGISTER_SIZE       : integer;
      SIGN_EXTENSION_SIZE : integer);

    port (
      rs1_data       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      rs2_data       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      instruction    : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      sign_extension : in  std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
      data_out       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_enable    : out std_logic
      );

  end component arithmetic_unit;


  signal rs1_data       : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal rs2_data       : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal instruction    : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
  signal sign_extension : std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
  signal out_data       : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_enable    : std_logic;

  constant ADD_OP  : std_logic_vector(2 downto 0) := "000";
  constant SLL_OP  : std_logic_vector(2 downto 0) := "001";
  constant SLT_OP  : std_logic_vector(2 downto 0) := "010";
  constant SLTU_OP : std_logic_vector(2 downto 0) := "011";
  constant XOR_OP  : std_logic_vector(2 downto 0) := "100";
  constant SR_OP   : std_logic_vector(2 downto 0) := "101";
  constant OR_OP   : std_logic_vector(2 downto 0) := "110";
  constant AND_OP  : std_logic_vector(2 downto 0) := "111";

  constant R_TYPE : std_logic_vector(6 downto 0) := "0110011";
  constant I_TYPE : std_logic_vector(6 downto 0) := "0010011";

begin
  -- instantiate the design-under-test
  dut : component arithmetic_unit
    generic map(REGISTER_SIZE    => REGISTER_SIZE,
                INSTRUCTION_SIZE => INSTRUCTION_SIZE,
                SIGN_EXTENSION_SIZE => SIGN_EXTENSION_SIZE)
    port map(rs1_data       => rs1_data,
             rs2_data       => rs2_data,
             instruction    => instruction,
             sign_extension => sign_extension,
             data_out       => out_data,
             data_enable    => data_enable
             );

  process
  begin


    rs1_data       <= x"0000_0010";
    rs2_data       <= x"0000_0010";
    --               imm   Dontcare       FUN    Dontcare    OPCODE
    instruction    <= x"007" & "00000" & ADD_OP & "00000" & I_TYPE;
    sign_extension <= x"00000";
    wait for 5 ns;
    assert out_data = x"0000_0017" severity failure;

    rs1_data       <= x"0000_0010";
    rs2_data       <= x"0000_0002";
    --               imm   Dontcare       FUN    Dontcare    OPCODE
    instruction    <= x"007" & "00000" & SLL_OP & "00000" & R_TYPE;
    sign_extension <= x"00000";
    wait for 5 ns;
    assert out_data = x"0000_0040" severity failure;

  end process;

end rtl;
