library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library riscv;
use riscv.instructions.all;
use riscv.components.all;

entity load_store_unit_tb is
end entity;

architecture rtl of load_store_unit_tb is
  constant REGISTER_SIZE       : integer := 32;
  constant INSTRUCTION_SIZE    : integer := 32;
  constant SIGN_EXTENSION_SIZE : integer := 20;
  constant ADDR_WIDTH          : integer := 4;

  signal clk            : std_logic := '0';
  signal valid          : std_logic;
  signal rs1_data       : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal rs2_data       : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal instruction    : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
  signal sign_extension : std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0) := (others => '0');
  signal stall          : std_logic;
  signal data_out       : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_enable    : std_logic;

  signal address    : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal byte_en    : std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
  signal write_en   : std_logic;
  signal read_en    : std_logic;
  signal write_data : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal read_data  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal busy       : std_logic;

  signal we    : std_logic;
  signal be    : std_logic_vector (4 - 1 downto 0);
  signal wdata : std_logic_vector(32 - 1 downto 0);
  signal waddr : integer range 0 to 2 ** ADDR_WIDTH -1;
  signal raddr : integer range 0 to 2 ** ADDR_WIDTH - 1;
  signal q     : std_logic_vector(32-1 downto 0);

  signal source : integer := 0;
  signal base   : integer := 0;

begin
  -- instantiate the design-under-test
  ls_unit : component load_store_unit
    generic map (
      REGISTER_SIZE       => REGISTER_SIZE,
      SIGN_EXTENSION_SIZE => SIGN_EXTENSION_SIZE,
      INSTRUCTION_SIZE    => INSTRUCTION_SIZE)
    port map (
      clk            => clk,
      valid          => valid,
      rs1_data       => rs1_data,
      rs2_data       => rs2_data,
      instruction    => instruction,
      sign_extension => sign_extension,
      stall          => stall,
      data_out       => data_out,
      data_enable    => data_enable,
      address        => address,
      byte_en        => byte_en,
      write_en       => write_en,
      read_en        => read_en,
      write_data     => write_data,
      read_data      => read_data,
      busy           => busy);
  mem : component byte_enabled_simple_dual_port_ram
    generic map (
      ADDR_WIDTH => ADDR_WIDTH,
      BYTE_WIDTH => 8,
      BYTES      => 4)
    port map (
      clk   => clk,
      we    => write_en,
      be    => byte_en,
      wdata => write_data,
      waddr => waddr,
      raddr => raddr,
      q     => read_data);
  raddr <= to_integer(unsigned(address))/4;
  waddr <= to_integer(unsigned(address))/4;

  rs2_data <= std_logic_vector(to_unsigned(source, REGISTER_SIZE));
  rs1_data <= std_logic_vector(to_unsigned(base, REGISTER_SIZE));

  clk_proc : process
  begin
    clk <= not clk;
    wait for 1 ns;
  end process;

  process(clk)
    variable state : integer := 0;
  begin
    if rising_edge(clk) then
      case state is


        when 0 =>
          source      <= 16#7BCDEF12#;
          base        <= 0;
          valid       <= '1';
          instruction <= SW(1, 1, 0);
        when 1 =>
          source      <= 16#12#;
          instruction <= SB(1, 1, 7);
        when 2 =>
          source      <= 16#DEAB#;
          instruction <= SH(1, 1, 4);
          when 3 =>
          instruction <= LB(1,1,7);
        when 4 =>
          instruction <= LH(1,1,4);
        when 5 =>
          instruction <= LW( 1,1,0);
        when 6 =>
          instruction <= LHU(1,1,4);

        when others => null;
      end case;

      state := state + 1;

    end if;

  end process;

end rtl;
