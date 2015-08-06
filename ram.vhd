
-- Quartus II VHDL Template
-- True Dual-Port RAM with single clock
--
-- Read-during-write on port A or B returns newly written data
--
-- Read-during-write between A and B returns either new or old data depending
-- on the order in which the simulator executes the process statements.
-- Quartus II will consider this read-during-write scenario as a
-- don't care condition to optimize the performance of the RAM.  If you
-- need a read-during-write between ports to return the old data, you
-- must instantiate the altsyncram Megafunction directly.

library ieee;
use ieee.std_logic_1164.all;
library work;
use work.components.all;
entity true_dual_port_ram_single_clock is

  generic
    (
      DATA_WIDTH : natural := 8;
      ADDR_WIDTH : natural := 6
      );

  port
    (
      clk          : in  std_logic;
      addr_a       : in  natural range 0 to 2**ADDR_WIDTH - 1;
      addr_b       : in  natural range 0 to 2**ADDR_WIDTH - 1;
      data_a       : in  std_logic_vector((DATA_WIDTH-1) downto 0);
      data_b       : in  std_logic_vector((DATA_WIDTH-1) downto 0);
      we_a         : in  std_logic := '1';
      we_b         : in  std_logic := '1';
      q_a          : out std_logic_vector((DATA_WIDTH -1) downto 0);
      q_b          : out std_logic_vector((DATA_WIDTH -1) downto 0)
      );

end true_dual_port_ram_single_clock;

architecture rtl of true_dual_port_ram_single_clock is

  -- Build a 2-D array type for the RAM
  subtype word_t is std_logic_vector((DATA_WIDTH-1) downto 0);
  type memory_t is array(2**ADDR_WIDTH-1 downto 0) of word_t;

  -- Declare the RAM
  shared variable ram : memory_t;

begin
  -- Port A
  process(clk)
  begin
    if(rising_edge(clk)) then
      if(we_a = '1') then
        ram(addr_a) := data_a;
      end if;
      q_a <= ram(addr_a);
    end if;
  end process;

  -- Port B
  process(clk)
  begin
    if(rising_edge(clk)) then
      if(we_b = '1') then
        ram(addr_b) := data_b;
      end if;
      q_b <= ram(addr_b);
    end if;
  end process;
end rtl;

library ieee;
use ieee.std_logic_1164.all;
library work;
use work.components.all;


entity byte_enabled_true_dual_port_ram is
  generic (
    BYTES      : natural := 4;
    ADDR_WIDTH : natural);
  port (
    clk    : in  std_logic;
    addr1  : in  natural range 0 to 2**ADDR_WIDTH-1;
    addr2  : in  natural range 0 to 2**ADDR_WIDTH-1;
    wdata1 : in  std_logic_vector(BYTES*8-1 downto 0);
    wdata2 : in  std_logic_vector(BYTES*8-1 downto 0);
    we1    : in  std_logic;
    be1    : in  std_logic_vector(BYTES-1 downto 0);
    we2    : in  std_logic;
    be2    : in  std_logic_vector(BYTES-1 downto 0);
    rdata1 : out std_logic_vector(BYTES*8-1 downto 0);
    rdata2 : out std_logic_vector(BYTES*8-1 downto 0));

end entity byte_enabled_true_dual_port_ram;

architecture rtl of byte_enabled_true_dual_port_ram is

  signal byte_enable1 : std_logic_vector(BYTES-1 downto 0);
  signal byte_enable2 : std_logic_vector(BYTES-1 downto 0);
begin  -- architecture rtl
  be_gen : for i in 0 to BYTES-1 generate
    byte_enable1(i) <= be1(i) and we1;
    byte_enable2(i) <= be2(i) and we2;

    bram : component true_dual_port_ram_single_clock
      generic map (
        DATA_WIDTH => 8,
        ADDR_WIDTH => ADDR_WIDTH)
      port map (
        clk    => clk,
        addr_a => addr1,
        addr_b => addr2,
        data_a => wdata1(8*(i+1)-1 downto 8*i),
        data_b => wdata2(8*(i+1)-1 downto 8*i),
        we_a   => byte_enable1(i),
        we_b   => byte_enable2(i),
        q_a    => rdata1(8*(i+1)-1 downto 8*i),
        q_b    => rdata2(8*(i+1)-1 downto 8*i));

  end generate be_gen;

end architecture rtl;
