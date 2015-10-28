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

    rs1_data : buffer std_logic_vector(REGISTER_SIZE -1 downto 0);
    rs2_data : buffer std_logic_vector(REGISTER_SIZE -1 downto 0)

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

  signal rs1_sel_latched : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal rs2_sel_latched : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);

  signal read_during_write1 : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal read_during_write2 : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal wb_fwd_data1 : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal wb_fwd_data2 : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal wb_data_latched : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal wb_sel_latched  : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal wb_en_latched   : std_logic;

begin

  we <= writeback_enable;
  re <= not stall;
  register_proc : process (clk) is
    variable read1 : std_logic_vector(REGISTER_SIZE-1 downto 0);
    variable read2 : std_logic_vector(REGISTER_SIZE-1 downto 0);
  begin
    if rising_edge(clk) then
      if we = '1' then
        registers(to_integer(unsigned(writeback_sel))) <= writeback_data;
      end if;
      out1 <= registers(to_integer(unsigned(rs1_sel)));
      out2 <= registers(to_integer(unsigned(rs2_sel)));
    end if;  --rising edge
  end process;

  read_during_write1 <= wb_data_latched when wb_en_latched = '1' and wb_sel_latched = rs1_sel_latched   else out1;
  wb_fwd_data1       <= writeback_data  when writeback_sel = rs1_sel_latched and writeback_enable = '1' else read_during_write1;

  read_during_write2 <= wb_data_latched when wb_en_latched = '1' and wb_sel_latched = rs2_sel_latched   else out2;
  wb_fwd_data2       <= writeback_data  when writeback_sel = rs2_sel_latched and writeback_enable = '1' else read_during_write2;

  process(clk) is
  begin
    if rising_edge(clk) then
      if stall = '0' then
        outreg1 <= wb_fwd_data1;
        outreg2 <= wb_fwd_data2;

      end if;

      rs1_sel_latched <= rs1_sel;
      rs2_sel_latched <= rs2_sel;

      wb_data_latched <= writeback_data;
      wb_sel_latched  <= writeback_sel;
      wb_en_latched   <= writeback_enable;

    end if;
  end process;


  rs1_data <= outreg1;
  rs2_data <= outreg2;


end architecture;
