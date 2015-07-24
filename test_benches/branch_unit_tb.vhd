library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;
entity branch_unit_tb is
end entity;

architecture rtl of branch_unit_tb is
  constant REGISTER_SIZE       : integer := 32;
  constant INSTRUCTION_SIZE    : integer := 32;
  constant SIGN_EXTENSION_SIZE : integer := 20;
  component branch_unit is
    generic (
      REGISTER_SIZE       : integer;
      INSTRUCTION_SIZE    : integer;
      SIGN_EXTENSION_SIZE : integer);

    port (
      rs1_data       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      rs2_data       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      current_pc     : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      predicted_pc   : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      instr          : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      sign_extension : in  std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
      --unconditional jumps store return address in rd, output return address
      -- on data_out lines
      data_out       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_out_en    : out std_logic;
      new_pc         : out std_logic_vector(REGISTER_SIZE-1 downto 0);  --next pc
      bad_predict    : out std_logic
      );

  end component branch_unit;


  signal rs1_data       : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal rs2_data       : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal current_pc     : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal predicted_pc   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal instr          : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
  signal sign_extension : std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
  signal data_out       : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_out_en    : std_logic;
  signal new_pc         : std_logic_vector(REGISTER_SIZE-1 downto 0);  --next pc
  signal bad_predict    : std_logic;

  --op codes
  constant JAL    : unsigned := "1101111";
  constant JALR   : unsigned := "1100111";
  constant BRANCH : unsigned := "1100011";

  --func3
  constant BEQ  : unsigned := "000";
  constant BNE  : unsigned := "001";
  constant BLT  : unsigned := "100";
  constant BGE  : unsigned := "101";
  constant BLTU : unsigned := "110";
  constant BGEU : unsigned := "111";

begin
  -- instantiate the design-under-test
  dut : component branch_unit
    generic map(REGISTER_SIZE       => REGISTER_SIZE,
                INSTRUCTION_SIZE    => INSTRUCTION_SIZE,
                SIGN_EXTENSION_SIZE => SIGN_EXTENSION_SIZE)
    port map(rs1_data       => rs1_data,
             rs2_data       => rs2_data,
             current_pc     => current_pc,
             predicted_pc   => predicted_pc,
             instr          => instr,
             sign_extension => sign_extension,
             data_out       => data_out,
             data_out_en    => data_out_en,
             new_pc         => new_pc,
             bad_predict    => bad_predict);

  process
    variable imm : unsigned(31 downto 0);
  begin


    rs1_data <= x"0000_0010";
    rs2_data <= x"0000_0010";
    imm      := unsigned(to_signed(-8, 32));

    instr <= std_logic_vector(imm(12) & imm(10 downto 5) & "0000000000" & BEQ & imm(4 downto 1)& imm(11) & BRANCH);

    sign_extension <= std_logic_vector(imm(imm'length-1 downto 12));
    current_pc     <= std_logic_vector(to_unsigned(8, REGISTER_SIZE));
    predicted_pc   <= std_logic_vector(to_unsigned(8+4, REGISTER_SIZE));
    wait for 5 ns;

    imm            := to_unsigned(5, 32);
    sign_extension <= std_logic_vector(imm(imm'length-1 downto 12));
    instr          <= std_logic_vector(imm(11 downto 0) &"00000"&"000"&"00001"&JALR);
    wait for 5 ns;

    imm            := to_unsigned(16#320#, 32);
    sign_extension <= std_logic_vector(imm(imm'length-1 downto 12));
    instr          <= std_logic_vector(imm(20)&imm(10 downto 1)&imm(11)&imm(19 downto 12) &"00001"&JAL);
    wait for 5 ns;


  end process;

end rtl;
