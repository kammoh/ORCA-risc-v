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
    clk   : in std_logic;
    reset : in std_logic;
    stall : in std_logic;

    flush       : in std_logic;
    instruction : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    valid_input : in std_logic;
    --writeback signals
    wb_sel      : in std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
    wb_data     : in std_logic_vector(REGISTER_SIZE -1 downto 0);
    wb_enable   : in std_logic;

    --output signals
    stall_out      : out std_logic;
    rs1_data       : out std_logic_vector(REGISTER_SIZE -1 downto 0);
    rs2_data       : out std_logic_vector(REGISTER_SIZE -1 downto 0);
    sign_extension : out std_logic_vector(SIGN_EXTENSION_SIZE -1 downto 0);
    --inputs just for carrying to next pipeline stage
    br_taken_in    : in  std_logic;
    pc_curr_in     : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    br_taken_out   : out std_logic;
    pc_curr_out    : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    instr_out      : out std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    subseq_instr   : out std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    valid_output   : out std_logic);


end;

architecture behavioural of decode is

  signal rs1 : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal rs2 : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);

  signal br_taken_latch : std_logic;
  signal pc_next_latch  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal pc_curr_latch  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal instr_latch    : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
  signal valid_latch    : std_logic;

  signal use_after_load_stall1 : std_logic;
  signal use_after_load_stall2 : std_logic;
  signal use_after_load_stall  : std_logic;

  signal i_rd  : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal i_rs1 : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal i_rs2 : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);

  signal il_rd     : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal il_rs1    : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal il_rs2    : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal il_opcode : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);


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
  rs1 <= instruction(19 downto 15) when stall = '0' else instr_latch(19 downto 15);
  rs2 <= instruction(24 downto 20) when stall = '0' else instr_latch(24 downto 20);

  il_rd     <= instr_latch(11 downto 7);
  il_opcode <= instr_latch(6 downto 2);
  i_rs1     <= instruction(19 downto 15);
  i_rs2     <= instruction(24 downto 20);

  use_after_load_stall1 <=  '1' when i_rs1 = il_rd and il_opcode = "00000"
                           else '0';
  use_after_load_stall2 <= '1' when i_rs2 = il_rd and il_opcode = "00000"
                           else '0';
  use_after_load_stall <= (use_after_load_stall1 or use_after_load_stall2) and valid_latch and not flush ;

  stall_out <= use_after_load_stall;

  decode_stage : process (clk, reset) is
  begin  -- process decode_stage
    if rising_edge(clk) then            -- rising clock edge
      if reset = '1' or flush = '1' then
        valid_output <= '0';
        valid_latch  <= '0';
      else
        if not stall = '1' then
          sign_extension <= std_logic_vector(
            resize(signed(instr_latch(INSTRUCTION_SIZE-1 downto INSTRUCTION_SIZE-1)),
                   SIGN_EXTENSION_SIZE));


          br_taken_latch <= br_taken_in;
          PC_curr_latch  <= PC_curr_in;
          instr_latch    <= instruction;
          valid_latch    <= valid_input and not use_after_load_stall;

          br_taken_out <= br_taken_latch;
          pc_curr_out  <= PC_curr_latch;
          instr_out    <= instr_latch;
          valid_output <= valid_latch;



        end if;
      end if;
    end if;
  end process decode_stage;
  subseq_instr <= instr_latch;
end architecture;
