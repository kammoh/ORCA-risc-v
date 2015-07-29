library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;
--use IEEE.std_logic_arith.all;

entity load_store_unit is


  generic (
    REGISTER_SIZE       : integer;
    SIGN_EXTENSION_SIZE : integer;
    INSTRUCTION_SIZE    : integer;
    MEMORY_SIZE_BYTES   : integer);

  port (
    clk            : in  std_logic;
    valid          : in  std_logic;
    rs1_data       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    rs2_data       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    instruction    : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    sign_extension : in  std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
    data_out       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_enable    : out std_logic);
end entity load_store_unit;

architecture rtl of load_store_unit is
  type memory_type is array(MEMORY_SIZE_BYTES downto 0) of unsigned(7 downto 0);
  signal memory : memory_type;

  constant IMMEDIATE_SIZE : integer := 12;

  constant BYTE_SIZE  : unsigned(2 downto 0) := "000";
  constant HALF_SIZE  : unsigned(2 downto 0) := "001";
  constant WORD_SIZE  : unsigned(2 downto 0) := "010";
  constant UBYTE_SIZE : unsigned(2 downto 0) := "100";
  constant UHALF_SIZE : unsigned(2 downto 0) := "101";

  alias base   : std_logic_vector(REGISTER_SIZE-1 downto 0) is rs1_data;
  alias source : std_logic_vector(REGISTER_SIZE-1 downto 0) is rs2_data;

begin
  ls_proc : process (clk) is
    variable imm          : unsigned(REGISTER_SIZE-1 downto 0);
    variable fun3         : unsigned(2 downto 0);
    variable byte         : unsigned(7 downto 0);
    variable opcode       : unsigned(6 downto 0);
    variable data_out_int : unsigned(REGISTER_SIZE-1 downto 0);
    variable store_data   : unsigned(REGISTER_SIZE-1 downto 0);


  begin  -- process ls_proc
    if rising_edge(clk) then
      fun3   := unsigned(instruction(14 downto 12));
      opcode := unsigned(instruction(6 downto 0));

      --default outputs
      data_enable <= '0';
      data_out    <= (others => 'X');

      --if data on inputs is not valid, don't do anything
      if valid = '1' then
        if opcode = "0100011" then      --store
          imm := unsigned(sign_extension(REGISTER_SIZE-12-1 downto 0) &
                          instruction(31 downto 25) & instruction(11 downto 7));
          imm        := imm + unsigned(base);
          store_data := unsigned(source);
          case fun3 is
            when BYTE_SIZE =>
              memory(to_integer(imm)) <= store_data(7 downto 0);
            when HALF_SIZE =>
              memory(to_integer(imm))   <= store_data(7 downto 0);
              memory(to_integer(imm)+1) <= store_data(15 downto 8);
            when WORD_SIZE =>
              memory(to_integer(imm))   <= store_data(7 downto 0);
              memory(to_integer(imm)+1) <= store_data(15 downto 8);
              memory(to_integer(imm)+2) <= store_data(23 downto 16);
              memory(to_integer(imm)+3) <= store_data(31 downto 24);
            when others => null;
          end case;

        elsif opcode = "0000011" then   --load

          imm := unsigned(sign_extension(REGISTER_SIZE-12-1 downto 0) &
                          instruction(31 downto 20));
          imm := imm + unsigned(base);
          for i in 0 to 3 loop
            byte                               := memory(to_integer(imm)+i);
            data_out_int((i+1)*8-1 downto i*8) := byte;
          end loop;  -- i
          case fun3 is
            when BYTE_SIZE =>
              for i in 31 downto 8 loop
                data_out_int(i) := data_out_int(7);
              end loop;  -- i
            when HALF_SIZE =>
              for i in 31 downto 16 loop
                data_out_int(i) := data_out_int(15);
              end loop;  -- i
--          when WORD_SIZE => null;
            when UBYTE_SIZE =>
              for i in 31 downto 8 loop
                data_out_int(i) := '0';
              end loop;  -- i

            when UHALF_SIZE =>
              for i in 31 downto 16 loop
                data_out_int(i) := '0';
              end loop;  -- i

            when others => null;
          end case;
          data_enable <= '1';
          data_out    <= std_logic_vector(data_out_int);
        end if;  --load/store

      end if;  --data_valid

    end if;  --clk


  end process ls_proc;


end architecture;
