library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
library work;
use work.rv_components.all;
use work.utils.all;

entity memory_system is
  generic (
    REGISTER_SIZE     : natural;
    DUAL_PORTED_INSTR : boolean := true);
  port (
    clk             : in  std_logic;
    instr_addr      : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_addr       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_we         : in  std_logic;
    data_be         : in  std_logic_vector(REGISTER_SIZE/8-1 downto 0);
    data_wdata      : in  std_logic_vector(REGISTER_SIZE - 1 downto 0);
    data_read_en    : in  std_logic;
    instr_read_en   : in  std_logic;
    data_rdata      : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    instr_rdata     : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    instr_wait      : out std_logic;
    data_wait       : out std_logic;
    instr_readvalid : out std_logic;
    data_readvalid  : out std_logic;

    data_av_address       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_av_byteenable    : out std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
    data_av_read          : out std_logic;
    data_av_readdata      : in  std_logic_vector(REGISTER_SIZE-1 downto 0) := (others => 'X');
    data_av_response      : in  std_logic_vector(1 downto 0)               := (others => 'X');
    data_av_write         : out std_logic;
    data_av_writedata     : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_av_lock          : out std_logic;
    data_av_waitrequest   : in  std_logic                                  := '0';
    data_av_readdatavalid : in  std_logic                                  := '0';

    instr_av_address       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    instr_av_byteenable    : out std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
    instr_av_read          : out std_logic;
    instr_av_readdata      : in  std_logic_vector(REGISTER_SIZE-1 downto 0) := (others => 'X');
    instr_av_response      : in  std_logic_vector(1 downto 0)               := (others => 'X');
    instr_av_write         : out std_logic;
    instr_av_writedata     : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    instr_av_lock          : out std_logic;
    instr_av_waitrequest   : in  std_logic                                  := '0';
    instr_av_readdatavalid : in  std_logic                                  := '0');

end memory_system;
architecture avalon of memory_system is
  signal tmp : std_logic;
begin
  data_mm : component avalon_master
    generic map (
      DATA_WIDTH => REGISTER_SIZE,
      ADDR_WIDTH => REGISTER_SIZE)
    port map (
      clk          => clk,
      read_enable  => data_read_en,
      write_enable => data_we,
      byte_enable  => data_be,
      address      => data_addr,
      write_data   => data_wdata,
      read_data    => data_rdata,
      wait_request => data_wait,
      read_valid   => data_readvalid,

      av_address       => data_av_address,
      av_byteenable    => data_av_byteenable,
      av_read          => data_av_read,
      av_readdata      => data_av_readdata,
      av_response      => data_av_response,
      av_write         => data_av_write,
      av_writedata     => data_av_writedata,
      av_lock          => data_av_lock,
      av_waitrequest   => data_av_waitrequest,
      av_readdatavalid => data_av_readdatavalid);

  instr_mm : component avalon_master
    generic map (
      DATA_WIDTH => REGISTER_SIZE,
      ADDR_WIDTH => REGISTER_SIZE)
    port map (
      clk          => clk,
      read_enable  => instr_read_en,
      write_enable => '0',
      byte_enable  => (others => '1'),
      address      => instr_addr,
      write_data   => (others => '0'),
      read_data    => instr_rdata,
      wait_request => instr_wait,
      read_valid   => instr_readvalid,

      av_address       => instr_av_address,
      av_byteenable    => instr_av_byteenable,
      av_read          => instr_av_read,
      av_readdata      => instr_av_readdata,
      av_response      => instr_av_response,
      av_write         => instr_av_write,
      av_writedata     => instr_av_writedata,
      av_lock          => instr_av_lock,
      av_waitrequest   => instr_av_waitrequest,
      av_readdatavalid => instr_av_readdatavalid);


end architecture;
