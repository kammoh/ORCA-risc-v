

-- Quartus II VHDL Template
-- Simple Dual-Port RAM with different read/write addresses and single read/write clock
-- and with a control for writing single bytes into the memory word; byte enable

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.instructions.all;
use work.utils.all;
use work.components.all;

entity memory_system is
  generic (
    REGISTER_SIZE     : natural;
    DUAL_PORTED_INSTR : boolean := true);
  port (
    clk              : in  std_logic;
    instr_addr       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_addr        : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_we          : in  std_logic;
    data_be          : in  std_logic_vector(REGISTER_SIZE/8-1 downto 0);
    data_wdata       : in  std_logic_vector(REGISTER_SIZE - 1 downto 0);
    data_read_en     : in  std_logic;
    instr_read_en    : in  std_logic;
    data_rdata       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    instr_data       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    instr_read_stall : out std_logic;
    data_read_stall  : out std_logic;
    instr_readvalid  : out std_logic;
    data_readvalid   : out std_logic;

    data_av_address       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_av_byteenable    : out std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
    data_av_read          : out std_logic;
    data_av_readdata      : in  std_logic_vector(REGISTER_SIZE-1 downto 0) := (others => 'X');
    data_av_response      : in  std_logic_vector(1 downto 0) := (others => 'X');
    data_av_write         : out std_logic;
    data_av_writedata     : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_av_lock          : out std_logic;
    data_av_waitrequest   : in  std_logic := '0';
    data_av_readdatavalid : in  std_logic := '0');
end memory_system;

architecture rtl of memory_system is


  constant RESET_ROM_START : natural := 0;
  constant RESET_ROM_SIZE  : natural := 4*1024;

  constant BRAM_START : natural := 16#10000#;
  constant BRAM_SIZE  : natural := 1*1024;


  function word_address (
    byte_address : std_logic_vector;
    length       : natural)
    return integer is
    constant shift : natural := log2(REGISTER_SIZE/8);
  begin
    return to_integer(unsigned(byte_address(length+shift-1 downto shift)));
  end function;



  signal reset_rom_instr_addr : integer range 0 to RESET_ROM_SIZE -1;
  signal reset_rom_data_addr  : integer range 0 to RESET_ROM_SIZE -1;
  signal reset_rom_instr_re   : std_logic;
  signal reset_rom_data_re    : std_logic;

  signal reset_rom_instr_out        : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal reset_rom_data_out         : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal reset_rom_instr_read_stall : std_logic;
  signal reset_rom_data_read_stall  : std_logic;
  signal reset_rom_instr_readvalid  : std_logic;
  signal reset_rom_data_readvalid   : std_logic;

  signal bram_instr_addr : integer range 0 to RESET_ROM_SIZE -1;
  signal bram_data_addr  : integer range 0 to RESET_ROM_SIZE -1;
  --signal bram_instr_re   : std_logic;
  --signal bram_data_re    : std_logic;
  signal bram_data_we    : std_logic;

  signal bram_instr_out        : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal bram_data_out         : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal bram_instr_read_stall : std_logic;
  signal bram_data_read_stall  : std_logic;
  signal bram_instr_readvalid  : std_logic;
  signal bram_data_readvalid   : std_logic;


  signal latched_instr_choice : std_logic_vector(1 downto 0);
  signal latched_data_choice  : std_logic_vector(1 downto 0);

  constant ROM_CHOICE      : std_logic_vector(1 downto 0) := "01";
  constant BRAM_CHOICE     : std_logic_vector(1 downto 0) := "10";
  constant EXTERNAL_CHOICE : std_logic_vector(1 downto 0) := (others => '0');

  signal instr_choice : std_logic_vector(1 downto 0);
  signal data_choice  : std_logic_vector(1 downto 0);


begin  -- rtl


  --which memory object does the data address refer to?
  with to_integer(unsigned(data_addr)) select
    data_choice <=
    BRAM_CHOICE     when BRAM_START to BRAM_START+BRAM_SIZE-1,
    ROM_CHOICE      when RESET_ROM_START to RESET_ROM_START+RESET_ROM_SIZE,
    EXTERNAL_CHOICE when others;

  --which memory object does the instr address refer to?
  with to_integer(unsigned(instr_addr)) select
    instr_choice <=
    BRAM_CHOICE     when BRAM_START to BRAM_START+BRAM_SIZE-1,
    ROM_CHOICE      when RESET_ROM_START to RESET_ROM_START+RESET_ROM_SIZE,
    EXTERNAL_CHOICE when others;

  reset_rom_instr_addr <= word_address(instr_addr, log2(RESET_ROM_SIZE));
  reset_rom_data_addr  <= word_address(data_addr,  log2(RESET_ROM_SIZE));
  reset_rom_instr_re   <= '1' when instr_read_en = '1' and instr_choice = ROM_CHOICE else '0';
  reset_rom_data_re    <= '1' when data_read_en = '1' and data_choice = ROM_CHOICE else '0';

  reset_rom : component instruction_rom
    generic map (
      REGISTER_SIZE => REGISTER_SIZE,
      ROM_SIZE      => RESET_ROM_SIZE,
      PORTS         => 1)
    port map (
      clk        => clk,
      instr_addr => reset_rom_instr_addr,
      data_addr  => reset_rom_data_addr,
      instr_re   => reset_rom_instr_re,
      data_re    => reset_rom_data_re,

      instr_out        => reset_rom_instr_out,
      data_out         => reset_rom_data_out,
      instr_read_stall => reset_rom_instr_read_stall,
      data_read_stall  => reset_rom_data_read_stall,
      instr_readvalid  => reset_rom_instr_readvalid,
      data_readvalid   => reset_rom_data_readvalid);

  --get output from dualport block_ram
  bram_data_we    <= '1' when data_choice = BRAM_CHOICE and data_we = '1' else '0';
  bram_instr_addr <= word_address(instr_addr, log2(BRAM_SIZE));
  bram_data_addr  <= word_address(data_addr, log2(BRAM_SIZE));

  bram : component byte_enabled_true_dual_port_ram
    generic map (
      ADDR_WIDTH => log2(BRAM_SIZE),
      BYTES      => REGISTER_SIZE/8)
    port map (
      clk    => clk,
      we1    => '0',
      we2    => bram_data_we,
      be1    => (others => '0'),
      be2    => data_be,
      wdata1 => (others => '0'),
      wdata2 => data_wdata,
      addr1  => bram_instr_addr,
      addr2  => bram_data_addr,
      rdata1 => bram_instr_out,
      rdata2 => bram_data_out);

  bram_instr_read_stall <= '0';
  bram_data_read_stall  <= '0';
  bram_data_readvalid   <= '1';
  bram_instr_readvalid  <= '1';


  --get output from external avalon bus
  --data_exdata_re <= '1' when data_choice = EXTERNAL_CHOICE and data_re = '1' else '0';
  --data_exdata_we <= '1' when data_choice = EXTERNAL_CHOICE and data_we = '1' else '0';

  --extern_data_mm : component avalon_master
  --  generic map (
  --    DATA_WIDTH => REGISTER_SIZE,
  --    ADDR_WIDTH => REGISTER_SIZE)
  --  port map (
  --    read_enable  => data_exdata_re,
  --    write_enable => data_exdata_we,
  --    byte_enable  => data_be,
  --    address      => data_addr,
  --    write_data   => data_wdata,
  --    read_data    => exdata_read_data,
  --    xfer_in_prog => exdata_stall,

  --    av_address       => data_av_address,
  --    av_byteenable    => data_av_byteenable,
  --    av_read          => data_av_read,
  --    av_readdata      => data_av_readdata,
  --    av_response      => data_av_response,
  --    av_write         => data_av_write,
  --    av_writedata     => data_av_writedata,
  --    av_lock          => data_av_lock,
  --    av_waitrequest   => data_av_waitrequest,
  --    av_readdatavalid => data_av_readdatavalid);




  latched_inputs : process (clk)
  begin
    if rising_edge(clk) then
      latched_instr_choice <= instr_choice;
      latched_data_choice  <= data_choice;
    end if;
  end process;





  --coalesce output signals
  with latched_instr_choice select
    instr_data <=
    bram_instr_out      when BRAM_CHOICE,
    reset_rom_instr_out when ROM_CHOICE,
    (others => 'X')     when others;

  with latched_data_choice select
    data_rdata <=
    bram_data_out      when BRAM_CHOICE,
    reset_rom_data_out when ROM_CHOICE,
    (others => 'X')    when others;

  with latched_data_choice select
    data_readvalid <=
    bram_data_readvalid      when BRAM_CHOICE,
    reset_rom_data_readvalid when ROM_CHOICE,
    '0'                      when others;

  with latched_instr_choice select
    instr_readvalid <=
    bram_instr_readvalid      when BRAM_CHOICE,
    reset_rom_instr_readvalid when ROM_CHOICE,
    '0'                       when others;

  with latched_data_choice select
    data_read_stall <=
    bram_data_read_stall      when BRAM_CHOICE,
    reset_rom_data_read_stall when ROM_CHOICE,
    '0'                       when others;

  with latched_instr_choice select
    instr_read_stall <=
    bram_instr_read_stall      when BRAM_CHOICE,
    reset_rom_instr_read_stall when ROM_CHOICE,
    '0'                        when others;


end architecture;
