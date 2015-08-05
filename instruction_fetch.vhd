library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library riscv;
use riscv.instructions.all;
use riscv.components.all;

entity instruction_fetch is
  generic (
    REGISTER_SIZE        : positive;
    INSTRUCTION_SIZE     : positive;
    INSTRUCTION_MEM_SIZE : positive);
  port (
    clk        : in std_logic;
    reset      : in std_logic;
    pc_corr    : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    pc_corr_en : in std_logic;

    instr_out   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    pc_out      : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    next_pc_out : out std_logic_vector(REGISTER_SIZE-1 downto 0));

end entity instruction_fetch;

architecture rtl of instruction_fetch is

  signal program_counter : std_logic_vector(REGISTER_SIZE -1 downto 0);

  type memory_type is array(0 to INSTRUCTION_MEM_SIZE)
    of std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal memory : memory_type := (
    ADDI(1, 0, 16#6a#),                 --j      0x0
    SB(1, 0, 10),                       --       0x4
    ADDI(2, 0, 16#6f#),                 --o      0x8
    SB(2, 0, 11),                       --       0xC
    ADDI(3, 0, 16#65#),                 --e      0x10
    SB(3, 0, 12),                       --       0x14
    ADDI(4, 0, 16#6c#),                 --l      0x18
    SB(4, 0, 13),                       --       0x1C
    SB(0, 0, 14),                       --       0x20
    ADDI(1, 0, 10),                     --       0x24
    LB(2, 1, 0),                        --       0x28
    ADDI(3, 2, -32),                    --       0x2C
    SB(3, 1, 10),                       --       0x30
    ADDI(1, 1, 1),                      --       0x34
    BNE(2, 0, -16),                     --       0x38
    NOP(0),
    JAL(0,0),                         --infinite loop
    others => NOP(0));

  signal instr : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);

  signal generated_pc : std_logic_vector(REGISTER_SIZE-1 downto 0);

begin  -- architecture rtl


  instr_memory : process(clk, reset)
    variable pc : unsigned(31 downto 0);
  begin
    if clk'event and clk = '1' then
      if reset = '1' then
        program_counter(1 downto 0)               <= "00";
        program_counter(REGISTER_SIZE-1 downto 2) <= (others => '1');

        instr <= (others => '0');
      else
        if pc_corr_en = '1' then
          pc := unsigned(pc_corr);
        else
          pc := unsigned(generated_pc);
        end if;
        instr           <= memory(to_integer("00"&pc(31 downto 2)));
        program_counter <= std_logic_vector(pc);
        pc_out          <= std_logic_vector(pc);
      end if;  -- reset


    end if;  --clock
  end process instr_memory;

  pc_logic : component pc_incr
    generic map (
      REGISTER_SIZE    => REGISTER_SIZE,
      INSTRUCTION_SIZE => INSTRUCTION_SIZE)
    port map (
      pc      => program_counter,
      instr   => instr,
      next_pc => generated_pc);

  instr_out   <= instr;
  next_pc_out <= generated_pc;




end architecture rtl;
