

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
    REGISTER_SIZE : natural);
  port (
    clk        : in  std_logic;
    instr_addr : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_addr  : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_we    : in  std_logic;
    data_be    : in  std_logic_vector(REGISTER_SIZE/8-1 downto 0);
    data_wdata : in  std_logic_vector(REGISTER_SIZE - 1 downto 0);
    data_rdata : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    instr_data : out std_logic_vector(REGISTER_SIZE-1 downto 0));
end memory_system;

architecture rtl of memory_system is


  constant RESET_ROM_START : natural := 0;
  constant RESET_ROM_SIZE  : natural := 4*1024;

  constant BRAM_START : natural := 16#10000#;
  constant BRAM_SIZE  : natural := 1*1024;

  constant BYTE_WIDTH     : natural := 8;
  constant BYTES_PER_WORD : natural := REGISTER_SIZE/BYTE_WIDTH;

  --  build up 2D array to hold the memory
  type word_t is array (0 to BYTES_PER_WORD-1) of std_logic_vector(BYTE_WIDTH-1 downto 0);

  type reset_rom_t is array (0 to RESET_ROM_SIZE -1) of word_t;

  function little_endian (
    input : std_logic_vector)
    return word_t is
    variable to_ret : word_t;
    variable tmp    : std_logic_vector(input'length -1 downto 0);
    variable d : integer;
  begin
    tmp := input;
    for b in 0 to BYTES_PER_WORD-1 loop
      d:= BYTES_PER_WORD-1 -b;
      to_ret(b) := tmp(BYTE_WIDTH*(d+1) -1 downto BYTE_WIDTH*d);
    end loop;  -- b
    return to_ret;
  end function;

  -- declare the RAM
  signal reset_rom : reset_rom_t := (
    little_endian(LUI(6, BRAM_START)),  --    0x0    BRAM_START = BRAM_START
    little_endian(ADDI(1, 0, 16#6a#)),  --j   0x4    c= 'j'
    little_endian(SB(1, 6, 10)),        --    0x8    BRAM_START[10]=c
    little_endian(ADDI(2, 0, 16#6f#)),  --o   0xC    c= 'o'
    little_endian(SB(2, 6, 11)),        --    0x10   BRAM_START[11]=c
    little_endian(ADDI(3, 0, 16#65#)),  --e   0x14   c= 'e'
    little_endian(SB(3, 6, 12)),        --    0x18   BRAM_START[12]=c
    little_endian(ADDI(4, 0, 16#6c#)),  --l   0x1C   c= 'l'
    little_endian(SB(4, 6, 13)),        --    0x20   BRAM_START[13]=c
    little_endian(SB(0, 6, 14)),        --    0x24   BRAM_START[14]='\0'
    little_endian(ADDI(1, 6, 10)),      --    0x28   ptr=BRAMSTART+10
                                        --  do{
    little_endian(LB(2, 1, 0)),         --    0x2C   c=*ptr
    little_endian(ADDI(3, 2, -32)),     --    0x30   C=c-32 //capitalize
    little_endian(SB(3, 1, 10)),        --    0x34   ptr[10]=C
    little_endian(ADDI(1, 1, 1)),       --    0x38   ptr++
    little_endian(BNE(2, 0, -16)),      --    0x3C }while(c!= 0)
    little_endian(JAL(0, 0)),           --    0x40 infinite loop
    others => little_endian(NOP(0)));

  signal instr_local : word_t;

  function word_address (
    byte_address : std_logic_vector;
    length       : natural)
    return integer is
    constant shift : natural := log2(BYTES_PER_WORD);
  begin
    return to_integer(unsigned(byte_address(length+shift-1 downto shift)));
  end function;


  signal reset_rom_instr_out : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal reset_rom_data_out  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal bram_instr_out      : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal bram_data_out       : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal bram_data_we        : std_logic;
  signal bram_addr1          : integer range 0 to BRAM_SIZE-1;
  signal bram_addr2          : integer range 0 to BRAM_SIZE-1;

  signal latched_instr_addr : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal latched_data_addr  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal latched_data_we    : std_logic;
  signal latched_data_be    : std_logic_vector(REGISTER_SIZE/8-1 downto 0);

begin  -- rtl

  --get output from the reset rom every cycle
  process(clk)
    variable i_q : word_t;
    variable d_q : word_t;
  begin
    if rising_edge(clk) then
      i_q := reset_rom(word_address(instr_addr, log2(RESET_ROM_SIZE)));
      d_q := reset_rom(word_address(data_addr, log2(RESET_ROM_SIZE)));

      for i in 0 to BYTES_PER_WORD - 1 loop
        reset_rom_instr_out(BYTE_WIDTH*(i+1) - 1 downto BYTE_WIDTH*i) <= i_q(i);
        reset_rom_data_out(BYTE_WIDTH*(i+1) - 1 downto BYTE_WIDTH*i)  <= d_q(i);
      end loop;

    end if;
  end process;

  addr_mem_sel : process (data_addr, data_we) is
  begin  -- process addr_mem_sel
    case to_integer(unsigned(data_addr)) is
      when BRAM_START to BRAM_START+BRAM_SIZE-1 =>
        bram_data_we <= data_we;
      when others =>
        bram_data_we <= '0';
    end case;
  end process addr_mem_sel;

  --get output from dualport block_ram
  bram_addr1 <= word_address(instr_addr, log2(BRAM_SIZE));
  bram_addr2 <= word_address(data_addr, log2(BRAM_SIZE));

  bram : component byte_enabled_true_dual_port_ram
    generic map (
      ADDR_WIDTH => log2(BRAM_SIZE),
      BYTES      => BYTES_PER_WORD)
    port map (
      clk    => clk,
      we1    => '0',
      we2    => bram_data_we,
      be1    => (others => '0'),
      be2    => data_be,
      wdata1 => (others => '0'),
      wdata2 => data_wdata,
      addr1  => bram_addr1,
      addr2  => bram_addr2,
      rdata1 => bram_instr_out,
      rdata2 => bram_data_out);

  latched_inputs : process (clk)
  begin
    if rising_edge(clk) then
      latched_instr_addr <= instr_addr;
      latched_data_addr  <= data_addr;
    end if;
  end process;



  --coalesce instruction read
  with to_integer(unsigned(latched_instr_addr)) select
    instr_data <=
    bram_instr_out      when BRAM_START to BRAM_START+BRAM_SIZE-1,
    reset_rom_instr_out when RESET_ROM_START to RESET_ROM_START + RESET_ROM_SIZE-1,
    (others => 'X')     when others;

  --coalesce data read
  with to_integer(unsigned(latched_data_addr)) select
    data_rdata <=
    bram_data_out      when BRAM_START to BRAM_START+BRAM_SIZE-1,
    reset_rom_data_out when RESET_ROM_START to RESET_ROM_START + RESET_ROM_SIZE-1,
    (others => 'X')    when others;


end architecture;
