

-- Quartus II VHDL Template
-- Simple Dual-Port RAM with different read/write addresses and single read/write clock
-- and with a control for writing single bytes into the memory word; byte enable

library ieee;
use ieee.std_logic_1164.all;
library riscv;

entity byte_enabled_simple_dual_port_ram is

	generic (
		ADDR_WIDTH : natural := 6;
		BYTE_WIDTH : natural := 8;
		BYTES : natural := 4);

	port (
		we, clk : in  std_logic;
		be      : in  std_logic_vector (BYTES - 1 downto 0);
		wdata   : in  std_logic_vector(BYTE_WIDTH*BYTES - 1 downto 0);
		waddr   : in  integer range 0 to 2 ** ADDR_WIDTH -1 ;
		raddr   : in  integer range 0 to 2 ** ADDR_WIDTH - 1;
		q       : out std_logic_vector(BYTES*BYTE_WIDTH-1 downto 0));
end byte_enabled_simple_dual_port_ram;

architecture rtl of byte_enabled_simple_dual_port_ram is
	--  build up 2D array to hold the memory
	type word_t is array (0 to BYTES-1) of std_logic_vector(BYTE_WIDTH-1 downto 0);
	type ram_t is array (0 to 2 ** ADDR_WIDTH - 1) of word_t;
	-- delcare the RAM
	signal ram : ram_t := (others => (others => (others => 'X') ));
	signal q_local : word_t;

begin  -- rtl
	-- Re-organize the read data from the RAM to match the output
	unpack: for i in 0 to BYTES - 1 generate
		q(BYTE_WIDTH*(i+1) - 1 downto BYTE_WIDTH*i) <= q_local(i);
	end generate unpack;

	mem_proc:process(clk)
	begin
		if(rising_edge(clk)) then
			if(we = '1') then
				for i in 0 to BYTES-1 loop
				if(be(i) = '1') then
					ram(waddr)(BYTES-1-i) <= wdata(BYTE_WIDTH*(i+1) - 1 downto BYTE_WIDTH*i);
				end if;
           end loop;  -- i
			end if;
			q_local <= ram(raddr);
		end if;
	end process;
end rtl;

-- Quartus II VHDL Template
-- True Dual-Port RAM with single clock
-- and individual controls for writing into seperate bytes of the memory word (byte-enable)
--
-- Read-during-write on port A or B returns old data
--
-- Read-during-write between A and B returns either new or old data depending
-- on the order in which the simulator executes the process statements.
-- Quartus II will consider this read-during-write scenario as a
-- don't care condition to optimize the performance of the RAM.  If you
-- need a read-during-write between ports to return the old data, you
-- must instantiate the altsyncram Megafunction directly.

library ieee;
use ieee.std_logic_1164.all;
library work;

entity byte_enabled_true_dual_port_ram is

	generic (
		ADDR_WIDTH : natural := 8;
		BYTE_WIDTH : natural := 8;
		BYTES : natural := 4);

	port (
		we1, we2, clk : in  std_logic;
		be1      : in  std_logic_vector (BYTES - 1 downto 0);
		be2      : in  std_logic_vector (BYTES - 1 downto 0);
		data_in1 : in  std_logic_vector(BYTES*BYTE_WIDTH - 1 downto 0);
		data_in2 : in  std_logic_vector(BYTES*BYTE_WIDTH - 1 downto 0);
		addr1   : in  integer range 0 to 2 ** ADDR_WIDTH -1 ;
		addr2   : in  integer range 0 to 2 ** ADDR_WIDTH - 1;
		data_out1 : out std_logic_vector(BYTES*BYTE_WIDTH-1 downto 0);
		data_out2 : out std_logic_vector(BYTES*BYTE_WIDTH-1 downto 0));
end byte_enabled_true_dual_port_ram;

architecture rtl of byte_enabled_true_dual_port_ram is
	--  build up 2D array to hold the memory
	type word_t is array (0 to BYTES-1) of std_logic_vector(BYTE_WIDTH-1 downto 0);
	type ram_t is array (0 to 2 ** ADDR_WIDTH - 1) of word_t;

	signal ram : ram_t;
	signal q1_local : word_t;
	signal q2_local : word_t;

begin  -- rtl
	-- Reorganize the read data from the RAM to match the output
	unpack: for i in 0 to BYTES - 1 generate
		data_out1(BYTE_WIDTH*(i+1) - 1 downto BYTE_WIDTH*i) <= q1_local(i);
		data_out2(BYTE_WIDTH*(i+1) - 1 downto BYTE_WIDTH*i) <= q2_local(i);
	end generate unpack;

	port1:process(clk)
	begin
		if(rising_edge(clk)) then
			if(we1 = '1') then
				for i in 0 to BYTES-1 loop
					if(be1(i) = '1') then
						ram(addr1)(BYTES-1-i) <= data_in1(BYTE_WIDTH*(i+1) - 1 downto BYTE_WIDTH*i);
					end if;
           end loop;  -- i
			end if;
			q1_local <= ram(addr1);
		end if;
	end process;

	port2:process(clk)
	begin
	if(rising_edge(clk)) then
		if(we2 = '1') then
			for i in 0 to BYTES-1 loop
				if(be2(i) = '1') then
					ram(addr2)(BYTES-1-i) <= data_in2(BYTE_WIDTH*(i+1) - 1 downto BYTE_WIDTH*i);
				end if;
			end loop;  -- i
		end if;
		q2_local <= ram(addr2);
	end if;
	end process;

end rtl;
