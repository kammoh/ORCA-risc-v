library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity system_calls is

  generic (
    REGISTER_SIZE    : natural;
    INSTRUCTION_SIZE : natural;
    RESET_VECTOR     : natural);

  port (
    clk         : in std_logic;
    reset       : in std_logic;
    valid       : in std_logic;
    rs1_data    : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    instruction : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);

    finished_instr : in std_logic;

    wb_data : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    wb_en   : out std_logic;

    to_host       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    from_host     : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    current_pc    : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    pc_correction : out std_logic_vector(REGISTER_SIZE -1 downto 0);
    pc_corr_en    : out std_logic);

end entity system_calls;

architecture rtl of system_calls is
  alias csr    : std_logic_vector(11 downto 0) is instruction(31 downto 20);
  alias source : std_logic_vector(4 downto 0) is instruction(19 downto 15);
  alias zimm   : std_logic_vector(4 downto 0) is instruction(19 downto 15);
  alias func3  : std_logic_vector(2 downto 0) is instruction(14 downto 12);
  alias dest   : std_logic_vector(4 downto 0) is instruction(11 downto 7);
  alias opcode : std_logic_vector(6 downto 0) is instruction(6 downto 0);

  signal bad_instruction : std_logic;

  signal cycles        : unsigned(63 downto 0);
  signal instr_retired : unsigned(63 downto 0);

  constant mcpuid  : std_logic_vector(REGISTER_SIZE-1 downto 0) := (others => '0');
  constant mimpid  : std_logic_vector(REGISTER_SIZE-1 downto 0) := x"0000" &x"8000";
  constant mhartid : std_logic_vector(REGISTER_SIZE-1 downto 0) := (others => '0');
  signal mstatus   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal mtvec     : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal mtdeleg   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal mie       : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal mtimecmp  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal mtime     : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal mtimeh    : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal mscratch  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal mepc      : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal mcause    : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal mbadaddr  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal mip       : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal mbase     : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal mbound    : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal mibase    : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal mibound   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal mdbase    : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal mdbound   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal htimew    : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal htimehw   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal mtohost   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal mfromhost : std_logic_vector(REGISTER_SIZE-1 downto 0);


  subtype csr_t is std_logic_vector(11 downto 0);
  --CSR constants
  --USER
  constant CSR_CYCLE     : csr_t := x"C00";
  constant CSR_TIME      : csr_t := x"C01";
  constant CSR_INSTRET   : csr_t := x"C02";
  constant CSR_CYCLEH    : csr_t := x"C80";
  constant CSR_TIMEH     : csr_t := x"C81";
  constant CSR_INSTRETH  : csr_t := x"C82";
  --MACHINE
  constant CSR_MCPUID    : csr_t := X"F00";
  constant CSR_MIMPID    : csr_t := X"F01";
  constant CSR_MHARTID   : csr_t := X"F10";
  constant CSR_MSTATUS   : csr_t := X"300";
  constant CSR_MTVEC     : csr_t := X"301";
  constant CSR_MTDELEG   : csr_t := X"302";
  constant CSR_MIE       : csr_t := X"304";
  constant CSR_MTIMECMP  : csr_t := X"321";
  constant CSR_MTIME     : csr_t := X"701";
  constant CSR_MTIMEH    : csr_t := X"741";
  constant CSR_MSCRATCH  : csr_t := X"340";
  constant CSR_MEPC      : csr_t := X"341";
  constant CSR_MCAUSE    : csr_t := X"342";
  constant CSR_MBADADDR  : csr_t := X"343";
  constant CSR_MIP       : csr_t := X"344";
  constant CSR_MBASE     : csr_t := X"380";
  constant CSR_MBOUND    : csr_t := X"381";
  constant CSR_MIBASE    : csr_t := X"382";
  constant CSR_MIBOUND   : csr_t := X"383";
  constant CSR_MDBASE    : csr_t := X"384";
  constant CSR_MDBOUND   : csr_t := X"385";
  constant CSR_HTIMEW    : csr_t := X"B01";
  constant CSR_HTIMEHW   : csr_t := X"B81";
  constant CSR_MTOHOST   : csr_t := X"780";
  constant CSR_MFROMHOST : csr_t := X"781";

  --EXECPTION CODES
  constant MMODE_ECALL : std_logic_vector(3 downto 0) := x"B";
  constant BREAKPOINT  : std_logic_vector(3 downto 0) := x"3";

  --RESSET VECTORS
  constant SYSTEM_RESET :
    std_logic_vector(REGISTER_SIZE-1 downto 0) := std_logic_vector(to_unsigned(RESET_VECTOR - 16#00#, REGISTER_SIZE));
  constant MACHINE_MODE_TRAP :
    std_logic_vector(REGISTER_SIZE-1 downto 0) := std_logic_vector(to_unsigned(RESET_VECTOR - 16#40#, REGISTER_SIZE));

  --func3 constants
  constant CSRRW  : std_logic_vector(2 downto 0) := "001";
  constant CSRRS  : std_logic_vector(2 downto 0) := "010";
  constant CSRRC  : std_logic_vector(2 downto 0) := "011";
  constant CSRRWI : std_logic_vector(2 downto 0) := "101";
  constant CSRRSI : std_logic_vector(2 downto 0) := "110";
  constant CSRRCI : std_logic_vector(2 downto 0) := "111";


--internal signals
  signal csr_read_val  : std_logic_vector(REGISTER_SIZE -1 downto 0);
  signal csr_write_val : std_logic_vector(REGISTER_SIZE -1 downto 0);
  signal bit_sel       : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal ibit_sel      : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal resized_zimm  : std_logic_vector(REGISTER_SIZE-1 downto 0);


begin  -- architecture rtl

  counter_increment : process (clk) is
  begin  -- process
    if rising_edge(clk) then
      if reset = '1' then
        cycles        <= (others => '0');
        instr_retired <= (others => '0');
      else
        cycles <= cycles +1;
        if finished_instr = '1' then
          instr_retired <= instr_retired +1;
        end if;
      end if;
    end if;
  end process;

  mfromhost <= from_host;
  mtime     <= std_logic_vector(cycles(REGISTER_SIZE-1 downto 0));
  mtimeh    <= std_logic_vector(cycles(63 downto 64-REGISTER_SIZE));

  with csr select
    csr_read_val <=
    std_logic_vector(instr_retired(REGISTER_SIZE-1 downto 0))   when CSR_INSTRET,
    std_logic_vector(instr_retired(63 downto 64-REGISTER_SIZE)) when CSR_INSTRETH,

    mtime     when CSR_CYCLE,
    mtime     when CSR_TIME,
    mtimeh    when CSR_CYCLEH,
    mtimeh    when CSR_TIMEH,
    mcpuid    when CSR_MCPUID,
    mimpid    when CSR_MIMPID,
    mhartid   when CSR_MHARTID,
    mstatus   when CSR_MSTATUS,
    mtvec     when CSR_MTVEC,
    mtdeleg   when CSR_MTDELEG,
    mie       when CSR_MIE,
    mtimecmp  when CSR_MTIMECMP,
    mtime     when CSR_MTIME,
    mtimeh    when CSR_MTIMEH,
    mscratch  when CSR_MSCRATCH,
    mepc      when CSR_MEPC,
    mcause    when CSR_MCAUSE,
    mbadaddr  when CSR_MBADADDR,
    mip       when CSR_MIP,
    mbase     when CSR_MBASE,
    mbound    when CSR_MBOUND,
    mibase    when CSR_MIBASE,
    mibound   when CSR_MIBOUND,
    mdbase    when CSR_MDBASE,
    mdbound   when CSR_MDBOUND,
    htimew    when CSR_HTIMEW,
    htimehw   when CSR_HTIMEHW,
    mtohost   when CSR_MTOHOST,
    mfromhost when CSR_MFROMHOST,

    (others => 'X') when others;

  bit_sel                                      <= rs1_data;
  ibit_sel(REGISTER_SIZE-1 downto zimm'left+1) <= (others => '0');
  ibit_sel(zimm'left downto 0)                 <= zimm;

  resized_zimm(4 downto 0)                <= zimm;
  resized_zimm(REGISTER_SIZE -1 downto 5) <= (others => '0');

  with func3 select
    csr_write_val <=
    rs1_data                      when CSRRW,
    csr_read_val or bit_sel       when CSRRS,
    csr_read_val and not bit_sel  when CSRRC,
    resized_zimm                  when CSRRWI,
    csr_read_val or ibit_sel      when CSRRSI,
    csr_read_val and not ibit_sel when CSRRCI,
    (others => 'X')               when others;


  output_proc : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        --mcpuid    (others => '0');
        --mimpid    (others => '0');
        --mhartid   (others => '0');
        mstatus   <= (others => '0');
        mtvec     <= SYSTEM_RESET;
        mtdeleg   <= (others => '0');
        mie       <= (others => '0');
        mtimecmp  <= (others => '0');
        --mtime     <= (others => '0');
        --mtimeh    <= (others => '0');
        mscratch  <= (others => '0');
        mepc      <= (others => '0');
        mcause    <= (others => '0');
        mbadaddr  <= (others => '0');
        mip       <= (others => '0');
        mbase     <= (others => '0');
        mbound    <= (others => '0');
        mibase    <= (others => '0');
        mibound   <= (others => '0');
        mdbase    <= (others => '0');
        mdbound   <= (others => '0');
        htimew    <= (others => '0');
        htimehw   <= (others => '0');
        --mfromhost <= (others => '0');
        mtohost   <= (others => '0');

      else
        --writeback to register file
        wb_data    <= csr_read_val;
        pc_corr_en <= '0';
        wb_en      <= '0';
        if opcode = "1110011" then
          if func3 /= "000" and func3 /= "100" then
            wb_en <= valid;
          end if;

          if zimm & func3 = "00000"&"000" then
            if CSR = x"000" then        --ECALL
              mcause(REGISTER_SIZE-1 downto 4) <= (others => '0');
              mcause(3 downto 0)               <= MMODE_ECALL;
              pc_corr_en                       <= '1';
              pc_correction                    <= MACHINE_MODE_TRAP;
              mepc                             <= current_pc;
            elsif CSR = x"001" then     --EBREAK
              mcause(REGISTER_SIZE-1 downto 4) <= (others => '0');
              mcause(3 downto 0)               <= BREAKPOINT;
              pc_corr_en                       <= '1';
              pc_correction                    <= MACHINE_MODE_TRAP;
              mepc                             <= current_pc;
            elsif CSR = x"100" then     --ERET
              pc_corr_en    <= '1';
              pc_correction <= mepc;
            end if;
          else
            --writeback to CSR
            case CSR is
              --read-write registers
              when CSR_MTOHOST =>
                mtohost <= csr_write_val;
              when CSR_MEPC =>
                mepc <= csr_write_val;
              when others =>
                null;
            end case;

          end if;  --system_calls

        end if;  --opcode
      end if;  --reset
    end if;  --clk
  end process;

  to_host <= mtohost;
end architecture rtl;
