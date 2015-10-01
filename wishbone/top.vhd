
library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity top is
  port(
    clk   : in std_logic;
    reset : in std_logic);
end entity;

architecture rtl of top is

  component riscV_wishbone is
    generic (
      REGISTER_SIZE : integer := 32;
      RESET_VECTOR  : natural := 16#00000200#);
    port(
      clk   : in std_logic;
      reset : in std_logic;

      --conduit end point
      coe_to_host         : out std_logic_vector(REGISTER_SIZE -1 downto 0);
      coe_from_host       : in  std_logic_vector(REGISTER_SIZE -1 downto 0);
      coe_program_counter : out std_logic_vector(REGISTER_SIZE -1 downto 0);

      data_ADR_O   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_DAT_I   : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_DAT_O   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_WE_O    : out std_logic;
      data_SEL_O   : out std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
      data_STB_O   : out std_logic;
      data_ACK_I   : in  std_logic;
      data_CYC_O   : out std_logic;
      data_CTI_O   : out std_logic_vector(2 downto 0);
      data_STALL_I : in  std_logic;

      instr_ADR_O   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      instr_DAT_I   : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      instr_DAT_O   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      instr_WE_O    : out std_logic;
      instr_SEL_O   : out std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
      instr_STB_O   : out std_logic;
      instr_ACK_I   : in  std_logic;
      instr_CYC_O   : out std_logic;
      instr_CTI_O   : out std_logic_vector(2 downto 0);
      instr_STALL_I : in  std_logic

      );
  end component riscV_wishbone;

  component wb_ram is
    generic (
      size             : integer := 4096;
      DATA_WIDTH       : integer := 32;
      INIT_FILE_FORMAT : string  := "hex";
      INIT_FILE_NAME   : string  := "none";
      LATTICE_FAMILY   : string  := "ICE40");
    port (
      CLK_I : in std_logic;
      RST_I : in std_logic;

      ADR_I  : in std_logic_vector(31 downto 0);
      DAT_I  : in std_logic_vector(DATA_WIDTH-1 downto 0);
      WE_I   : in std_logic;
      CYC_I  : in std_logic;
      STB_I  : in std_logic;
      SEL_I  : in std_logic_vector(DATA_WIDTH/8-1 downto 0);
      CTI_I  : in std_logic_vector(2 downto 0);
      BTE_I  : in std_logic_vector(1 downto 0);
      LOCK_I : in std_logic;

      STALL_O : out std_logic;
      DAT_O   : out std_logic_vector(DATA_WIDTH-1 downto 0);
      ACK_O   : out std_logic;
      ERR_O   : out std_logic;
      RTY_O   : out std_logic);
  end component wb_ram;

  component wb_ebr_ctrl
    generic(
      SIZE             : integer := 4096;
      EBR_WB_DAT_WIDTH : integer := 32;
      INIT_FILE_FORMAT : string  := "hex";
      INIT_FILE_NAME   : string  := "none");
    port(
      CLK_I : in std_logic;
      RST_I : in std_logic;

      EBR_ADR_I  : in std_logic_vector(31 downto 0);
      EBR_DAT_I  : in std_logic_vector(EBR_WB_DAT_WIDTH-1 downto 0);
      EBR_WE_I   : in std_logic;
      EBR_CYC_I  : in std_logic;
      EBR_STB_I  : in std_logic;
      EBR_SEL_I  : in std_logic_vector(EBR_WB_DAT_WIDTH/8-1 downto 0);
      EBR_CTI_I  : in std_logic_vector(2 downto 0);
      EBR_BTE_I  : in std_logic_vector(1 downto 0);
      EBR_LOCK_I : in std_logic;

      EBR_DAT_O : out std_logic_vector(EBR_WB_DAT_WIDTH-1 downto 0);
      EBR_ACK_O : out std_logic;
      EBR_ERR_O : out std_logic;
      EBR_RTY_O : out std_logic);
  end component;

  component wb_arbiter is
    generic (
      PRIORITY_SLAVE : integer := 1;    --slave which always gets priority
      DATA_WIDTH     : integer := 32
      );
    port (
      CLK_I : in std_logic;
      RST_I : in std_logic;

      slave1_ADR_I : in std_logic_vector(31 downto 0);
      slave1_DAT_I : in std_logic_vector(DATA_WIDTH-1 downto 0);
      slave1_WE_I  : in std_logic;
      slave1_CYC_I : in std_logic;
      slave1_STB_I : in std_logic;
      slave1_SEL_I : in std_logic_vector(DATA_WIDTH/8-1 downto 0);
      slave1_CTI_I : in std_logic_vector(2 downto 0);
      slave1_BTE_I : in std_logic_vector(1 downto 0);

      slave1_LOCK_I : in std_logic;

      slave1_STALL_O : out std_logic;
      slave1_DAT_O   : out std_logic_vector(DATA_WIDTH-1 downto 0);
      slave1_ACK_O   : out std_logic;
      slave1_ERR_O   : out std_logic;
      slave1_RTY_O   : out std_logic;

      slave2_ADR_I : in std_logic_vector(31 downto 0);
      slave2_DAT_I : in std_logic_vector(DATA_WIDTH-1 downto 0);
      slave2_WE_I  : in std_logic;
      slave2_CYC_I : in std_logic;
      slave2_STB_I : in std_logic;
      slave2_SEL_I : in std_logic_vector(DATA_WIDTH/8-1 downto 0);
      slave2_CTI_I : in std_logic_vector(2 downto 0);
      slave2_BTE_I : in std_logic_vector(1 downto 0);

      slave2_LOCK_I : in std_logic;

      slave2_STALL_O : out std_logic;
      slave2_DAT_O   : out std_logic_vector(DATA_WIDTH-1 downto 0);
      slave2_ACK_O   : out std_logic;
      slave2_ERR_O   : out std_logic;
      slave2_RTY_O   : out std_logic;

      master_ADR_O  : out std_logic_vector(31 downto 0);
      master_DAT_O  : out std_logic_vector(DATA_WIDTH-1 downto 0);
      master_WE_O   : out std_logic;
      master_CYC_O  : out std_logic;
      master_STB_O  : out std_logic;
      master_SEL_O  : out std_logic_vector(DATA_WIDTH/8-1 downto 0);
      master_CTI_O  : out std_logic_vector(2 downto 0);
      master_BTE_O  : out std_logic_vector(1 downto 0);
      master_LOCK_O : out std_logic;

      master_STALL_I : in std_logic;
      master_DAT_I   : in std_logic_vector(DATA_WIDTH-1 downto 0);
      master_ACK_I   : in std_logic;
      master_ERR_I   : in std_logic;
      master_RTY_I   : in std_logic


      );
  end component;


  constant REGISTER_SIZE : natural := 32;

  signal RAM_ADR_I  : std_logic_vector(31 downto 0);
  signal RAM_DAT_I  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal RAM_WE_I   : std_logic;
  signal RAM_CYC_I  : std_logic;
  signal RAM_STB_I  : std_logic;
  signal RAM_SEL_I  : std_logic_vector(REGISTER_SIZE/8-1 downto 0);
  signal RAM_CTI_I  : std_logic_vector(2 downto 0);
  signal RAM_BTE_I  : std_logic_vector(1 downto 0);
  signal RAM_LOCK_I : std_logic;

  signal RAM_STALL_O : std_logic;
  signal RAM_DAT_O   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal RAM_ACK_O   : std_logic;
  signal RAM_ERR_O   : std_logic;
  signal RAM_RTY_O   : std_logic;

  signal data_ADR_O  : std_logic_vector(31 downto 0);
  signal data_DAT_O  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_WE_O   : std_logic;
  signal data_CYC_O  : std_logic;
  signal data_STB_O  : std_logic;
  signal data_SEL_O  : std_logic_vector(REGISTER_SIZE/8-1 downto 0);
  signal data_CTI_O  : std_logic_vector(2 downto 0);
  signal data_BTE_O  : std_logic_vector(1 downto 0);
  signal data_LOCK_O : std_logic;

  signal data_STALL_I : std_logic;
  signal data_DAT_I   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_ACK_I   : std_logic;
  signal data_ERR_I   : std_logic;
  signal data_RTY_I   : std_logic;

  signal instr_ADR_O  : std_logic_vector(31 downto 0);
  signal instr_DAT_O  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal instr_WE_O   : std_logic;
  signal instr_CYC_O  : std_logic;
  signal instr_STB_O  : std_logic;
  signal instr_SEL_O  : std_logic_vector(REGISTER_SIZE/8-1 downto 0);
  signal instr_CTI_O  : std_logic_vector(2 downto 0);
  signal instr_BTE_O  : std_logic_vector(1 downto 0);
  signal instr_LOCK_O : std_logic;

  signal instr_STALL_I : std_logic;
  signal instr_DAT_I   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal instr_ACK_I   : std_logic;
  signal instr_ERR_I   : std_logic;
  signal instr_RTY_I   : std_logic;



begin

  mem : component wb_ram
    generic map(
      SIZE             => 8*1024,
      INIT_FILE_FORMAT => "hex",
      INIT_FILE_NAME   => "test.mem",
      LATTICE_FAMILY   =>  "iCE40")
    port map(
      CLK_I => clk,
      RST_I => reset,

      ADR_I  => RAM_ADR_I,
      DAT_I  => RAM_DAT_I,
      WE_I   => RAM_WE_I,
      CYC_I  => RAM_CYC_I,
      STB_I  => RAM_STB_I,
      SEL_I  => RAM_SEL_I,
      CTI_I  => RAM_CTI_I,
      BTE_I  => RAM_BTE_I,
      LOCK_I => RAM_LOCK_I,

      STALL_O => RAM_STALL_O,
      DAT_O   => RAM_DAT_O,
      ACK_O   => RAM_ACK_O,
      ERR_O   => RAM_ERR_O,
      RTY_O   => RAM_RTY_O);

  arbiter : component wb_arbiter
    port map (
      CLK_I => clk,
      RST_I => reset,

      slave1_ADR_I  => data_ADR_O,
      slave1_DAT_I  => data_DAT_O,
      slave1_WE_I   => data_WE_O,
      slave1_CYC_I  => data_CYC_O,
      slave1_STB_I  => data_STB_O,
      slave1_SEL_I  => data_SEL_O,
      slave1_CTI_I  => data_CTI_O,
      slave1_BTE_I  => data_BTE_O,
      slave1_LOCK_I => data_LOCK_O,

      slave1_STALL_O => data_STALL_I,
      slave1_DAT_O   => data_DAT_I,
      slave1_ACK_O   => data_ACK_I,
      slave1_ERR_O   => data_ERR_I,
      slave1_RTY_O   => data_RTY_I,

      slave2_ADR_I  => instr_ADR_O,
      slave2_DAT_I  => instr_DAT_O,
      slave2_WE_I   => instr_WE_O,
      slave2_CYC_I  => instr_CYC_O,
      slave2_STB_I  => instr_STB_O,
      slave2_SEL_I  => instr_SEL_O,
      slave2_CTI_I  => instr_CTI_O,
      slave2_BTE_I  => instr_BTE_O,
      slave2_LOCK_I => instr_LOCK_O,

      slave2_STALL_O => instr_STALL_I,
      slave2_DAT_O   => instr_DAT_I,
      slave2_ACK_O   => instr_ACK_I,
      slave2_ERR_O   => instr_ERR_I,
      slave2_RTY_O   => instr_RTY_I,

      master_ADR_O  => RAM_ADR_I,
      master_DAT_O  => RAM_DAT_I,
      master_WE_O   => RAM_WE_I,
      master_CYC_O  => RAM_CYC_I,
      master_STB_O  => RAM_STB_I,
      master_SEL_O  => RAM_SEL_I,
      master_CTI_O  => RAM_CTI_I,
      master_BTE_O  => RAM_BTE_I,
      master_LOCK_O => RAM_LOCK_I,

      master_STALL_I => ram_STALL_O,
      master_DAT_I   => RAM_DAT_O,
      master_ACK_I   => RAM_ACK_O,
      master_ERR_I   => RAM_ERR_O,
      master_RTY_I   => RAM_RTY_O);




  rv : component riscV_wishbone
    port map(

      clk   => clk,
      reset => reset,

      --conduit end point
      --coe_to_host =>
      coe_from_host => (others => '0'),
      --coe_program_counter =>

      data_ADR_O   => data_ADR_O,
      data_DAT_I   => data_DAT_I,
      data_DAT_O   => data_DAT_O,
      data_WE_O    => data_WE_O,
      data_SEL_O   => data_SEL_O,
      data_STB_O   => data_STB_O,
      data_ACK_I   => data_ACK_I,
      data_CYC_O   => data_CYC_O,
      data_STALL_I => data_STALL_I,

      instr_ADR_O   => instr_ADR_O,
      instr_DAT_I   => instr_DAT_I,
      instr_DAT_O   => instr_DAT_O,
      instr_WE_O    => instr_WE_O,
      instr_SEL_O   => instr_SEL_O,
      instr_STB_O   => instr_STB_O,
      instr_ACK_I   => instr_ACK_I,
      instr_CYC_O   => instr_CYC_O,
      instr_CTI_O   => instr_CTI_O,
      instr_STALL_I => instr_STALL_I);

--  --data always takes priority, because that
--  --avoids starvation.

--  next_port_choice <= DATA when curr_port_choice = INSTR and data_STB_O = '1' else INSTR;

--  instr_ACK_I <= '0'       when curr_port_choice = DATA else EBR_ACK_O;
--  data_ACK_I  <= EBR_ACK_O when curr_port_choice = DATA else '0';

--  for control signals use different port choices based on ACK
--  port_choice <= next_port_choice when EBR_ACK_O = '1'    else curr_port_choice;
--  EBR_ADR_I   <= data_ADR_O       when port_choice = DATA else instr_ADR_O;
--  EBR_DAT_I   <= data_dat_O       when port_choice = DATA else instr_dat_O;
--  EBR_WE_I    <= data_WE_O        when port_choice = DATA else instr_WE_O;
--  EBR_SEL_I   <= data_SEL_O       when port_choice = DATA else instr_SEL_O;
--  EBR_STB_I   <= data_STB_O       when port_choice = DATA else instr_STB_O;
--  EBR_CYC_I   <= data_CYC_O       when port_choice = DATA else instr_CYC_O;
--  EBR_CTI_I   <= "000"            when port_choice = DATA else instr_CTI_O;

--  data_DAT_I  <= EBR_DAT_O;
--  instr_DAT_I <= EBR_DAT_O;

--  choice : process(clk)
--  begin
--    if rising_edge(clk) then
--      if reset = '1' then
--        curr_port_choice <= INSTR;
--      end if;
--      if EBR_ACK_O = '1' then
--        curr_port_choice <= next_port_choice;
--      end if;
--    end if;
--  end process;
--  EBR_LOCK_I <= '0';
--  EBR_BTE_I  <= (others => '0');


end architecture;
