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

       data_ADR_O : out std_logic_vector(REGISTER_SIZE-1 downto 0);
       data_DAT_I : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
       data_DAT_O : out std_logic_vector(REGISTER_SIZE-1 downto 0);
       data_WE_O  : out std_logic;
       data_SEL_O : out std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
       data_STB_O : out std_logic;
       data_ACK_I : in  std_logic;
       data_CYC_O : out std_logic;

       instr_ADR_O : out std_logic_vector(REGISTER_SIZE-1 downto 0);
       instr_DAT_I : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
       instr_DAT_O : out std_logic_vector(REGISTER_SIZE-1 downto 0);
       instr_WE_O  : out std_logic;
       instr_SEL_O : out std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
       instr_STB_O : out std_logic;
       instr_ACK_I : in  std_logic;
       instr_CYC_O : out std_logic
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


  signal idle       : std_logic := '0';
  signal last_addr  : std_logic_vector(REGISTER_SIZE -1 downto 0);
  signal last_write : std_logic;
  signal last_read  : std_logic;

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
  avm_data_waitrequest   <= not data_ACK_I;
  avm_data_readdatavalid <= data_ACK_I and avm_data_read;


  --output
  instr_ADR_O                   <= avm_instruction_address;
  instr_DAT_O                   <= avm_instruction_writedata;
  instr_WE_O                    <= avm_instruction_write;
  instr_SEL_O                   <= avm_instruction_byteenable;
  instr_STB_O                   <= (avm_instruction_write or avm_instruction_read)and not idle;
  instr_CYC_O                   <= (avm_instruction_write or avm_instruction_read)and not idle;
  --input
  avm_instruction_readdata      <= instr_DAT_I;
  avm_instruction_waitrequest   <= not instr_ACK_I;
  avm_instruction_readdatavalid <= instr_ACK_I and avm_instruction_read;

  --it seems that if the address is not one word after the word before it,
  --there needs to be an idle cycle in between. weird.
  --process(clk) is
  --begin
  --  if rising_edge(clk) then
  --    last_addr  <= avm_instruction_address;
  --    last_write <= avm_instruction_write;
  --    last_read  <= avm_instruction_read;
  --    if avm_instruction_read = '1' then
  --      if last_read = '1' then
  --        if unsigned(last_addr)+to_unsigned(4, REGISTER_SIZE) /= unsigned(avm_instruction_address) then
  --          idle <= '1';
  --        else
  --          idle <= '0';
  --        end if;  --mismatch
  --      else                            --lastread
  --        idle <= '0';
  --      end if;
  --    else
  --      idle <= '0';
  --    end if;  --read
  --  end if;  --clk
  --end process;
end architecture rtl;
