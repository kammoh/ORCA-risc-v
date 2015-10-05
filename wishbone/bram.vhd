
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_TEXTIO.all;
use STD.TEXTIO.all;

library work;
use work.utils.all;


entity bram_lattice is
  generic (
    RAM_DEPTH      : integer := 1024;
    RAM_WIDTH      : integer := 32;
    BYTE_SIZE      : integer := 8;
    INIT_FILE_NAME : string
    );
  port
    (
      address  : in  std_logic_vector(log2(RAM_DEPTH)-1 downto 0);
      clock    : in  std_logic;
      data_in  : in  std_logic_vector(RAM_WIDTH-1 downto 0);
      we       : in  std_logic;
      be       : in  std_logic_vector(RAM_WIDTH/BYTE_SIZE-1 downto 0);
      readdata : out std_logic_vector(RAM_WIDTH-1 downto 0)
      );
end bram_lattice;


architecture rtl of bram_lattice is
  type word_t is array (0 to RAM_WIDTH/BYTE_SIZE-1) of std_logic_vector(BYTE_SIZE-1 downto 0);
  type ram_type is array (0 to RAM_DEPTH-1) of std_logic_vector(RAM_WIDTH-1 downto 0);

  function to_slv (tmp_hexnum : string) return std_logic_vector is
    variable temp  : std_logic_vector(31 downto 0);
    variable digit : natural;
  begin
    for i in tmp_hexnum'range loop
      case tmp_hexnum(i) is
        when '0' to '9' =>
          digit := character'pos(tmp_hexnum(i)) - character'pos('0');
        when 'A' to 'F' =>
          digit := (character'pos(tmp_hexnum(i)) - character'pos('A'))+10;
        when 'a' to 'f' =>
          digit := (character'pos(tmp_hexnum(i)) - character'pos('a'))+10;
        when others => digit := 0;

      end case;
      temp(i*4+3 downto i*4) := std_logic_vector(to_unsigned(digit, 4));
    end loop;
    return temp;
  end function;

  impure function init_bram (ram_file_name : in string) return ram_type is
    -- pragma synthesis_off
    file ramfile           : text is in ram_file_name;
    variable line_read     : line;
    variable my_line       : line;
    variable ss            : string(7 downto 0);
    -- pragma synthesis_on
    variable ram_to_return : ram_type;

  begin
    --ram_to_return := (others => (others => '0'));
    -- pragma synthesis_off
    for i in ram_type'range loop
      if not endfile(ramfile) then
        readline(ramfile, line_read);
        read(line_read, ss);
        ram_to_return(i) := to_slv(ss);
      end if;
    end loop;
    -- pragma synthesis_on
    return ram_to_return;
  end function;


  signal ram : ram_type := init_bram(INIT_FILE_NAME);

  signal Q : std_logic_vector(RAM_WIDTH-1 downto 0);

begin

  process (clock)
  begin
    if rising_edge(clock) then
      Q <= ram(to_integer(unsigned(address)));
      if WE = '1' then
        ram(to_integer(unsigned(address))) <= data_in;
      end if;
    end if;
  end process;

  readdata <= Q;
end rtl;
