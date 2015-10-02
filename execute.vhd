library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.std_logic_textio.all;          -- I/O for logic types

library work;
use work.rv_components.all;
library STD;
use STD.textio.all;                     -- basic I/O

entity execute is
  generic(
    REGISTER_SIZE       : positive;
    REGISTER_NAME_SIZE  : positive;
    INSTRUCTION_SIZE    : positive;
    SIGN_EXTENSION_SIZE : positive;
    RESET_VECTOR        : natural);
  port(
    clk         : in std_logic;
    reset       : in std_logic;
    valid_input : in std_logic;

    pc_next     : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    pc_current  : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    instruction : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);

    rs1_data       : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    rs2_data       : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    sign_extension : in std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);

    wb_sel  : buffer std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
    wb_data : buffer std_logic_vector(REGISTER_SIZE-1 downto 0);
    wb_en   : buffer std_logic;

    to_host   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    from_host : in  std_logic_vector(REGISTER_SIZE-1 downto 0);

    predict_corr    : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
    predict_corr_en : out    std_logic;
    stall_pipeline  : buffer std_logic;
--memory-bus
    address         : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
    byte_en         : out    std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
    write_en        : out    std_logic;
    read_en         : out    std_logic;
    write_data      : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
    read_data       : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    waitrequest     : in     std_logic;
    datavalid       : in     std_logic);
end;

architecture behavioural of execute is

  alias rd : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) is
    instruction(11 downto 7);
  alias rs1 : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) is
    instruction(19 downto 15);
  alias rs2 : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) is
    instruction(24 downto 20);


  -- various writeback sources
  signal br_data_out  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal alu_data_out : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal ld_data_out  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal upp_data_out : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal sys_data_out : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal br_data_en  : std_logic;
  signal alu_data_en : std_logic;
  signal ld_data_en  : std_logic;
  signal upp_data_en : std_logic;
  signal sys_data_en : std_logic;

  signal writeback_1hot : std_logic_vector(4 downto 0);

  signal br_bad_predict : std_logic;
  signal br_new_pc      : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal syscall_en     : std_logic;
  signal syscall_target : std_logic_vector(REGISTER_SIZE-1 downto 0);



  signal rs1_data_fwd : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal rs2_data_fwd : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal ls_valid            : std_logic;
  signal ls_unit_waiting     : std_logic;
  signal valid_input_latched : std_logic;

  signal wb_sel_latched  : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal wb_data_latched : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal wb_en_latched   : std_logic;


  constant ZERO : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) := (others => '0');

begin

  --use the previous clock's writeback data when appropriate

  rs1_data_fwd <= wb_data_latched when wb_sel_latched = rs1 and wb_en_latched = '1'and wb_sel_latched /= ZERO else
                  wb_data when wb_sel = rs1 and wb_en = '1'and wb_sel /= ZERO else rs1_data;
  rs2_data_fwd <= wb_data_latched when wb_sel_latched = rs2 and wb_en_latched = '1'and wb_sel_latched /= ZERO else
                  wb_data when wb_sel = rs2 and wb_en = '1'and wb_sel /= ZERO else rs2_data;


  ls_valid <= valid_input and not reset;

  alu : component arithmetic_unit
    generic map (
      INSTRUCTION_SIZE    => INSTRUCTION_SIZE,
      REGISTER_SIZE       => REGISTER_SIZE,
      SIGN_EXTENSION_SIZE => SIGN_EXTENSION_SIZE)
    port map (
      clk            => clk,
      stall          => stall_pipeline,
      valid          => valid_input,
      rs1_data       => rs1_data_fwd,
      rs2_data       => rs2_data_fwd,
      instruction    => instruction,
      sign_extension => sign_extension,
      data_out       => alu_data_out,
      data_enable    => alu_data_en);


  branch : component branch_unit
    generic map (
      REGISTER_SIZE       => REGISTER_SIZE,
      INSTRUCTION_SIZE    => INSTRUCTION_SIZE,
      SIGN_EXTENSION_SIZE => SIGN_EXTENSION_SIZE)
    port map(
      clk            => clk,
      reset          => reset,
      stall          => stall_pipeline,
      rs1_data       => rs1_data_fwd,
      rs2_data       => rs2_data_fwd,
      current_pc     => pc_current,
      predicted_pc   => pc_next,
      instr          => instruction,
      sign_extension => sign_extension,
      data_out       => br_data_out,
      data_out_en    => br_data_en,
      new_pc         => br_new_pc,
      bad_predict    => br_bad_predict);

  ls_unit : component load_store_unit
    generic map(
      REGISTER_SIZE       => REGISTER_SIZE,
      SIGN_EXTENSION_SIZE => SIGN_EXTENSION_SIZE,
      INSTRUCTION_SIZE    => INSTRUCTION_SIZE)
    port map(
      clk            => clk,
      reset          => reset,
      valid          => ls_valid,
      rs1_data       => rs1_data_fwd,
      rs2_data       => rs2_data_fwd,
      instruction    => instruction,
      sign_extension => sign_extension,
      waiting        => ls_unit_waiting,
      data_out       => ld_data_out,
      data_enable    => ld_data_en,
      --memory bus
      address        => address,
      byte_en        => byte_en,
      write_en       => write_en,
      read_en        => read_en,
      write_data     => write_data,
      read_data      => read_data,
      waitrequest    => waitrequest,
      readvalid      => datavalid);

  syscall : component system_calls
    generic map (
      REGISTER_SIZE    => REGISTER_SIZE,
      INSTRUCTION_SIZE => INSTRUCTION_SIZE,
      RESET_VECTOR     => RESET_VECTOR)
    port map (
      clk            => clk,
      reset          => reset,
      valid          => valid_input,
      rs1_data       => rs1_data_fwd,
      instruction    => instruction,
      finished_instr => '0',
      wb_data        => sys_data_out,
      wb_en          => sys_data_en,
      to_host        => to_host,
      from_host      => from_host,

      current_pc    => pc_current,
      pc_correction => syscall_target,
      pc_corr_en    => syscall_en);

  uppimm : component upper_immediate
    generic map (
      REGISTER_SIZE    => REGISTER_SIZE,
      INSTRUCTION_SIZE => INSTRUCTION_SIZE)
    port map (
      clk        => clk,
      valid      => valid_input,
      instr      => instruction,
      pc_current => pc_current,
      data_out   => upp_data_out,
      data_en    => upp_data_en);

  stall_pipeline <= ls_unit_waiting;

  --the above rv_components have output latches,
  --find out which is the actual output
  writeback_1hot(4) <= sys_data_en;
  writeback_1hot(3) <= upp_data_en;
  writeback_1hot(2) <= alu_data_en;
  writeback_1hot(1) <= br_data_en;
  writeback_1hot(0) <= ld_data_en;

  --with writeback_1hot select
  --  wb_data <=
  --  sys_data_out    when "10000",
  --  upp_data_out    when "01000",
  --  alu_data_out    when "00100",
  --  br_data_out     when "00010",
  --  ld_data_out     when "00001",
  --  (others => 'X') when others;

  wb_data <= sys_data_out when sys_data_en = '1' else
             upp_data_out when upp_data_en = '1' else
             alu_data_out when alu_data_en = '1' else
             br_data_out  when br_data_en = '1' else
             ld_data_out;
--  wb_data <= alu_data_out;
  wb_en <= alu_data_en or br_data_en or ld_data_en or upp_data_en or sys_data_en;

  predict_corr_en <= (syscall_en or br_bad_predict) and valid_input_latched;

  predict_corr <= br_new_pc when br_bad_predict = '1' else syscall_target;

--wb_sel needs to be latched as well
  wb_sel_proc : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        wb_en_latched       <= '0';
        valid_input_latched <= '0';
      else
        valid_input_latched <= valid_input;
        wb_sel              <= rd;
        if stall_pipeline = '1' and wb_en_latched = '0' then
          --first stall cycle
          wb_en_latched   <= wb_en;
          wb_data_latched <= wb_data;
          wb_sel_latched  <= wb_sel;
        elsif stall_pipeline = '0' then
          --pipeline not stalling
          wb_en_latched <= '0';
        end if;

      end if;  --reset
    end if;  --clk
  end process;

  --my_print : process(clk)
  --  variable my_line : line;            -- type 'line' comes from textio
  --begin
  --  if rising_edge(clk) then
  --    if valid_input = '1' then
  --      write(my_line, string'("executing pc = "));  -- formatting
  --      hwrite(my_line, (pc_current));  -- format type std_logic_vector as hex
  --      write(my_line, string'(" instr =  "));       -- formatting
  --      hwrite(my_line, (instruction));  -- format type std_logic_vector as hex
  --      if ls_unit_waiting = '1' then
  --        write(my_line, string'(" stalling"));      -- formatting
  --      end if;
  --      writeline(output, my_line);     -- write to "output"
  --    else
  --      write(my_line, string'("bubble"));  -- formatting
  --      writeline(output, my_line);     -- write to "output"
  --    end if;

  --  end if;
  --end process my_print;

end architecture;
