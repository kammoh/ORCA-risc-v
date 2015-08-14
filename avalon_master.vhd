library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.utils.all;

entity avalon_master is
  generic (
    DATA_WIDTH : natural;
    ADDR_WIDTH : natural);
  port (
    clk : in std_logic;

    --CPU signals
    read_enable  : in  std_logic;
    write_enable : in  std_logic;
    byte_enable  : in  std_logic_vector(DATA_WIDTH/8 -1 downto 0);
    address      : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    write_data   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    read_data    : out std_logic_vector(DATA_WIDTH-1 downto 0);
    wait_request : out std_logic;
    read_valid   : out std_logic;


    --avalon bus signals
    av_address       : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    av_byteenable    : out std_logic_vector(DATA_WIDTH/8 -1 downto 0);
    av_read          : out std_logic;
    av_readdata      : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    av_response      : in  std_logic_vector(1 downto 0);
    av_write         : out std_logic;
    av_writedata     : out std_logic_vector(DATA_WIDTH-1 downto 0);
    av_lock          : out std_logic;
    av_waitrequest   : in  std_logic;
    av_readdatavalid : in  std_logic);
end entity avalon_master;

architecture rtl of avalon_master is
  constant WORD_SIZE : natural := log2(DATA_WIDTH/8);

begin  -- architecture rtl

  av_address <= std_logic_vector(shift_right(unsigned(address),WORD_SIZE));
  av_byteenable <= byte_enable;
  av_read      <= read_enable;
  read_data    <= av_readdata;
  --av_response
  av_write     <= write_enable;
  av_writedata <= write_data;
  av_lock      <= '0';
  wait_request <= av_waitrequest;
  read_valid   <= av_readdatavalid;

end architecture rtl;
