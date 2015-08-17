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
    clk   : in std_logic;
    reset : in std_logic;
    stall : in std_logic;

    pc_corr    : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    pc_corr_en : in std_logic;

    instr_out       : out std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    pc_out          : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    next_pc_out     : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    valid_instr_out : out std_logic;

    read_address   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    read_en        : out std_logic;
    read_data      : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    read_datavalid : in  std_logic;
    read_wait      : in  std_logic
    );

end entity instruction_fetch;

architecture rtl of instruction_fetch is

  constant RESET_TARGET  : integer := 16#00002000#;
--constant RESET_TARGET  : integer := 16#ffff2000#;
  signal program_counter : std_logic_vector(REGISTER_SIZE -1 downto 0);

  signal instr       : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
  signal instr_be    : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
  signal valid_instr : std_logic;

  signal generated_pc : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal latched_pc   : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal stalled : std_logic;

begin  -- architecture rtl

  stalled <= stall or read_wait;

  program_counter <= latched_pc when stalled = '1' else  --stalled
                     pc_corr when pc_corr_en = '1' else  --branch prediction fail
                     generated_pc;      --regular operation


  read_address <= program_counter;
  read_en      <= not reset;

  latch_pc : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        --if we subtract 4 from the target, we will get the target on the next
        --cycle
        latched_pc <= std_logic_vector(to_signed(RESET_TARGET, REGISTER_SIZE));
      else
        latched_pc <= program_counter;
      end if;
    end if;
  end process;



  instr_be <= read_data ;
  --unpack instruction
  instr <= (instr_be(7 downto 0) & instr_be(15 downto 8) &
            instr_be(23 downto 16) & instr_be(31 downto 24));

  valid_instr <= read_datavalid;

  pc_logic : component pc_incr
    generic map (
      REGISTER_SIZE    => REGISTER_SIZE,
      INSTRUCTION_SIZE => INSTRUCTION_SIZE)
    port map (
      pc          => latched_pc,
      instr       => instr,
      valid_instr => valid_instr,
      next_pc     => generated_pc);


  instr_out   <= instr;
  pc_out      <= latched_pc;
  next_pc_out <= generated_pc;

  valid_instr_out <= valid_instr;



end architecture rtl;
