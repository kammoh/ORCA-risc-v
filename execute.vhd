library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.components.all;

entity execute is
  generic(
    REGISTER_SIZE       : positive;
    REGISTER_NAME_SIZE  : positive;
    INSTRUCTION_SIZE    : positive;
    SIGN_EXTENSION_SIZE : positive);
  port(
    clk   : in std_logic;
    reset : in std_logic;

    pc_next     : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    pc_current  : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    instruction : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);

    rs1_data       : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    rs2_data       : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    sign_extension : in std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);

    wb_sel  : inout std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
    wb_data : inout std_logic_vector(REGISTER_SIZE-1 downto 0);
    wb_en   : inout std_logic;

    predict_corr    : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    predict_corr_en : out std_logic;

--memory-bus
    address    : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    byte_en    : out std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
    write_en   : out std_logic;
    read_en    : out std_logic;
    write_data : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    read_data  : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    busy       : in  std_logic);
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
  signal br_data_en   : std_logic;
  signal alu_data_en  : std_logic;
  signal ld_data_en   : std_logic;

  signal upp_data_en : std_logic;

  signal writeback_1hot : std_logic_vector(3 downto 0);

  signal bad_predict : std_logic;
  signal new_pc      : std_logic_vector(REGISTER_SIZE-1 downto 0);



  signal rs1_data_fwd : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal rs2_data_fwd : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal nreset          : std_logic;
  signal ls_unit_stalled : std_logic;

  constant ZERO : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) := (others => '0');

begin

  --use the previous clock's writeback data when appropriate

  rs1_data_fwd <= wb_data when wb_sel = rs1 and wb_en = '1'and wb_sel /= ZERO else rs1_data;
  rs2_data_fwd <= wb_data when wb_sel = rs2 and wb_en = '1'and wb_sel /= ZERO else rs2_data;
  nreset       <= not reset;
  alu : component arithmetic_unit
    generic map (
      INSTRUCTION_SIZE    => INSTRUCTION_SIZE,
      REGISTER_SIZE       => REGISTER_SIZE,
      SIGN_EXTENSION_SIZE => SIGN_EXTENSION_SIZE)
    port map (
      clk            => clk,
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
      rs1_data       => rs1_data_fwd,
      rs2_data       => rs2_data_fwd,
      current_pc     => pc_current,
      predicted_pc   => pc_next,
      instr          => instruction,
      sign_extension => sign_extension,
      data_out       => br_data_out,
      data_out_en    => br_data_en,
      new_pc         => new_pc,
      bad_predict    => bad_predict);

  ls_unit : component load_store_unit
    generic map(
      REGISTER_SIZE       => REGISTER_SIZE,
      SIGN_EXTENSION_SIZE => SIGN_EXTENSION_SIZE,
      INSTRUCTION_SIZE    => INSTRUCTION_SIZE)
    port map(
      clk            => clk,
      valid          => nreset,
      rs1_data       => rs1_data_fwd,
      rs2_data       => rs2_data_fwd,
      instruction    => instruction,
      sign_extension => sign_extension,
      stall          => ls_unit_stalled,
      data_out       => ld_data_out,
      data_enable    => ld_data_en,
      --memory bus
      address        => address,
      byte_en        => byte_en,
      write_en       => write_en,
      read_en        => read_en,
      write_data     => write_data,
      read_data      => read_data,
      busy           => busy);


  --the above components have output latches,
  --find out which is the actual output
  writeback_1hot(3) <= upp_data_en;
  writeback_1hot(2) <= alu_data_en;
  writeback_1hot(1) <= br_data_en;
  writeback_1hot(0) <= ld_data_en;

  with writeback_1hot select
    wb_data <=
    upp_data_out    when "1000",
    alu_data_out    when "0100",
    br_data_out     when "0010",
    ld_data_out     when "0001",
    (others => 'X') when others;

  wb_en           <= alu_data_en or br_data_en or ld_data_en or upp_data_en;
  predict_corr_en <= bad_predict;
  predict_corr    <= new_pc;

  --wb_sel needs to be latched as well
  wb_sel_proc : process(clk)
  begin
    if rising_edge(clk) then
      wb_sel <= rd;
    end if;
  end process;

  upper_imm : process (clk, reset) is
    variable opcode : std_logic_vector(6 downto 0);
    variable imm    : unsigned(REGISTER_SIZE-1 downto 0);

    constant LUI   : std_logic_vector(6 downto 0) := "0110111";
    constant AUIPC : std_logic_vector(6 downto 0) := "0010111";
  begin  -- process upper_imm


    if clk'event and clk = '1' then     -- rising clock edge
      if reset = '1' then               -- synchronous reset (active high)

      else
        opcode            := instruction(6 downto 0);
        imm(31 downto 12) := unsigned(instruction(31 downto 12));
        imm(11 downto 0)  := (others => '0');
        case opcode is
          when LUI =>
            upp_data_en  <= '1';
            upp_data_out <= std_logic_vector(imm);
          when AUIPC =>
            upp_data_en  <= '1';
            upp_data_out <= std_logic_vector(unsigned(pc_current) + imm);
          when others =>
            upp_data_en  <= '0';
            upp_data_out <= (others => 'X');
        end case;
      end if;  -- reset
    end if;  -- clk
  end process upper_imm;

end architecture;
