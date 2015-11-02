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

    pc_next      : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    pc_current   : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    instruction  : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    subseq_instr : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);

    rs1_data       : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    rs2_data       : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    sign_extension : in std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);

    wb_sel  : buffer std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
    wb_data : buffer std_logic_vector(REGISTER_SIZE-1 downto 0);
    wb_en   : buffer std_logic;

    to_host   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    from_host : in  std_logic_vector(REGISTER_SIZE-1 downto 0);

    predict_corr    : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
    predict_corr_en : buffer std_logic;
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
  alias opcode : std_logic_vector(4 downto 0) is
    instruction(6 downto 2);

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

  signal wb_mux : std_logic_vector(1 downto 0);


  signal br_bad_predict : std_logic;
  signal br_new_pc      : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal syscall_en     : std_logic;
  signal syscall_target : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal rs1_data_fwd : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal rs2_data_fwd : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal ls_unit_waiting       : std_logic;
  signal use_after_load_stall1 : std_logic;
  signal use_after_load_stall2 : std_logic;
  signal use_after_load_stall  : std_logic;

  signal fwd_sel  : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal fwd_data : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal fwd_en   : std_logic;
  signal fwd_mux  : std_logic;


  signal ls_valid_in  : std_logic;
  signal ld_latch_en  : std_logic;
  signal ld_latch_out : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal ld_rd        : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal rd_latch     : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);

  constant ZERO : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) := (others => '0');

  signal rs1_mux : std_logic_vector(1 downto 0);
  signal rs2_mux : std_logic_vector(1 downto 0);

  signal finished_instr : std_logic;

  constant LUI_OP   : std_logic_vector(4 downto 0) := "01101";
  constant AUIPC_OP : std_logic_vector(4 downto 0) := "00101";
  constant ALU_OP   : std_logic_vector(4 downto 0) := "01100";
  constant ALUI_OP  : std_logic_vector(4 downto 0) := "00100";
  constant CSR_OP   : std_logic_vector(4 downto 0) := "11100";
begin


  with rs1_mux select
    rs1_data_fwd <=
    fwd_data     when "00",
    ld_latch_out when "01",
    rs1_data     when others;
  with rs2_mux select
    rs2_data_fwd <=
    fwd_data     when "00",
    ld_latch_out when "01",
    rs2_data     when others;


  wb_mux <= "00" when sys_data_en = '1' else
            "01" when ld_data_en = '1' else
            "10" when br_data_en = '1' else
            "11";                       --when alu_data_en = '1'
  with wb_mux select
    wb_data <=
    sys_data_out when "00",
    ld_data_out  when "01",
    br_data_out  when "10",
    alu_data_out when others;

  wb_en  <= sys_data_en or ld_data_en or br_data_en or alu_data_en when wb_sel /= ZERO else '0';
  wb_sel <= rd_latch;

  --never forward from jal (always flush pipe)
  --never forward directly from ld_data (use register)
  fwd_data <= sys_data_out when sys_data_en = '1' else alu_data_out;

  use_after_load_stall1 <= ld_data_en when rd_latch = rs1 else '0';
  use_after_load_stall2 <= ld_data_en when rd_latch = rs2 else '0';
  use_after_load_stall  <= use_after_load_stall1 or use_after_load_stall2;

  stall_pipeline <= ls_unit_waiting or use_after_load_stall;

  process(clk)
    variable next_instr  : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    variable current_alu : boolean;
    alias ni_rs1         : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) is subseq_instr(19 downto 15);
    alias ni_rs2         : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) is subseq_instr(24 downto 20);
  begin
    if rising_edge(clk) then

      current_alu := (opcode = LUI_OP or
                      opcode = AUIPC_OP or
                      opcode = ALU_OP or
                      opcode = ALUI_OP or
                      opcode = CSR_OP) ;

      --calculate where the next forward data will go
      if use_after_load_stall1 = '1' then
        rs1_mux <= "01";
      elsif stall_pipeline = '0' then
        if current_alu and rd = ni_rs1 and rd /= ZERO and valid_input = '1' then
          rs1_mux <= "00";
        elsif ld_data_en = '1' and rd_latch = ni_rs1 and rd_latch /= ZERO then
          rs1_mux <= "01";
        else
          rs1_mux <= "11";
        end if;
      end if;

      if use_after_load_stall2 = '1' then
        rs2_mux <= "01";
      elsif stall_pipeline = '0' then
        if current_alu and rd = ni_rs2 and rd /= ZERO and valid_input = '1' then
          rs2_mux <= "00";
        elsif ld_data_en = '1' and rd_latch = ni_rs2 and rd_latch /= ZERO then
          rs2_mux <= "01";
        else
          rs2_mux <= "11";
        end if;
      end if;

      if ls_unit_waiting = '0' then
        ld_latch_out <= ld_data_out;
      end if;

      --save various flip flops for forwarding
      --and writeback
      if ls_unit_waiting = '0' then
        rd_latch <= rd;
      end if;

      if rd_latch /= ZERO then
        ld_latch_en <= ld_data_en;
      else
        ld_latch_en <= '0';
      end if;
      ld_rd <= rd_latch;


      if reset = '1' then
        ld_latch_en <= '0';
      end if;
    end if;
  end process;

  alu : component arithmetic_unit
    generic map (
      INSTRUCTION_SIZE    => INSTRUCTION_SIZE,
      REGISTER_SIZE       => REGISTER_SIZE,
      SIGN_EXTENSION_SIZE => SIGN_EXTENSION_SIZE)
    port map (
      clk             => clk,
      stall           => stall_pipeline,
      valid           => valid_input,
      rs1_data        => rs1_data_fwd,
      rs2_data        => rs2_data_fwd,
      instruction     => instruction,
      sign_extension  => sign_extension,
      program_counter => pc_current,
      data_out        => alu_data_out,
      data_enable     => alu_data_en);


  branch : entity work.branch_unit(latch_middle)
    generic map (
      REGISTER_SIZE       => REGISTER_SIZE,
      INSTRUCTION_SIZE    => INSTRUCTION_SIZE,
      SIGN_EXTENSION_SIZE => SIGN_EXTENSION_SIZE)
    port map(
      clk            => clk,
      reset          => reset,
      valid          => valid_input,
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
  ls_valid_in <= valid_input and not use_after_load_stall;
  ls_unit : component load_store_unit
    generic map(
      REGISTER_SIZE       => REGISTER_SIZE,
      SIGN_EXTENSION_SIZE => SIGN_EXTENSION_SIZE,
      INSTRUCTION_SIZE    => INSTRUCTION_SIZE)
    port map(
      clk            => clk,
      reset          => reset,
      valid          => ls_valid_in,
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
  process(clk)
  begin
--create delayed versions
  end process;

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
      finished_instr => finished_instr,
      wb_data        => sys_data_out,
      wb_en          => sys_data_en,
      to_host        => to_host,
      from_host      => from_host,

      current_pc    => pc_current,
      next_pc       => pc_next,
      pc_correction => syscall_target,
      pc_corr_en    => syscall_en,

      use_after_load_stall => use_after_load_stall,
      load_stall           => ls_unit_waiting,
      predict_corr         => predict_corr_en
      );


  finished_instr <= valid_input and not stall_pipeline;

  predict_corr_en <= syscall_en or br_bad_predict;
  predict_corr    <= br_new_pc when br_bad_predict = '1' else syscall_target;

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
--    --write(my_line, string'("bubble"));  -- formatting
--    --writeline(output, my_line);     -- write to "output"
--    end if;
--  end if;
--end process my_print;

end architecture;
