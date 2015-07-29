
library ieee;
use ieee.std_logic_1164.all;
use ieee.NUMERIC_STD.all;
entity riscv_tb is
end entity;

architecture rtl of riscv_tb is
  constant REGISTER_SIZE : integer := 32;

  component riscv is

    generic (
      REGISTER_SIZE        : integer;
      INSTRUCTION_MEM_SIZE : integer;
      DATA_MEMORY_SIZE     : integer);
    port(clk   : in std_logic;
         reset : in std_logic);
  end component;

  signal clk   : std_logic := '0';
  signal reset : std_logic := '1';
begin
  -- instantiate the design-under-test
  dut : component riscv
    generic map(REGISTER_SIZE        => REGISTER_SIZE,
                INSTRUCTION_MEM_SIZE => 256,
                DATA_MEMORY_SIZE     => 256)

    port map(clk   => clk,
             reset => reset);

  clk_proc : process
  begin
    clk <= '1';
    wait for 1 ns;
    clk <= '0';
    wait for 1 ns;
  end process;


  main_proc : process(clk)
    variable state : natural := 1;
  begin

    --hold in reset for a few cycles
    if clk'event and clk = '1' then
      case state is
        --reset
        when 1 to 2 =>
          reset <= '1';
        when 3 =>
          --end reset
          reset <= '0';
        when others => null;
      end case;
      state := state + 1;
    end if;


  end process;

end rtl;
