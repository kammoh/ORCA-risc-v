

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
    clk             : in  std_logic;
    instr_addr      : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_addr       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_we         : in  std_logic;
    data_be         : in  std_logic_vector(REGISTER_SIZE/8-1 downto 0);
    data_wdata      : in  std_logic_vector(REGISTER_SIZE - 1 downto 0);
    data_read_en    : in  std_logic;
    instr_read_en   : in  std_logic;
    data_rdata      : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    instr_data      : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    instr_read_busy : out std_logic;
    data_read_busy  : out std_logic);
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
    variable d      : integer;
  begin
    tmp := input;
    for b in 0 to BYTES_PER_WORD-1 loop
      d         := BYTES_PER_WORD-1 -b;
      to_ret(b) := tmp(BYTE_WIDTH*(d+1) -1 downto BYTE_WIDTH*d);
    end loop;  -- b
    return to_ret;
  end function;

  -- declare the RAM
  signal reset_rom : reset_rom_t := (
    little_endian(LW(1, 0, 0)),  --    0x0    load from instruction memory
    little_endian(LUI(6, BRAM_START)),  --    0x4    BRAM_START = BRAM_START
    little_endian(ADDI(1, 0, 16#6a#)),  --j   0x8    c= 'j'
    little_endian(SB(1, 6, 10)),        --    0xC    BRAM_START[10]=c
    little_endian(ADDI(2, 0, 16#6f#)),  --o   0x10   c= 'o'
    little_endian(SB(2, 6, 11)),        --    0x14   BRAM_START[11]=c
    little_endian(ADDI(3, 0, 16#65#)),  --e   0x18   c= 'e'
    little_endian(SB(3, 6, 12)),        --    0x1C   BRAM_START[12]=c
    little_endian(ADDI(4, 0, 16#6c#)),  --l   0x20   c= 'l'
    little_endian(SB(4, 6, 13)),        --    0x24   BRAM_START[13]=c
    little_endian(SB(0, 6, 14)),        --    0x28   BRAM_START[14]='\0'
    little_endian(ADDI(1, 6, 10)),      --    0x2C   ptr=BRAMSTART+10
                                        --  do{
    little_endian(LB(2, 1, 0)),         --    0x302C   c=*ptr
    little_endian(ADDI(3, 2, -32)),     --    0x34   C=c-32 //capitalize
    little_endian(SB(3, 1, 10)),        --    0x38   ptr[10]=C
    little_endian(ADDI(1, 1, 1)),       --    0x3C   ptr++
    little_endian(BNE(2, 0, -16)),      --    0x44  }while(c!= 0)
    little_endian(JAL(0, 0)),           --     infinite loop
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

  signal latched_instr_choice : std_logic_vector(1 downto 0);
  signal latched_data_choice : std_logic_vector(1 downto 0);

  constant ROM_CHOICE  : std_logic_vector(1 downto 0) := "01";
  constant BRAM_CHOICE : std_logic_vector(1 downto 0) := "10";
  constant NO_CHOICE   : std_logic_vector(1 downto 0) := (others => '0');

  signal instr_choice : std_logic_vector(1 downto 0);
  signal data_choice  : std_logic_vector(1 downto 0);

  signal rom_addr_combined : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal rom_data_combined : std_logic_vector(REGISTER_SIZE-1 downto 0);

begin  -- rtl


  --which memory object does the data address refer to?
  with to_integer(unsigned(data_addr)) select
    data_choice <=
    BRAM_CHOICE when BRAM_START to BRAM_START+BRAM_SIZE-1,
    ROM_CHOICE  when RESET_ROM_START to RESET_ROM_START+RESET_ROM_SIZE,
    NO_CHOICE   when others;

  --which memory object does the instr address refer to?
  with to_integer(unsigned(instr_addr)) select
    instr_choice <=
    BRAM_CHOICE when BRAM_START to BRAM_START+BRAM_SIZE-1,
    ROM_CHOICE  when RESET_ROM_START to RESET_ROM_START+RESET_ROM_SIZE,
    NO_CHOICE   when others;



  --get output from the reset rom every cycle
  dual_ported_instr_ram : if DUAL_PORTED_INSTR generate
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
    instr_read_busy <= '0';
  end generate dual_ported_instr_ram;

  single_ported_instr_ram : if not DUAL_PORTED_INSTR generate
    --data addr gets priority since that prevents starvation
    rom_addr_combined <= data_addr when data_choice = ROM_CHOICE and data_read_en = '1'
                         else instr_addr;
    instr_read_busy <= '1' when data_choice = ROM_CHOICE and data_read_en = '1' else '0';

    reset_rom_instr_out <= rom_data_combined;
    reset_rom_data_out  <= rom_data_combined;

    process(clk)
      variable q : word_t;
    begin
      if rising_edge(clk) then
        q := reset_rom(word_address(rom_addr_combined, log2(RESET_ROM_SIZE)));
        for i in 0 to BYTES_PER_WORD - 1 loop
          rom_data_combined(BYTE_WIDTH*(i+1) - 1 downto BYTE_WIDTH*i) <= q(i);
        end loop;
      end if;
    end process;
  end generate single_ported_instr_ram;


  bram_data_we <= '1' when data_choice = BRAM_CHOICE and data_we = '1' else '0';
  --get output from dualport block_ram
  bram_addr1   <= word_address(instr_addr, log2(BRAM_SIZE));
  bram_addr2   <= word_address(data_addr, log2(BRAM_SIZE));

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
      latched_instr_choice <= instr_choice;
      latched_data_choice <= data_choice;
    end if;
  end process;



  --coalesce instruction read
  with latched_instr_choice select
    instr_data <=
    bram_instr_out      when BRAM_CHOICE,
    reset_rom_instr_out when ROM_CHOICE,
    (others => 'X')     when others;

  --coalesce data read
  with latched_data_choice select
    data_rdata <=
    bram_data_out      when BRAM_CHOICE,
    reset_rom_data_out when ROM_CHOICE,
    (others => 'X')    when others;

  data_read_busy <= '0';
end architecture;
