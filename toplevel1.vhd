library IEEE;
use IEEE.STD_LOGIC_1164.all;
entity riscV1 is

  generic (
	 REGISTER_SIZE			 : integer;
	 INSTRUCTION_MEM_SIZE : integer;
	 DATA_MEMORY_SIZE		 : integer);
  port(clk	 : in std_logic;
		 reset : in std_logic);

end entity riscV1;

architecture rtl of riscV1 is
  constant REGISTER_NAME_SIZE	 : integer := 5;
  constant INSTRUCTION_SIZE	 : integer := 32;
  constant SIGN_EXTENSION_SIZE : integer := 20;

  component decode is
	 generic(
		REGISTER_SIZE		  : positive;
		REGISTER_NAME_SIZE  : positive;
		INSTRUCTION_SIZE	  : positive;
		SIGN_EXTENSION_SIZE : positive);
	 port(
		clk			: in std_logic;
		reset			: in std_logic;
		instruction : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);

		--writeback signals
		wb_sel	 : in std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
		wb_data	 : in std_logic_vector(REGISTER_SIZE -1 downto 0);
		wb_enable : in std_logic;

		--output signals
		rs1_data			: out std_logic_vector(REGISTER_SIZE -1 downto 0);
		rs2_data			: out std_logic_vector(REGISTER_SIZE -1 downto 0);
		sign_extension : out std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
		--inputs just for carrying to next pipeline stage
		pc_next_in		: in	std_logic_vector(REGISTER_SIZE-1 downto 0);
		pc_curr_in		: in	std_logic_vector(REGISTER_SIZE-1 downto 0);
		instr_in			: in	std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
		pc_next_out		: out std_logic_vector(REGISTER_SIZE-1 downto 0);
		pc_curr_out		: out std_logic_vector(REGISTER_SIZE-1 downto 0);
		instr_out		: out std_logic_vector(INSTRUCTION_SIZE-1 downto 0));

  end component;



  component execute is
	 generic(
		REGISTER_SIZE		  : positive;
		REGISTER_NAME_SIZE  : positive;
		INSTRUCTION_SIZE	  : positive;
		SIGN_EXTENSION_SIZE : positive);
	 port(
		clk	: in std_logic;
		reset : in std_logic;

		pc_next		: in std_logic_vector(REGISTER_SIZE-1 downto 0);
		pc_current	: in std_logic_vector(REGISTER_SIZE-1 downto 0);
		instruction : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);

		rs1_data			: in std_logic_vector(REGISTER_SIZE-1 downto 0);
		rs2_data			: in std_logic_vector(REGISTER_SIZE-1 downto 0);
		sign_extension : in std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);

		wb_sel  : inout std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
		wb_data : inout std_logic_vector(REGISTER_SIZE-1 downto 0);
		wb_en	  : inout std_logic;

		predict_corr	 : out std_logic_vector(REGISTER_SIZE-1 downto 0);
		predict_corr_en : out std_logic);
  end component execute;

  component instruction_fetch is
	 generic (
		REGISTER_SIZE			: positive;
		INSTRUCTION_SIZE		: positive;
		INSTRUCTION_MEM_SIZE : positive);
	 port (
		clk		  : in std_logic;
		reset		  : in std_logic;
		pc_corr	  : in std_logic_vector(REGISTER_SIZE-1 downto 0);
		pc_corr_en : in std_logic;

		instr_out	: out std_logic_vector(REGISTER_SIZE-1 downto 0);
		pc_out		: out std_logic_vector(REGISTER_SIZE-1 downto 0);
		next_pc_out : out std_logic_vector(REGISTER_SIZE-1 downto 0));

  end component instruction_fetch;

  --signals going int fetch
  signal pc_corr_en : std_logic;
  signal pc_corr	  : std_logic_vector(REGISTER_SIZE-1 downto 0);

  --signals going into decode
  signal d_instr	 : std_logic_vector(INSTRUCTION_SIZE -1 downto 0);
  signal d_pc		 : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal d_next_pc : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal wb_data : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal wb_sel  : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal wb_en	  : std_logic;

  --signals going into execute
  signal e_instr			: std_logic_vector(INSTRUCTION_SIZE -1 downto 0);
  signal e_pc				: std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal e_next_pc		: std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal rs1_data			: std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal rs2_data			: std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal sign_extension : std_logic_vector(REGISTER_SIZE-12-1 downto 0);

begin	 -- architecture rtl
  instr_fetch : component instruction_fetch
	 generic map (
		REGISTER_SIZE			=> REGISTER_SIZE,
		INSTRUCTION_SIZE		=> INSTRUCTION_SIZE,
		INSTRUCTION_MEM_SIZE => INSTRUCTION_MEM_SIZE)
	 port map (
		clk		  => clk,
		reset		  => reset,
		pc_corr	  => pc_corr,
		pc_corr_en => pc_corr_en,

		instr_out	=> d_instr,
		pc_out		=> d_pc,
		next_pc_out => d_next_pc);

  D : component decode
	 generic map(
		REGISTER_SIZE		  => REGISTER_SIZE,
		REGISTER_NAME_SIZE  => REGISTER_NAME_SIZE,
		INSTRUCTION_SIZE	  => INSTRUCTION_SIZE,
		SIGN_EXTENSION_SIZE => SIGN_EXTENSION_SIZE)
	 port map(
		clk				=> clk,
		reset				=> reset,
		instruction		=> d_instr,
		--writeback ,signals
		wb_sel			=> wb_sel,
		wb_data			=> wb_data,
		wb_enable		=> wb_en,
		--output sig,nals
		rs1_data			=> rs1_data,
		rs2_data			=> rs2_data,
		sign_extension => sign_extension,
		--inputs jus,t for carrying to next pipeline stage
		pc_next_in		=> d_next_pc,
		pc_curr_in		=> d_pc,
		instr_in			=> d_instr,
		pc_next_out		=> e_next_pc,
		pc_curr_out		=> e_pc,
		instr_out		=> e_instr);
  X : component execute
	 generic map (
		REGISTER_SIZE		  => REGISTER_SIZE,
		REGISTER_NAME_SIZE  => REGISTER_NAME_SIZE,
		INSTRUCTION_SIZE	  => INSTRUCTION_SIZE,
		SIGN_EXTENSION_SIZE => SIGN_EXTENSION_SIZE)
	 port map (
		clk				 => clk,
		reset				 => reset,
		pc_next			 => d_next_pc,
		pc_current		 => e_pc,
		instruction		 => e_instr,
		rs1_data			 => rs1_data,
		rs2_data			 => rs2_data,
		sign_extension	 => sign_extension,
		wb_sel			 => wb_sel,
		wb_data			 => wb_data,
		wb_en				 => wb_en,
		predict_corr	 => pc_corr,
		predict_corr_en => pc_corr_en);

end architecture rtl;
