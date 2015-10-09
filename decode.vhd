library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.rv_components.all;

entity decode is
  generic(
    REGISTER_SIZE       : positive;
    REGISTER_NAME_SIZE  : positive;
    INSTRUCTION_SIZE    : positive;
    SIGN_EXTENSION_SIZE : positive);
  port(
    clk         : in std_logic;
    reset       : in std_logic;
    stall       : in std_logic;
    instruction : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    valid_input : in std_logic;
    --writeback signals
    wb_sel      : in std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
    wb_data     : in std_logic_vector(REGISTER_SIZE -1 downto 0);
    wb_enable   : in std_logic;

    --output signals
    rs1_data       : out std_logic_vector(REGISTER_SIZE -1 downto 0);
    rs2_data       : out std_logic_vector(REGISTER_SIZE -1 downto 0);
    sign_extension : out std_logic_vector(SIGN_EXTENSION_SIZE -1 downto 0);
    --inputs just for carrying to next pipeline stage
    pc_next_in     : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    pc_curr_in     : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    instr_in       : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    pc_next_out    : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    pc_curr_out    : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    instr_out      : out std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    stall_out      : out std_logic;
    valid_output   : out std_logic);


end;

architecture behavioural of decode is

  alias rd : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) is
    instruction(11 downto 7);
  alias rs1 : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) is
    instruction(19 downto 15);
  alias rs2 : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) is
    instruction(24 downto 20);
  alias opcode : std_logic_vector(6 downto 0) is
    instruction(6 downto 0);

  constant LOAD : std_logic_vector(6 downto 0)                    := "0000011";
  constant ZERO : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) := (others => '0');

  signal load_dest       : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal load_dest_valid : boolean;
  signal stall_o         : std_logic;
  signal valid_latched   : std_logic;
begin
  register_file_1 : component register_file
    generic map (
      REGISTER_SIZE      => REGISTER_SIZE,
      REGISTER_NAME_SIZE => REGISTER_NAME_SIZE)
    port map(
      clk              => clk,
      stall            => stall,
      valid_input      => valid_input,
      rs1_sel          => rs1,
      rs2_sel          => rs2,
      writeback_sel    => wb_sel,
      writeback_data   => wb_data,
      writeback_enable => wb_enable,
      rs1_data         => rs1_data,
      rs2_data         => rs2_data
      );

  stall_o      <= valid_input when (rs1 = load_dest or rs2 = load_dest) and load_dest_valid else '0';

  stall_out    <= stall_o;
--  valid_output <= valid_latched and not stall_o;
  decode_stage : process (clk, reset) is
  begin  -- process decode_stage
    if rising_edge(clk) then            -- rising clock edge
      if reset = '1' then
        sign_extension  <= (others => '0');
        pc_next_out     <= (others => '0');
        pc_curr_out     <= (others => '0');
        instr_out       <= (others => '0');
        valid_output   <= '0';
        load_dest_valid <= false;
      else
        if stall = '0' then
          --if this is a load, remeber so that we can insert a stall
          --if rd is used in next instruction
          if opcode = LOAD and rd /= ZERO and valid_input = '1' then
            load_dest_valid <= true;
          else
            load_dest_valid <= false;
          end if;
          load_dest <= rd;
          sign_extension <= std_logic_vector(
            resize(signed(instruction(INSTRUCTION_SIZE-1 downto INSTRUCTION_SIZE-1)),
                   SIGN_EXTENSION_SIZE));
          pc_next_out   <= PC_next_in;
          pc_curr_out   <= PC_curr_in;
          instr_out     <= instruction;
          valid_output <= valid_input and not stall_o;
        end if;

      end if;
    end if;
  end process decode_stage;

end architecture;
