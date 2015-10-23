library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.top_component_pkg.all;
-------------------------------------------------------------------------------
-- This is a wishbone splitter, it supports up to 8 slaves, but can
-- be modified fairly obviously to support more. to define a slave
-- address space, use the following generic
--    slaveX_address => (ADR_START,SIZE)
--
-- All slave address spaces must be a power of two in size
-------------------------------------------------------------------------------

entity wb_splitter is

  generic (
    master0_address : address_array := (0, 0);
    master1_address : address_array := (0, 0);
    master2_address : address_array := (0, 0);
    DATA_WIDTH      : natural       := 32
    );
  port(

    CLK_I : in std_logic;
    RST_I : in std_logic;

    slave_ADR_I   : in  std_logic_vector(31 downto 0);
    slave_DAT_I   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    slave_WE_I    : in  std_logic;
    slave_CYC_I   : in  std_logic;
    slave_STB_I   : in  std_logic;
    slave_SEL_I   : in  std_logic_vector(DATA_WIDTH/8-1 downto 0);
    slave_CTI_I   : in  std_logic_vector(2 downto 0);
    slave_BTE_I   : in  std_logic_vector(1 downto 0);
    slave_LOCK_I  : in  std_logic;
    slave_STALL_O : out std_logic;
    slave_DAT_O   : out std_logic_vector(DATA_WIDTH-1 downto 0);
    slave_ACK_O   : out std_logic;
    slave_ERR_O   : out std_logic;
    slave_RTY_O   : out std_logic;


    master0_ADR_O   : out std_logic_vector(31 downto 0);
    master0_DAT_O   : out std_logic_vector(DATA_WIDTH-1 downto 0);
    master0_WE_O    : out std_logic;
    master0_CYC_O   : out std_logic;
    master0_STB_O   : out std_logic;
    master0_SEL_O   : out std_logic_vector(DATA_WIDTH/8-1 downto 0);
    master0_CTI_O   : out std_logic_vector(2 downto 0);
    master0_BTE_O   : out std_logic_vector(1 downto 0);
    master0_LOCK_O  : out std_logic;
    master0_STALL_I : in  std_logic;
    master0_DAT_I   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    master0_ACK_I   : in  std_logic;
    master0_ERR_I   : in  std_logic;
    master0_RTY_I   : in  std_logic;


    master1_ADR_O   : out std_logic_vector(31 downto 0);
    master1_DAT_O   : out std_logic_vector(DATA_WIDTH-1 downto 0);
    master1_WE_O    : out std_logic;
    master1_CYC_O   : out std_logic;
    master1_STB_O   : out std_logic;
    master1_SEL_O   : out std_logic_vector(DATA_WIDTH/8-1 downto 0);
    master1_CTI_O   : out std_logic_vector(2 downto 0);
    master1_BTE_O   : out std_logic_vector(1 downto 0);
    master1_LOCK_O  : out std_logic;
    master1_STALL_I : in  std_logic;
    master1_DAT_I   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    master1_ACK_I   : in  std_logic;
    master1_ERR_I   : in  std_logic;
    master1_RTY_I   : in  std_logic;


    master2_ADR_O   : out std_logic_vector(31 downto 0);
    master2_DAT_O   : out std_logic_vector(DATA_WIDTH-1 downto 0);
    master2_WE_O    : out std_logic;
    master2_CYC_O   : out std_logic;
    master2_STB_O   : out std_logic;
    master2_SEL_O   : out std_logic_vector(DATA_WIDTH/8-1 downto 0);
    master2_CTI_O   : out std_logic_vector(2 downto 0);
    master2_BTE_O   : out std_logic_vector(1 downto 0);
    master2_LOCK_O  : out std_logic;
    master2_STALL_I : in  std_logic;
    master2_DAT_I   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    master2_ACK_I   : in  std_logic;
    master2_ERR_I   : in  std_logic;
    master2_RTY_I   : in  std_logic);

end entity wb_splitter;


architecture rtl of wb_splitter is
  constant REGISTER_SIZE : natural := 32;

  signal master0_stb : std_logic;
  signal master1_stb : std_logic;
  signal master2_stb : std_logic;

  type choice_t is (M0, M1, M2);
  signal choice      : choice_t;
  signal last_choice : choice_t;
  signal adr_i       : unsigned(31 downto 0);
begin  -- architecture rt
  adr_i <= unsigned(slave_ADR_I);
  master0_gen : if master0_address(0) /= 0 generate
    constant adr  : natural                            := master0_address(1);
    constant size : natural                            := master0_address(0);
    constant mask : unsigned(REGISTER_SIZE-1 downto 0) := not to_unsigned(size-1, REGISTER_SIZE);

  begin
    master0_stb <= slave_STB_I when (adr_i and mask) = to_unsigned(adr, REGISTER_SIZE) else '0';
  end generate master0_gen;
  nmaster0_gen : if master0_address(0) = 0 generate
--  begin
    master0_stb <= '0';
  end generate nmaster0_gen;

  master1_gen : if master1_address(1) /= 0 generate
    constant adr  : natural                            := master1_address(1);
    constant size : natural                            := master1_address(0);
    constant mask : unsigned(REGISTER_SIZE-1 downto 0) := not to_unsigned(size-1, REGISTER_SIZE);
  begin
    master1_stb <= slave_STB_I when (adr_i and mask) = to_unsigned(adr, REGISTER_SIZE) else '0';
  end generate master1_gen;
  nmaster1_gen : if master1_address(0) = 0 generate
--  begin
    master1_stb <= '0';
  end generate nmaster1_gen;

  master2_gen : if master2_address(1) /= 0 generate
    constant adr  : natural                            := master2_address(1);
    constant size : natural                            := master2_address(0);
    constant mask : unsigned(REGISTER_SIZE-1 downto 0) := not to_unsigned(size-1, REGISTER_SIZE);
  begin
    master2_stb <= slave_STB_I when (adr_i and mask) = to_unsigned(adr, REGISTER_SIZE) else '0';
  end generate master2_gen;
  nmaster2_gen : if master2_address(0) = 0 generate
--  begin
    master2_stb <= '0';
  end generate nmaster2_gen;


  -----------------------------------------------------------------------------
  -- hook up the stb signals that are generated above,
  -- and hookup the passthrough signals
  -----------------------------------------------------------------------------

  master0_STB_O  <= master0_stb;
  master0_ADR_O  <= slave_ADR_I;
  master0_DAT_O  <= slave_DAT_I;
  master0_WE_O   <= slave_WE_I;
  master0_CYC_O  <= slave_CYC_I;
  master0_SEL_O  <= slave_SEL_I;
  master0_CTI_O  <= slave_CTI_I;
  master0_BTE_O  <= slave_BTE_I;
  master0_LOCK_O <= slave_LOCK_I;

  master1_STB_O  <= master1_stb;
  master1_ADR_O  <= slave_ADR_I;
  master1_DAT_O  <= slave_DAT_I;
  master1_WE_O   <= slave_WE_I;
  master1_CYC_O  <= slave_CYC_I;
  master1_SEL_O  <= slave_SEL_I;
  master1_CTI_O  <= slave_CTI_I;
  master1_BTE_O  <= slave_BTE_I;
  master1_LOCK_O <= slave_LOCK_I;

  master2_STB_O  <= master2_stb;
  master2_ADR_O  <= slave_ADR_I;
  master2_DAT_O  <= slave_DAT_I;
  master2_WE_O   <= slave_WE_I;
  master2_CYC_O  <= slave_CYC_I;
  master2_SEL_O  <= slave_SEL_I;
  master2_CTI_O  <= slave_CTI_I;
  master2_BTE_O  <= slave_BTE_I;
  master2_LOCK_O <= slave_LOCK_I;

  -------------------------------------------------------------------------------
  -- The output signals are multiplexed below
  -------------------------------------------------------------------------------
  choice <= M0 when master0_stb = '1' else
            M1 when master1_stb = '1' else
            M2 when master2_stb = '1';

  process(clk_i)
  begin
    if rising_edge(clk_I) then
      last_choice <= choice;
    end if;
  end process;


  with choice select
    slave_stall_O <=
    master0_STALL_I when M0,
    master1_STALL_I when M1,
    master2_STALL_I when M2;

  with last_choice select
    slave_ack_O <=
    master0_ACK_I when M0,
    master1_ACK_I when M1,
    master2_ACK_I when M2;


  with last_choice select
    slave_DAT_O <=
    master0_DAT_I when M0,
    master1_DAT_I when M1,
    master2_DAT_I when M2;

  slave_ERR_O <= '0';
  slave_RTY_O <= '0';


end architecture rtl;
