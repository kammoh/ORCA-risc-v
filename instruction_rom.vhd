library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.components.all;
use work.instructions.all;
use work.utils.all;

entity instruction_rom is
  generic (
    REGISTER_SIZE : integer;
    ROM_SIZE      : integer;
    PORTS         : natural range 1 to 2);
  port (
    clk        : in std_logic;
    instr_addr : in natural range 0 to ROM_SIZE -1;
    data_addr  : in natural range 0 to ROM_SIZE -1;
    instr_re   : in std_logic;
    data_re    : in std_logic;

    data_out         : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    instr_out        : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    instr_read_stall : out std_logic;
    data_read_stall  : out std_logic;
    instr_readvalid  : out std_logic;
    data_readvalid   : out std_logic);

end entity instruction_rom;

architecture rtl of instruction_rom is

  constant BYTE_WIDTH     : natural := 8;
  constant BYTES_PER_WORD : natural := REGISTER_SIZE/BYTE_WIDTH;

  --  build up 2D array to hold the memory
  type word_t is array (0 to BYTES_PER_WORD-1) of std_logic_vector(BYTE_WIDTH-1 downto 0);

  type rom_t is array (0 to ROM_SIZE -1) of word_t;

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
  constant BRAM_START : integer := 16#10000#;

  -- declare the RAM
  signal reset_rom : rom_t := (
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
    little_endian(LB(2, 1, 0)),         --    0x30   c=*ptr
    little_endian(ADDI(3, 2, -32)),     --    0x34   C=c-32 //capitalize
    little_endian(SB(3, 1, 10)),        --    0x38   ptr[10]=C
    little_endian(ADDI(1, 1, 1)),       --    0x3C   ptr++
    little_endian(BNE(2, 0, -16)),      --    0x44  }while(c!= 0)
    little_endian(JAL(0, 0)),           --     infinite loop
    others => little_endian(NOP(0)));

  signal rom_addr_combined : natural;
  signal rom_data_combined : std_logic_vector(REGISTER_SIZE-1 downto 0);

begin  -- architecture rtl

  --get output from the reset rom every cycle
  dual_ported_instr_ram : if PORTS = 2 generate
    process(clk)
      variable i_q : word_t;
      variable d_q : word_t;
    begin
      if rising_edge(clk) then
        data_readvalid  <= data_re;
        instr_readvalid <= instr_re;

        i_q := reset_rom(instr_addr);
        d_q := reset_rom(data_addr);

        for i in 0 to BYTES_PER_WORD - 1 loop
          instr_out(BYTE_WIDTH*(i+1) - 1 downto BYTE_WIDTH*i) <= i_q(i);
          data_out(BYTE_WIDTH*(i+1) - 1 downto BYTE_WIDTH*i)  <= d_q(i);
        end loop;

      end if;
    end process;
    instr_read_stall <= '0';
    data_read_stall  <= '0';
  end generate dual_ported_instr_ram;

  single_ported_instr_ram : if PORTS = 1 generate
    --data addr gets priority since that prevents starvation
    rom_addr_combined <= data_addr when data_re = '1' else instr_addr;
    instr_read_stall  <= instr_re and data_re;
    data_read_stall   <= '0';

    instr_out <= rom_data_combined;
    data_out  <= rom_data_combined;

    process(clk)
      variable q : word_t;
    begin
      if rising_edge(clk) then
        if data_re = '1' then
          data_readvalid  <= '1';
          instr_readvalid <= '0';
        elsif instr_re = '1' then
          data_readvalid  <= '0';
          instr_readvalid <= '1';
        else
          data_readvalid  <= '0';
          instr_readvalid <= '0';
        end if;

        q := reset_rom(rom_addr_combined);
        for i in 0 to BYTES_PER_WORD - 1 loop
          rom_data_combined(BYTE_WIDTH*(i+1) - 1 downto BYTE_WIDTH*i) <= q(i);
        end loop;
      end if;
    end process;
  end generate single_ported_instr_ram;

end architecture rtl;
