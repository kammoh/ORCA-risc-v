library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.rv_components.all;

entity instruction_fetch is
  generic (
    REGISTER_SIZE    : positive;
    INSTRUCTION_SIZE : positive;
    RESET_VECTOR     : natural);
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

  signal correction      : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal correction_en   : std_logic;
  signal program_counter : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal generated_pc    : std_logic_vector(REGISTER_SIZE -1 downto 0);
  signal address         : std_logic_vector(REGISTER_SIZE -1 downto 0);

  signal instr : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);

  signal valid_instr : std_logic;

  signal saved_instr_out       : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
  signal saved_pc_out          : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal saved_next_pc_out     : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal saved_valid_instr_out : std_logic;


begin  -- architecture rtl



  assert program_counter(1 downto 0) = "00" report "BAD INSTRUCTION ADDRESS" severity error;

  read_en <= not reset;

  latch_pc : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        program_counter <= std_logic_vector(to_signed(RESET_VECTOR, REGISTER_SIZE));
        correction_en   <= '0';
      else
        if pc_corr_en = '1' then
          correction_en <= '1';
          correction    <= pc_corr;
        elsif read_datavalid = '1' then
          correction_en <= '0';
        end if;
        program_counter <= address;
      end if;
    end if;  -- clock
  end process;

  address <= program_counter when read_datavalid = '0' or stall = '1' else
             correction when correction_en = '1' else
             generated_pc;


--unpack instruction
  instr <= read_data;

  valid_instr <= read_datavalid and not correction_en and not stall;

  pc_logic : component pc_incr
    generic map (
      REGISTER_SIZE    => REGISTER_SIZE,
      INSTRUCTION_SIZE => INSTRUCTION_SIZE)
    port map (
      pc          => program_counter,
      instr       => instr,
      valid_instr => valid_instr,
      next_pc     => generated_pc);


  instr_out   <=  instr;
  pc_out      <=  program_counter;
  next_pc_out <=  generated_pc;

  valid_instr_out <= saved_valid_instr_out when stall = '1' else valid_instr;

  read_address <= address;

  process(clk)
  begin
    if rising_edge(clk) then
      if stall = '0' then
        saved_instr_out       <= instr;
        saved_pc_out          <= program_counter;
        saved_next_pc_out     <= generated_pc;
        saved_valid_instr_out <= valid_instr;
      end if;
    end if;
  end process;
end architecture rtl;
