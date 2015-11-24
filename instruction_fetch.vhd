

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;


library work;
use work.rv_components.all;
use work.utils.all;

entity instruction_fetch is
  generic (
    REGISTER_SIZE    : positive;
    INSTRUCTION_SIZE : positive;
    RESET_VECTOR     : natural);
  port (
    clk   : in std_logic;
    reset : in std_logic;
    stall : in std_logic;

    branch_pred : in std_logic_vector(REGISTER_SIZE*2+3-1 downto 0);

    instr_out       : out std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    pc_out          : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    br_taken        : out std_logic;
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
  signal next_pc         : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal predicted_pc    : std_logic_vector(REGISTER_SIZE -1 downto 0);
  signal saved_address   : std_logic_vector(REGISTER_SIZE -1 downto 0);

  signal instr : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);

  signal valid_instr : std_logic;

  constant BRANCH_PREDICTORS : natural := 0;

  signal pc_corr    : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal pc_corr_en : std_logic;
  signal if_stall   : std_logic;
begin  -- architecture rtl
  pc_corr    <= branch_get_tgt(branch_pred);
  pc_corr_en <= branch_get_flush(branch_pred);

  assert program_counter(1 downto 0) = "00" report "BAD INSTRUCTION ADDRESS" severity error;

  read_en <= not reset;

  if_stall <= stall or read_wait;

  next_pc <= pc_corr when pc_corr_en = '1' else
             predicted_pc;

  latch_corr : process(clk)
  begin
    if rising_edge(clk) then
      if pc_corr_en = '1' then
        correction_en <= '1';
      elsif read_datavalid = '1' then
        correction_en <= '0';
      end if;
      if reset = '1' then
        correction_en <= '0';
      end if;
    end if;  -- clock
  end process;

  latch_pc : process(clk)
  begin
    if rising_edge(clk) then
      if stall = '0' or pc_corr_en = '1' then
        program_counter <= next_pc;
      end if;
      if stall = '0' then
        saved_address <= program_counter;
      end if;
      if reset = '1' then
        program_counter <= std_logic_vector(to_signed(RESET_VECTOR, REGISTER_SIZE));
      end if;
    end if;  -- clock
  end process;


--unpack instruction
  instr       <= read_data;
  valid_instr <= read_datavalid and not pc_corr_en and not correction_en;




  nuse_BP : if BRANCH_PREDICTORS = 0 generate

    --No branch prediction
    process(clk)
    begin
      if rising_edge(clk) then
        br_taken     <= '0';
        if stall='0'  then
          predicted_pc <= std_logic_vector(signed(next_pc) + 4);
        end if;
        if reset = '1' then
          predicted_pc <= std_logic_vector(to_signed(RESET_VECTOR, REGISTER_SIZE));
        end if;
      end if;
    end process;

  end generate nuse_BP;

  use_BP : if BRANCH_PREDICTORS > 0 generate
    constant INDEX_SIZE : integer := log2(BRANCH_PREDICTORS);
    constant TAG_SIZE   : integer := REGISTER_SIZE-2-INDEX_SIZE;

    type tbt_type is array(BRANCH_PREDICTORS-1 downto 0) of std_logic_vector(REGISTER_SIZE+TAG_SIZE+1 -1 downto 0);
    signal branch_tbt       : tbt_type := (others => (others => '0'));
    signal prediction_match : std_logic;
    signal branch_taken     : std_logic;
    signal branch_pc        : std_logic_vector(REGISTER_SIZE-1 downto 0);
    signal branch_tgt       : std_logic_vector(REGISTER_SIZE-1 downto 0);
    signal branch_flush     : std_logic;
    signal branch_en        : std_logic;
    signal tbt_raddr        : integer;
    signal tbt_waddr        : integer;
    signal add4             : std_logic_vector(REGISTER_SIZE-1 downto 0);
    signal addr_tag         : std_logic_vector(TAG_SIZE-1 downto 0);

    signal tbt_entry : std_logic_vector(branch_tbt(0)'range);
    alias tbt_tag    : std_logic_vector(TAG_SIZE-1 downto 0) is tbt_entry(REGISTER_SIZE+TAG_SIZE-1 downto REGISTER_SIZE);
    alias tbt_taken  : std_logic is tbt_entry(tbt_entry'left);
    alias tbt_target : std_logic_vector(REGISTER_SIZE-1 downto 0) is tbt_entry(REGISTER_SIZE-1 downto 0);
  begin
    branch_tgt   <= branch_get_tgt(branch_pred);
    branch_pc    <= branch_get_pc(branch_pred);
    branch_taken <= branch_get_taken(branch_pred);
    branch_en    <= branch_get_enable(branch_pred);
    tbt_raddr    <= 0 when BRANCH_PREDICTORS = 1 else
                    to_integer(unsigned(next_pc(INDEX_SIZE+2-1 downto 2)));
    tbt_waddr <= 0 when BRANCH_PREDICTORS = 1 else
                 to_integer(unsigned(branch_pc(INDEX_SIZE+2-1 downto 2)));

    process(clk)

    begin
      if rising_edge(clk) then
        tbt_entry <= branch_tbt(tbt_raddr);
        if branch_en = '1' then
          branch_tbt(tbt_waddr) <= branch_taken &branch_pc(INDEX_SIZE+2+TAG_SIZE-1 downto INDEX_SIZE+2) & branch_tgt;
        end if;

        addr_tag <= next_pc(INDEX_SIZE+2+TAG_SIZE-1 downto INDEX_SIZE+2);
        add4     <= std_logic_vector(signed(next_pc) + 4);
      end if;
    end process;

    predicted_pc     <= tbt_target when tbt_tag = addr_tag and tbt_taken = '1' else add4;
    br_taken         <= '1'        when tbt_tag = addr_tag and tbt_taken = '1' else '0';
    prediction_match <= '1'        when tbt_tag = addr_tag                     else '0';
  end generate use_BP;



  instr_out <= instr;
  pc_out    <= saved_address;

  valid_instr_out <= valid_instr;

  read_address <= saved_address when read_wait = '1' else program_counter;

end architecture rtl;
