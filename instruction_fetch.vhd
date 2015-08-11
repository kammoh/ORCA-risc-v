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
    read_stalled   : in  std_logic
    );

end entity instruction_fetch;

architecture rtl of instruction_fetch is

  constant RESET_TARGET  : integer := 0;
  signal program_counter : std_logic_vector(REGISTER_SIZE -1 downto 0);

  signal instr        : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
  signal instr_be     : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
  signal valid_instr : std_logic;

  signal generated_pc : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal latched_pc   : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal stalled             : std_logic;
  signal instr_latched       : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
  signal latched_instr_valid : std_logic;

begin  -- architecture rtl

  stalled <= stall or read_stalled;

  program_counter <= pc_corr when pc_corr_en = '1' else  --branch prediction fail
                     latched_pc when stalled = '1' else  --stalled
                     generated_pc;      --regular operation


  read_address <= program_counter;
  read_en      <= not reset and (read_stalled or not stall);

  latch_pc : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        --if we subtract 4 from the target, we will get the target on the next
        --cycle
        latched_pc          <= std_logic_vector(to_signed(RESET_TARGET, REGISTER_SIZE));
        latched_instr_valid <= '0';
      else
        latched_pc <= program_counter;
        if read_datavalid = '1' then
          instr_latched <= read_data;
          if stalled = '1' then
            latched_instr_valid <= '1';
          else
            latched_instr_valid <= '0';
          end if;

        end if;
      end if;
    end if;
  end process;


  --choose latched or new instr
  instr_be <= read_data when read_datavalid = '1' else instr_latched;
  --unpack instruction
  instr <= (instr_be(7 downto 0) & instr_be(15 downto 8) &
            instr_be(23 downto 16) & instr_be(31 downto 24));
  valid_instr <= latched_instr_valid or read_datavalid ;
  pc_logic : component pc_incr
    generic map (
      REGISTER_SIZE    => REGISTER_SIZE,
      INSTRUCTION_SIZE => INSTRUCTION_SIZE)
    port map (
      pc      => latched_pc,
      instr   => instr,
      valid_instr => valid_instr,
      next_pc => generated_pc);


  instr_out       <= instr;
  pc_out          <= latched_pc;
  next_pc_out     <= generated_pc;

  valid_instr_out <= valid_instr;



end architecture rtl;
