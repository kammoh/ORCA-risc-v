library ieee;
use ieee.std_logic_1164.all;
library work;
use work.components.all;


-- this is a wrapper around byte_enabled_true_dual_port_ram,
-- adds artificial waiting to test stall logic during load_store
entity wait_cycle_bram is

  generic (
    BYTES       : natural;
    ADDR_WIDTH  : natural;
    WAIT_STATES : natural);

  port (
    clk    : in std_logic;
    addr1  : in natural range 0 to 2**ADDR_WIDTH-1;
    addr2  : in natural range 0 to 2**ADDR_WIDTH-1;
    wdata1 : in std_logic_vector(BYTES*8-1 downto 0);
    wdata2 : in std_logic_vector(BYTES*8-1 downto 0);
    re1    : in std_logic;
    re2    : in std_logic;
    we1    : in std_logic;
    be1    : in std_logic_vector(BYTES-1 downto 0);
    we2    : in std_logic;
    be2    : in std_logic_vector(BYTES-1 downto 0);

    rdata1     : out std_logic_vector(BYTES*8-1 downto 0);
    rdata2     : out std_logic_vector(BYTES*8-1 downto 0);
    stalled1   : out std_logic;
    stalled2   : out std_logic;
    readvalid1 : out std_logic;
    readvalid2 : out std_logic);

end entity wait_cycle_bram;

architecture rtl of wait_cycle_bram is
  signal port1_count : natural;
  signal port2_count : natural;

  signal rdata1_int : std_logic_vector(BYTES*8-1 downto 0);
  signal rdata2_int : std_logic_vector(BYTES*8-1 downto 0);
  signal we1_int    : std_logic;
  signal we2_int    : std_logic;

begin  -- architecture rtl


  wait_state_gen : if WAIT_STATES /= 0 generate
    process(clk)
    begin
      if rising_edge(clk) then
        if (re1 = '1') and port1_count /= 0 then
          port1_count <= port1_count -1;
        else
          port1_count <= WAIT_STATES;
        end if;

        if (re2 = '1') and port2_count /= 0 then
          port2_count <= port2_count -1;
        else
          port2_count <= WAIT_STATES;
        end if;
      end if;
    end process;
  end generate wait_state_gen;
  zero_gen : if WAIT_STATES = 0 generate
    port2_count <= 0;
    port1_count <= 0;
  end generate zero_gen;

  ram : component byte_enabled_true_dual_port_ram
    generic map(
      BYTES      => BYTES,
      ADDR_WIDTH => ADDR_WIDTH)
    port map (
      clk    => clk,
      addr1  => addr1,
      addr2  => addr2,
      wdata1 => wdata1,
      wdata2 => wdata2,
      we1    => we1_int,
      be1    => be1,
      we2    => we2_int,
      be2    => be2,
      rdata1 => rdata1_int,
      rdata2 => rdata2_int);

  we1_int <= we1;
  we2_int <= we2;
  rdata1  <= rdata1_int when port1_count = 0 else (others => 'X');
  rdata2  <= rdata2_int when port2_count = 0 else (others => 'X');

  --stalled unless available or will be available next cycle
  stalled1 <= '0' when (port1_count = 1 or port1_count = 0) else re1;
  stalled2 <= '0' when (port2_count = 1 or port2_count = 0) else re2;


  readvalid1 <= '0' when port1_count /= 0 else '1';
  readvalid2 <= '0' when port2_count /= 0 else '1';

end architecture rtl;
