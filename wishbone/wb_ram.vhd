library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.utils.all;

entity wb_ram is

  generic (
    size             : integer := 4096;
    DATA_WIDTH       : integer := 32;
    INIT_FILE_FORMAT : string  := "hex";
    INIT_FILE_NAME   : string  := "none";
    LATTICE_FAMILY   : string  := "ICE40");
  port (
    CLK_I : in std_logic;
    RST_I : in std_logic;

    ADR_I : in std_logic_vector(31 downto 0);
    DAT_I : in std_logic_vector(DATA_WIDTH-1 downto 0);
    WE_I  : in std_logic;
    CYC_I : in std_logic;
    STB_I : in std_logic;
    SEL_I : in std_logic_vector(DATA_WIDTH/8-1 downto 0);
    CTI_I : in std_logic_vector(2 downto 0);
    BTE_I : in std_logic_vector(1 downto 0);

    LOCK_I : in std_logic;

    STALL_O : out std_logic;
    DAT_O   : out std_logic_vector(DATA_WIDTH-1 downto 0);
    ACK_O   : out std_logic;
    ERR_O   : out std_logic;
    RTY_O   : out std_logic);

end entity wb_ram;

architecture rtl of wb_ram is
  component pmi_ram_dp_be is
    generic (
      pmi_wr_addr_depth    : integer := 512;
      pmi_wr_addr_width    : integer := 9;
      pmi_wr_data_width    : integer := 18;
      pmi_rd_addr_depth    : integer := 512;
      pmi_rd_addr_width    : integer := 9;
      pmi_rd_data_width    : integer := 18;
      pmi_regmode          : string  := "reg";
      pmi_gsr              : string  := "disable";
      pmi_resetmode        : string  := "sync";
      pmi_optimization     : string  := "speed";
      pmi_init_file        : string  := "none";
      pmi_init_file_format : string  := "binary";
      pmi_byte_size        : integer := 9;
      pmi_family           : string  := "ECP2";
      module_type          : string  := "pmi_ram_dp_be"
      );
    port (
      Data      : in  std_logic_vector(pmi_wr_data_width-1 downto 0);
      WrAddress : in  std_logic_vector(pmi_wr_addr_width-1 downto 0);
      RdAddress : in  std_logic_vector(pmi_rd_addr_width-1 downto 0);
      WrClock   : in  std_logic;
      RdClock   : in  std_logic;
      WrClockEn : in  std_logic;
      RdClockEn : in  std_logic;
      WE        : in  std_logic;
      Reset     : in  std_logic;
      ByteEn    : in  std_logic_vector(((pmi_wr_data_width+pmi_byte_size-1)/pmi_byte_size-1) downto 0);
      Q         : out std_logic_vector(pmi_rd_data_width-1 downto 0)
      );
  end component pmi_ram_dp_be;

  constant BYTES_PER_WORD : integer := DATA_WIDTH/8;

  signal address : std_logic_vector(log2(SIZE/BYTES_PER_WORD)-1 downto 0);
begin  -- architecture rtl

  address <= ADR_I(address'left+log2(BYTES_PER_WORD) downto log2(BYTES_PER_WORD));

  ram : component pmi_ram_dp_be
    generic map(
      pmi_wr_addr_depth    => SIZE/BYTES_PER_WORD,
      pmi_wr_addr_width    => log2(SIZE/BYTES_PER_WORD),
      pmi_wr_data_width    => DATA_WIDTH,
      pmi_rd_addr_depth    => SIZE/BYTES_PER_WORD,
      pmi_rd_addr_width    => log2(SIZE/BYTES_PER_WORD),
      pmi_rd_data_width    => DATA_WIDTH,
      pmi_regmode          => "noreg",
      pmi_byte_size        => 8,
      pmi_gsr              => "disable",
      pmi_init_file        => INIT_FILE_NAME,
      pmi_init_file_format => INIT_FILE_FORMAT,
      pmi_family           => LATTICE_FAMILY)
    port map (
      Data      => DAT_I,
      WrAddress => address,
      RdAddress => address,
      WrClock   => CLK_I,
      RdClock   => CLK_I,
      WrClockEN => '1',
      RdClockEN => '1',
      WE        => WE_I,
      ByteEn    => SEL_I,
      Reset     => RST_I,
      Q         => DAT_O);

  STALL_O <= '0';
  ERR_O   <= '0';
  RTY_O   <= '0';

  process(CLK_I)
  begin
    if rising_edge(CLK_I) then
      ACK_O <= STB_I and CYC_I;
    end if;
  end process;




end architecture rtl;
