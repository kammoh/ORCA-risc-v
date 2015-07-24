library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity decode_execute is
  generic(
    REGISTER_SIZE      : positive;
    REGISTER_NAME_SIZE : positive;
    INSTRUCTION_SIZE   : positive);
  port(
    clk         : in std_logic;
    reset       : in std_logic;
    PC_next     : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    PC_current  : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    instruction : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    valid_input : in std_logic;
    wb_sel_in   : in std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
    wb_data_in  : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    wb_en_in    : in std_logic;


    wb_sel_out            : out std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
    wb_data_out           : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    wb_en_out             : out std_logic;
    predict_corr          : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    predict_corr_en       : out std_logic;
    stall_previous_stages : out std_logic);
end;

architecture behavioural of decode_execute is

  alias rd : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) is
    instruction(11 downto 6);
  alias rs1 : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) is
    instruction(19 downto 15);
  alias rs2 : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) is
    instruction(24 downto 20);

  constant SHORTEST_IMMEDIATE  : integer := 12;
  constant SIGN_EXTENSION_SIZE : integer := REGISTER_SIZE -INSTRUCTION_SIZE + (REGISTER_SIZE -SHORTEST_IMMEDIATE);
  signal sign_extension        : std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);

  -- read register values
  signal rs1_data : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal rs2_data : std_logic_vector(REGISTER_SIZE-1 downto 0);

  -- various writeback sources
  signal br_data_out  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal alu_data_out : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal ld_data_out  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal br_data_en   : std_logic;
  signal alu_data_en  : std_logic;
  signal ld_data_en   : std_logic;

  signal bad_predict : std_logic;
  signal new_pc      : std_logic_vector(REGISTER_SIZE-1 downto 0);

  component register_file
    generic(
      REGISTER_SIZE      : positive;
      REGISTER_NAME_SIZE : positive);
    port(
      clk              : in  std_logic;
      rs1_sel          : in  std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
      rs2_sel          : in  std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
      writeback_sel    : in  std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
      writeback_data   : in  std_logic_vector(REGISTER_SIZE -1 downto 0);
      writeback_enable : in  std_logic;
      rs1_data         : out std_logic_vector(REGISTER_SIZE -1 downto 0);
      rs2_data         : out std_logic_vector(REGISTER_SIZE -1 downto 0));
  end component;

  component arithmetic_unit is
    generic (
      INSTRUCTION_SIZE    : integer;
      REGISTER_SIZE       : integer;
      SIGN_EXTENSION_SIZE : integer);
    port (
      rs1_data       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      rs2_data       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      instruction    : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      sign_extension : in  std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
      data_out       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_enable    : out std_logic);
  end component arithmetic_unit;

  component branch_unit is
    generic (
      REGISTER_SIZE       : integer;
      INSTRUCTION_SIZE    : integer;
      SIGN_EXTENSION_SIZE : integer);
    port (
      rs1_data       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      rs2_data       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      current_pc     : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      predicted_pc   : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      instr          : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      sign_extension : in  std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
      data_out       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_out_en    : out std_logic;
      new_pc         : out std_logic_vector(REGISTER_SIZE-1 downto 0);  --next pc
      bad_predict    : out std_logic
      );
  end component branch_unit;

  component load_store_unit is
    generic (
      REGISTER_SIZE       : integer;
      SIGN_EXTENSION_SIZE : integer;
      INSTRUCTION_SIZE    : integer;
      MEMORY_SIZE_BYTES   : integer);
    port (
      clk            : in  std_logic;
      valid          : in  std_logic;
      rs1_data       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      rs2_data       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      instruction    : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      sign_extension : in  std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
      data_out       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_enable    : out std_logic
      );
  end component load_store_unit;

begin
  register_file_1 : component register_file
    generic map (
      REGISTER_SIZE      => REGISTER_SIZE,
      REGISTER_NAME_SIZE => REGISTER_NAME_SIZE)
    port map(
      clk              => clk,
      rs1_sel          => rs1,
      rs2_sel          => rs1,
      writeback_sel    => wb_sel_in,
      writeback_data   => wb_data_in,
      writeback_enable => wb_en_in,
      rs1_data         => rs1_data,
      rs2_data         => rs2_data
      );

  s_ext : for I in 0 to sign_extension'length generate
    sign_extension(i) <= instruction(instruction'left);
  end generate;


  alu : component arithmetic_unit
    generic map (
      INSTRUCTION_SIZE    => INSTRUCTION_SIZE,
      REGISTER_SIZE       => REGISTER_SIZE,
      SIGN_EXTENSION_SIZE => SIGN_EXTENSION_SIZE)
    port map (
      rs1_data       => rs1_data,
      rs2_data       => rs2_data,
      instruction    => instruction,
      sign_extension => sign_extension,
      data_out       => alu_data_out,
      data_enable    => alu_data_en);


  branch : component branch_unit
    generic map (REGISTER_SIZE       => REGISTER_SIZE,
                 INSTRUCTION_SIZE    => INSTRUCTION_SIZE,
                 SIGN_EXTENSION_SIZE => SIGN_EXTENSION_SIZE)
    port map(rs1_data       => rs1_data,
             rs2_data       => rs2_data,
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
      INSTRUCTION_SIZE    => INSTRUCTION_SIZE,
      MEMORY_SIZE_BYTES   => 1024)

    port map(
      clk            => clk,
      valid          => valid_input,
      rs1_data       => rs1_data,
      rs2_data       => rs2_data,
      instruction    => instruction,
      sign_extension => sign_extension,
      data_out       => ld_data_out,
      data_enable    => ld_data_en);

  coalesce : process (clk, reset) is
  begin  -- process coalesce
    if clk'event and clk = '1' then     -- rising clock edge
      if reset = '1' then               -- synchronous reset (active high)
        wb_data_out <= (others => 'X');
        wb_en_out   <= '0';
      else
        --default data_out to don't care
        wb_data_out           <= (others => 'X');
        wb_en_out             <= '0';
        stall_previous_stages <= '0';

        if alu_data_en = '1' then
          wb_en_out   <= '1';
          wb_data_out <= alu_data_out;
        elsif br_data_en = '1' then
          wb_en_out   <= '1';
          wb_data_out <= br_data_out;
        elsif ld_data_en = '1' then
          wb_en_out   <= '1';
          wb_data_out <= ld_data_out;
        end if;  --wb_en

        wb_sel_out      <= rd;
        predict_corr    <= new_pc;
        predict_corr_en <= bad_predict;
      end if;  --reset
    end if;  --clk

  end process coalesce;



end architecture;
