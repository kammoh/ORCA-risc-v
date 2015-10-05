library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.rv_components.all;

entity riscV_wishbone is

  generic (
    REGISTER_SIZE : integer := 32;
    RESET_VECTOR  : natural := 16#00000200#);

  port(clk   : in std_logic;
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

end entity riscV_wishbone;



architecture rtl of riscV_wishbone is
  signal avm_data_address       : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal avm_data_byteenable    : std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
  signal avm_data_read          : std_logic;
  signal avm_data_readdata      : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal avm_data_response      : std_logic_vector(1 downto 0);
  signal avm_data_write         : std_logic;
  signal avm_data_writedata     : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal avm_data_lock          : std_logic;
  signal avm_data_waitrequest   : std_logic;
  signal avm_data_readdatavalid : std_logic;


  signal avm_instruction_address       : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal avm_instruction_byteenable    : std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
  signal avm_instruction_read          : std_logic;
  signal avm_instruction_readdata      : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal avm_instruction_response      : std_logic_vector(1 downto 0);
  signal avm_instruction_write         : std_logic;
  signal avm_instruction_writedata     : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal avm_instruction_lock          : std_logic;
  signal avm_instruction_waitrequest   : std_logic;
  signal avm_instruction_readdatavalid : std_logic;

  signal instr_readvalid_mask : std_logic;
  signal data_readvalid_mask  : std_logic;


  constant INCR_BURST_CYC : std_logic_vector(2 downto 0) := "010";
  constant END_BURST_CYC  : std_logic_vector(2 downto 0) := "111";
  constant CLASSIC_CYC    : std_logic_vector(2 downto 0) := "000";

  signal burst_break   : std_logic;
  signal expected_addr : std_logic_vector(REGISTER_SIZE -1 downto 0);
  signal last_bb       : std_logic;

begin  -- architecture rtl

  rv : component riscV
    generic map (
      REGISTER_SIZE => REGISTER_SIZE,
      RESET_VECTOR  => RESET_VECTOR)
    port map(
      clk   => clk,
      reset => reset,

      --conduit end point
      coe_to_host         => coe_to_host,
      coe_from_host       => coe_from_host,
      coe_program_counter => coe_program_counter,

      --avalon master bus
      avm_data_address       => avm_data_address,
      avm_data_byteenable    => avm_data_byteenable,
      avm_data_read          => avm_data_read,
      avm_data_readdata      => avm_data_readdata,
      avm_data_response      => avm_data_response,
      avm_data_write         => avm_data_write,
      avm_data_writedata     => avm_data_writedata,
      avm_data_lock          => avm_data_lock,
      avm_data_waitrequest   => avm_data_waitrequest,
      avm_data_readdatavalid => avm_data_readdatavalid,

      --avalon master bus                     --avalon master bus
      avm_instruction_address       => avm_instruction_address,
      avm_instruction_byteenable    => avm_instruction_byteenable,
      avm_instruction_read          => avm_instruction_read,
      avm_instruction_readdata      => avm_instruction_readdata,
      avm_instruction_response      => avm_instruction_response,
      avm_instruction_write         => avm_instruction_write,
      avm_instruction_writedata     => avm_instruction_writedata,
      avm_instruction_lock          => avm_instruction_lock,
      avm_instruction_waitrequest   => avm_instruction_waitrequest,
      avm_instruction_readdatavalid => avm_instruction_readdatavalid
      );

  --output
  data_ADR_O             <= avm_data_address;
  data_DAT_O             <= avm_data_writedata;
  data_WE_O              <= avm_data_write;
  data_SEL_O             <= avm_data_byteenable;
  data_STB_O             <= avm_data_write or avm_data_read;
  data_CYC_O             <= avm_data_write or avm_data_read;
  --input
  avm_data_readdata      <= data_DAT_I;
  avm_data_waitrequest   <= data_STALL_I;
  avm_data_readdatavalid <= data_ACK_I and data_readvalid_mask;



  --output
  instr_ADR_O                   <= avm_instruction_address;
  instr_DAT_O                   <= avm_instruction_writedata;
  instr_WE_O                    <= avm_instruction_write;
  instr_SEL_O                   <= avm_instruction_byteenable;
  instr_STB_O                   <= (avm_instruction_write or avm_instruction_read);
  instr_CYC_O                   <= (avm_instruction_write or avm_instruction_read);
--  instr_CTI_O <= INCR_BURST_CYC when burst_break = '0' else END_BURST_CYC;
  instr_CTI_O                   <= CLASSIC_CYC;
  --input
  avm_instruction_readdata      <= instr_DAT_I;
  avm_instruction_waitrequest   <= instr_STALL_I;
  avm_instruction_readdatavalid <= instr_ACK_I ;


  --if previous cycle was a read, then this cycle can have a
  --readdatavalid, else not,
  process(clk)
  begin
    if rising_edge(clk) then

      if avm_data_read = '1' then
        data_readvalid_mask <= '1';
      elsif avm_data_readdatavalid = '1' then
        data_readvalid_mask <= '0';
      end if;

      if avm_instruction_read = '1' then
        instr_readvalid_mask <= '1';
      elsif avm_instruction_readdatavalid = '1' then
        instr_readvalid_mask <= '0';
      end if;

      if reset= '1' then
        instr_readvalid_mask <= '0';
        data_readvalid_mask <= '0';
      end if;
    end if;
  end process;
  --process(clk) is
  --begin
  --  if rising_edge(clk) then
  --    if reset = '1' then
  --      expected_addr <= std_logic_vector(avm_instruction_address);
  --      last_bb       <= burst_break;
  --    else
  --      if instr_ACK_I = '1' then

  --        last_bb <= burst_break;

  --      end if;
  --    end if;
  --  end if;
  --end process;

end architecture rtl;
