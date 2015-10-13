library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;
--use IEEE.std_logic_arith.all;

entity branch_unit is


  generic (
    REGISTER_SIZE       : integer;
    INSTRUCTION_SIZE    : integer;
    SIGN_EXTENSION_SIZE : integer);

  port (
    clk            : in  std_logic;
    stall          : in  std_logic;
    valid          : in  std_logic;
    reset          : in  std_logic;
    rs1_data       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    rs2_data       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    current_pc     : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    predicted_pc   : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    instr          : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    sign_extension : in  std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
    --unconditional jumps store return address in rd, output return address
    -- on data_out lines
    data_out       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_out_en    : out std_logic;
    new_pc         : out std_logic_vector(REGISTER_SIZE-1 downto 0);  --next pc
    bad_predict    : out std_logic
    );
end entity branch_unit;

architecture latch_on_input of branch_unit is

  constant OP_IMM_IMMEDIATE_SIZE : integer := 12;

  --op codes
  constant JAL    : std_logic_vector(6 downto 0) := "1101111";
  constant JALR   : std_logic_vector(6 downto 0) := "1100111";
  constant BRANCH : std_logic_vector(6 downto 0) := "1100011";

  --func3
  constant BEQ  : std_logic_vector(2 downto 0) := "000";
  constant BNE  : std_logic_vector(2 downto 0) := "001";
  constant BLT  : std_logic_vector(2 downto 0) := "100";
  constant BGE  : std_logic_vector(2 downto 0) := "101";
  constant BLTU : std_logic_vector(2 downto 0) := "110";
  constant BGEU : std_logic_vector(2 downto 0) := "111";


  --these are one bit larget than a register
  signal op1      : signed(REGISTER_SIZE downto 0);
  signal op2      : signed(REGISTER_SIZE downto 0);
  signal sub      : signed(REGISTER_SIZE downto 0);
  signal msb_mask : std_logic;

  signal jal_imm        : unsigned(REGISTER_SIZE-1 downto 0);
  signal jalr_imm       : unsigned(REGISTER_SIZE-1 downto 0);
  signal b_imm          : unsigned(REGISTER_SIZE-1 downto 0);
  signal branch_target  : unsigned(REGISTER_SIZE-1 downto 0);
  signal nbranch_target : unsigned(REGISTER_SIZE-1 downto 0);
  signal jalr_target    : unsigned(REGISTER_SIZE-1 downto 0);
  signal jal_target     : unsigned(REGISTER_SIZE-1 downto 0);
  signal target_pc      : unsigned(REGISTER_SIZE-1 downto 0);

  signal leq_flg : std_logic;
  signal eq_flg  : std_logic;

  signal branch_taken : std_logic;

  signal valid_latch          : std_logic;
  signal rs1_data_latch       : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal rs2_data_latch       : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal current_pc_latch     : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal predicted_pc_latch   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal instr_latch          : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
  signal sign_extension_latch : std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);


  alias func3  : std_logic_vector(2 downto 0) is instr_latch(14 downto 12);
  alias opcode : std_logic_vector(6 downto 0) is instr_latch(6 downto 0);

begin  -- architecture rtl

  input_latch : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        current_pc_latch     <= std_logic_vector(to_unsigned(0, REGISTER_SIZE));
        predicted_pc_latch   <= std_logic_vector(to_unsigned(4, REGISTER_SIZE));
        instr_latch          <= instr;
        sign_extension_latch <= sign_extension;
      else
        if stall = '0' then
          valid_latch          <= valid;
          rs1_data_latch       <= rs1_data;
          rs2_data_latch       <= rs2_data;
          current_pc_latch     <= current_pc;
          predicted_pc_latch   <= predicted_pc;
          instr_latch          <= instr;
          sign_extension_latch <= sign_extension;
        end if;

      end if;
    end if;

  end process;

  with func3 select
    msb_mask <=
    '0' when BLTU,
    '0' when BGEU,
    '1' when others;



  op1 <= signed((msb_mask and rs1_data_latch(rs1_data'left)) & rs1_data_latch);
  op2 <= signed((msb_mask and rs2_data_latch(rs2_data'left)) & rs2_data_latch);
  sub <= op1 - op2;

  eq_flg  <= '1' when op1 = op2 else '0';
  leq_flg <= sub(sub'left);

  with func3 select
    branch_taken <=
    eq_flg                 when beq,
    not eq_flg             when bne,
    leq_flg and not eq_flg when blt,
    not leq_flg or eq_flg  when bge,
    leq_flg and not eq_flg when bltu,
    not leq_flg or eq_flg  when bgeu,
    '0'                    when others;

  b_imm <= unsigned(sign_extension_latch(REGISTER_SIZE-13 downto 0) &
                    instr_latch(7) & instr_latch(30 downto 25) &instr_latch(11 downto 8) & "0");

  jalr_imm <= unsigned(sign_extension_latch(REGISTER_SIZE-12-1 downto 0) &
                       instr_latch(31 downto 21) & "0") ;
  jal_imm <= unsigned(RESIZE(signed(instr_latch(31) & instr_latch(19 downto 12) & instr_latch(19 downto 12) & instr_latch(20) &
                                    instr_latch(30 downto 21)&"0"),REGISTER_SIZE));


  branch_target  <= b_imm + unsigned(current_pc_latch);
  nbranch_target <= to_unsigned(4, REGISTER_SIZE) + unsigned(current_pc_latch);
  jalr_target    <= jalr_imm + unsigned(rs1_data_latch);
  jal_target     <= jal_imm + unsigned(current_pc_latch);


  with branch_taken & opcode select
    target_pc <=
    jalr_target    when "0" & JALR,
    jalr_target    when "1" & JALR,
    jal_target     when "0" & JAL,
    jal_target     when "1" & JAL,
    branch_target  when "1" & BRANCH,
    nbranch_target when others;



  data_out_en <= '1' when valid_latch = '1' and (opcode = JAL or opcode = JALR)           else '0';
  data_out    <= std_logic_vector(nbranch_target);
  new_pc      <= std_logic_vector(target_pc);
  bad_predict <= '1' when valid_latch = '1' and target_pc /= unsigned(predicted_pc_latch) else '0';


end architecture;



architecture latch_on_output of branch_unit is

  constant OP_IMM_IMMEDIATE_SIZE : integer := 12;

  --op codes
  constant JAL    : std_logic_vector(6 downto 0) := "1101111";
  constant JALR   : std_logic_vector(6 downto 0) := "1100111";
  constant BRANCH : std_logic_vector(6 downto 0) := "1100011";

  --func3
  constant BEQ  : std_logic_vector(2 downto 0) := "000";
  constant BNE  : std_logic_vector(2 downto 0) := "001";
  constant BLT  : std_logic_vector(2 downto 0) := "100";
  constant BGE  : std_logic_vector(2 downto 0) := "101";
  constant BLTU : std_logic_vector(2 downto 0) := "110";
  constant BGEU : std_logic_vector(2 downto 0) := "111";


  --these are one bit larget than a register
  signal op1      : signed(REGISTER_SIZE downto 0);
  signal op2      : signed(REGISTER_SIZE downto 0);
  signal sub      : signed(REGISTER_SIZE downto 0);
  signal msb_mask : std_logic;

  signal jal_imm        : unsigned(REGISTER_SIZE-1 downto 0);
  signal jalr_imm       : unsigned(REGISTER_SIZE-1 downto 0);
  signal b_imm          : unsigned(REGISTER_SIZE-1 downto 0);
  signal branch_target  : unsigned(REGISTER_SIZE-1 downto 0);
  signal nbranch_target : unsigned(REGISTER_SIZE-1 downto 0);
  signal jalr_target    : unsigned(REGISTER_SIZE-1 downto 0);
  signal jal_target     : unsigned(REGISTER_SIZE-1 downto 0);
  signal target_pc      : unsigned(REGISTER_SIZE-1 downto 0);

  signal leq_flg : std_logic;
  signal eq_flg  : std_logic;

  signal branch_taken : std_logic;
  signal bmux         : std_logic_vector(1 downto 0);
  alias func3         : std_logic_vector(2 downto 0) is instr(14 downto 12);
  alias opcode        : std_logic_vector(6 downto 0) is instr(6 downto 0);

begin  -- architecture


  --msb_mask is '0' for unsigned branch instructions
  msb_mask <= not func3(1);


  op1 <= signed((msb_mask and rs1_data(rs1_data'left)) & rs1_data);
  op2 <= signed((msb_mask and rs2_data(rs2_data'left)) & rs2_data);
  sub <= op1 - op2;

  eq_flg  <= '1' when rs1_data = rs2_data else '0';
  leq_flg <= sub(sub'left);

  with func3 select
    branch_taken <=
    eq_flg                 when beq,
    not eq_flg             when bne,
    leq_flg and not eq_flg when blt,
    not leq_flg or eq_flg  when bge,
    leq_flg and not eq_flg when bltu,
    not leq_flg or eq_flg  when bgeu,
    '0'                    when others;

  b_imm <= unsigned(sign_extension(REGISTER_SIZE-13 downto 0) &
                    instr(7) & instr(30 downto 25) &instr(11 downto 8) & "0");

  jalr_imm <= unsigned(sign_extension(REGISTER_SIZE-12-1 downto 0) &
                       instr(31 downto 21) & "0") ;
  jal_imm <= unsigned(RESIZE(signed(instr(31) & instr(19 downto 12) & instr(19 downto 12) & instr(20) &
                                    instr(30 downto 21)&"0"),REGISTER_SIZE));

  target_add : if true generate
    branch_target  <= b_imm + unsigned(current_pc);
    nbranch_target <= to_unsigned(4, REGISTER_SIZE) + unsigned(current_pc);
    jalr_target    <= jalr_imm + unsigned(rs1_data);
    jal_target     <= jal_imm + unsigned(current_pc);

  end generate target_add;

  bmux <= "00" when opcode = JALR else
          "01" when opcode = JAL else
          "10" when opcode = BRANCH and branch_taken = '1' else
          "11";


  --with bmux select
  --  target_pc <=
  --  jalr_target    when "00",
  --  jal_target     when "01",
  --  branch_target  when "10",
  --  nbranch_target when others;

  target_mux : if true generate
    with branch_taken & opcode select
      target_pc <=
      jalr_target    when "0" & JALR,
      jalr_target    when "1" & JALR,
      jal_target     when "0" & JAL,
      jal_target     when "1" & JAL,
      branch_target  when "1" & BRANCH,
      nbranch_target when others;

  end generate target_mux;


  output_latch : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        data_out_en <= '0';
        bad_predict <= '0';
      else
        if stall = '0' then
          if valid = '1' and (opcode = JAL or opcode = JALR) then
            data_out_en <= '1';
          else
            data_out_en <= '0';
          end if;
          if valid = '1' and target_pc /= unsigned(predicted_pc) then
            bad_predict <= '1';
          else
            bad_predict <= '0';
          end if;
          data_out <= std_logic_vector(nbranch_target);
          new_pc   <= std_logic_vector(target_pc);

        end if;

      end if;
    end if;

  end process;


end architecture;



architecture latch_middle of branch_unit is

  constant OP_IMM_IMMEDIATE_SIZE : integer := 12;

  --op codes
  constant JAL    : std_logic_vector(6 downto 0) := "1101111";
  constant JALR   : std_logic_vector(6 downto 0) := "1100111";
  constant BRANCH : std_logic_vector(6 downto 0) := "1100011";

  --func3
  constant BEQ  : std_logic_vector(2 downto 0) := "000";
  constant BNE  : std_logic_vector(2 downto 0) := "001";
  constant BLT  : std_logic_vector(2 downto 0) := "100";
  constant BGE  : std_logic_vector(2 downto 0) := "101";
  constant BLTU : std_logic_vector(2 downto 0) := "110";
  constant BGEU : std_logic_vector(2 downto 0) := "111";


  --these are one bit larget than a register
  signal op1      : signed(REGISTER_SIZE downto 0);
  signal op2      : signed(REGISTER_SIZE downto 0);
  signal sub      : signed(REGISTER_SIZE downto 0);
  signal msb_mask : std_logic;

  signal jal_imm        : unsigned(REGISTER_SIZE-1 downto 0);
  signal jalr_imm       : unsigned(REGISTER_SIZE-1 downto 0);
  signal b_imm          : unsigned(REGISTER_SIZE-1 downto 0);
  signal branch_target  : unsigned(REGISTER_SIZE-1 downto 0);
  signal nbranch_target : unsigned(REGISTER_SIZE-1 downto 0);
  signal jalr_target    : unsigned(REGISTER_SIZE-1 downto 0);
  signal jal_target     : unsigned(REGISTER_SIZE-1 downto 0);
  signal target_pc      : unsigned(REGISTER_SIZE-1 downto 0);

  signal leq_flg : std_logic;
  signal eq_flg  : std_logic;

  signal branch_taken : std_logic;

  alias func3  : std_logic_vector(2 downto 0) is instr(14 downto 12);
  alias opcode : std_logic_vector(6 downto 0) is instr(6 downto 0);

  signal opcode_latch       : std_logic_vector(6 downto 0);
  signal valid_latch        : std_logic;
  signal predicted_pc_latch : unsigned(REGISTER_SIZE-1 downto 0);
  signal target_pc_latch    : unsigned(REGISTER_SIZE-1 downto 0);
  signal branch_taken_latch : std_logic;
  signal data_en_latch      : std_logic;
begin  -- architecture


  with func3 select
    msb_mask <=
    '0' when BLTU,
    '0' when BGEU,
    '1' when others;



  op1 <= signed((msb_mask and rs1_data(rs1_data'left)) & rs1_data);
  op2 <= signed((msb_mask and rs2_data(rs2_data'left)) & rs2_data);
  sub <= op1 - op2;

  eq_flg  <= '1' when op1 = op2 else '0';
  leq_flg <= sub(sub'left);

  with func3 select
    branch_taken <=
    eq_flg                 when beq,
    not eq_flg             when bne,
    leq_flg and not eq_flg when blt,
    not leq_flg or eq_flg  when bge,
    leq_flg and not eq_flg when bltu,
    not leq_flg or eq_flg  when bgeu,
    '0'                    when others;

  b_imm <= unsigned(sign_extension(REGISTER_SIZE-13 downto 0) &
                    instr(7) & instr(30 downto 25) &instr(11 downto 8) & "0");

  jalr_imm <= unsigned(sign_extension(REGISTER_SIZE-12-1 downto 0) &
                       instr(31 downto 21) & "0") ;
  jal_imm <= unsigned(RESIZE(signed(instr(31) & instr(19 downto 12) & instr(19 downto 12) & instr(20) &
                                    instr(30 downto 21)&"0"),REGISTER_SIZE));

  branch_target      <= b_imm + unsigned(current_pc);
  nbranch_target     <= to_unsigned(4, REGISTER_SIZE) + unsigned(current_pc);
  jalr_target        <= jalr_imm + unsigned(rs1_data);
  jal_target         <= jal_imm + unsigned(current_pc);

  with branch_taken & opcode select
    target_pc <=
    jalr_target    when "0" & JALR,
    jalr_target    when "1" & JALR,
    jal_target     when "0" & JAL,
    jal_target     when "1" & JAL,
    branch_target  when "1" & BRANCH,
    nbranch_target when others;


  middle_latch : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        valid_latch <= '0';

      else
        if stall = '0' then
          valid_latch        <= valid;
          predicted_pc_latch <= unsigned(predicted_pc);
          target_pc_latch <= target_pc;
          if opcode = JAL or opcode = JALR then
            data_en_latch <= valid;
          else
            data_en_latch <= '0';
          end if;
          data_out <= std_logic_vector(nbranch_target);
        end if;
      end if;
    end if;
  end process;


  data_out_en <= data_en_latch;
  bad_predict <= valid_latch when target_pc_latch /= predicted_pc_latch or data_en_latch = '1' else '0';
  --data_out    <= std_logic_vector(nbranch_target);
  new_pc      <= std_logic_vector(target_pc_latch);


end architecture;
