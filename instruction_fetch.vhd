library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.instructions.all;
use work.components.all;

entity instruction_fetch is
  generic (
    REGISTER_SIZE    : positive;
    INSTRUCTION_SIZE : positive);
  port (
    clk        : in std_logic;
    reset      : in std_logic;
    pc_corr    : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    pc_corr_en : in std_logic;

    instr_out       : out std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    pc_out          : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    next_pc_out     : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    valid_instr_out : out std_logic;

    instr_address : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    instr_in      : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    instr_busy    : in  std_logic
    );

end entity instruction_fetch;

architecture rtl of instruction_fetch is

  constant RESET_TARGET  : integer := 0;
  signal program_counter : std_logic_vector(REGISTER_SIZE -1 downto 0);

  signal instr : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);

  signal generated_pc : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal latched_pc   : std_logic_vector(REGISTER_SIZE-1 downto 0);
begin  -- architecture rtl


  program_counter <= pc_corr when pc_corr_en = '1' else  --branch prediction fail
                     latched_pc when instr_busy = '1'  else     --stalled instr fetch
                     generated_pc;      --regular operation

  instr_address <= program_counter;

  latch_pc : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        --if we subtract 4 from the target, we will get the target on the next
        --cycle
        latched_pc <= std_logic_vector(to_signed(RESET_TARGET -4, REGISTER_SIZE));
        valid_instr_out <= '0';
      else
        latched_pc <= program_counter;
        valid_instr_out <= not instr_busy;
      end if;
    end if;
  end process;

  --unpack the instructions
  instr <= instr_in(7 downto 0) & instr_in(15 downto 8) &
           instr_in(23 downto 16) & instr_in(31 downto 24);
  pc_logic : component pc_incr
    generic map (
      REGISTER_SIZE    => REGISTER_SIZE,
      INSTRUCTION_SIZE => INSTRUCTION_SIZE)
    port map (
      pc      => latched_pc,
      instr   => instr,
      next_pc => generated_pc);

  instr_out   <= instr;
  pc_out      <= latched_pc;
  next_pc_out <= generated_pc;




end architecture rtl;
