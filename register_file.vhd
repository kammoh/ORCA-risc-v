library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;


entity register_file is
  generic(
    REGISTER_SIZE      : positive;
    REGISTER_NAME_SIZE : positive
    );
  port(
    clk              : in std_logic;
    stall            : in std_logic;
    valid_input      : in std_logic;
    rs1_sel          : in std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
    rs2_sel          : in std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
    writeback_sel    : in std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
    writeback_data   : in std_logic_vector(REGISTER_SIZE -1 downto 0);
    writeback_enable : in std_logic;

    rs1_data : out std_logic_vector(REGISTER_SIZE -1 downto 0);
    rs2_data : out std_logic_vector(REGISTER_SIZE -1 downto 0)

    );
end;

architecture rtl of register_file is
  type register_list is array(31 downto 0) of std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal registers : register_list := (others => (others => '0'));

  constant ZERO : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) := (others => '0');

  signal we      : std_logic;
  signal re      : std_logic;
  signal out1    : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal out2    : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal outreg1 : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal outreg2 : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal rs1_sel_latched1 : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal rs2_sel_latched1 : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal rs1_sel_latched2 : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal rs2_sel_latched2 : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);


  signal wb_data_latched1 : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal wb_sel_latched1  : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal wb_en_latched1   : std_logic;
  signal wb_data_latched2 : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal wb_sel_latched2  : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal wb_en_latched2   : std_logic;

begin

  we <= writeback_enable;
  re <= not stall;
  register_proc : process (clk) is
  begin
    if rising_edge(clk) then
      if we = '1' then
        registers(to_integer(unsigned(writeback_sel))) <= writeback_data;
      end if;
      if re = '1' then
        out1    <= registers(to_integer(unsigned(rs1_sel)));
        out2    <= registers(to_integer(unsigned(rs2_sel)));
        outreg1 <= out1;
        outreg2 <= out2;
      end if;
    end if;  --rising edge
  end process;

  process(clk) is
  begin
    if rising_edge(clk) then
      if stall = '0' then

        rs1_sel_latched1 <= rs1_sel;
        rs1_sel_latched2 <= rs1_sel_latched1;
        rs2_sel_latched1 <= rs2_sel;
        rs2_sel_latched2 <= rs2_sel_latched1;

      end if;

      wb_data_latched1 <= writeback_data;
      wb_sel_latched1  <= writeback_sel;
      wb_en_latched1   <= writeback_enable;

      wb_data_latched2 <= wb_data_latched1;
      wb_sel_latched2  <= wb_sel_latched1;
      wb_en_latched2   <= wb_en_latched1;

    end if;
  end process;

  --forwarding
  rs1_data <= wb_data_latched1 when rs1_sel_latched2 = wb_sel_latched1 and wb_en_latched1 = '1' else
              wb_data_latched2 when rs1_sel_latched2 = wb_sel_latched2 and wb_en_latched2 = '1' else
              outreg1;

  rs2_data <= wb_data_latched1 when rs2_sel_latched2 = wb_sel_latched1 and wb_en_latched1 = '1' else
              wb_data_latched2 when rs2_sel_latched2 = wb_sel_latched2 and wb_en_latched2 = '1' else
              outreg2;


end architecture;
