-- top_component_pkg.vhd
-- Copyright (C) 2015 VectorBlox Computing, Inc.

-- Component declarations

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.top_util_pkg.all;

package top_component_pkg is

  component uart_core
    generic(
      CLK_IN_MHZ : integer := 25;
      BAUD_RATE  : integer := 115200;
      ADDRWIDTH  : integer := 3;
      DATAWIDTH  : integer := 8;
      MODEM_B    : boolean := true;
      FIFO       : boolean := false
      );
    port(
-- Global reset and clock
      CLK        : in  std_logic;
      RESET      : in  std_logic;
-- wishbone interface
      UART_ADR_I : in  std_logic_vector(7 downto 0);
      UART_DAT_I : in  std_logic_vector(15 downto 0);
      UART_DAT_O : out std_logic_vector(15 downto 0);
      UART_STB_I : in  std_logic;
      UART_CYC_I : in  std_logic;
      UART_WE_I  : in  std_logic;
      UART_SEL_I : in  std_logic_vector(3 downto 0);
      UART_CTI_I : in  std_logic_vector(2 downto 0);
      UART_BTE_I : in  std_logic_vector(1 downto 0);
      UART_ACK_O : out std_logic;
      INTR       : out std_logic;
-- Receiver interface
      SIN        : in  std_logic;
      RXRDY_N    : out std_logic;
-- Transmitter interface
--Generate --if MODEM

--begin
      DCD_N : in  std_logic;
      CTS_N : in  std_logic;
      DSR_N : in  std_logic;
      RI_N  : in  std_logic;
      DTR_N : out std_logic;
      RTS_N : out std_logic;

--end Generate ;
--
      SOUT    : out std_logic;
      TXRDY_N : out std_logic
      );
  end component;

  component my_led
    port (
      red_i   : in  std_logic;
      green_i : in  std_logic;
      blue_i  : in  std_logic;
      hp_i    : in  std_logic;
      red     : out std_logic;
      green   : out std_logic;
      blue    : out std_logic;
      hp      : out std_logic);
  end component;

  component riscV_wishbone is
    generic (
      REGISTER_SIZE : integer := 32;
      RESET_VECTOR  : natural := 16#00000200#);
    port(
      clk   : in std_logic;
      reset : in std_logic;

      --conduit end point
      coe_to_host         : out std_logic_vector(REGISTER_SIZE -1 downto 0);
      coe_from_host       : in  std_logic_vector(REGISTER_SIZE -1 downto 0);
      coe_program_counter : out std_logic_vector(REGISTER_SIZE -1 downto 0);

      data_ADR_O   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_DAT_I   : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_DAT_O   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_WE_O    : out std_logic;
      data_SEL_O   : out std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
      data_STB_O   : out std_logic;
      data_ACK_I   : in  std_logic;
      data_CYC_O   : out std_logic;
      data_CTI_O   : out std_logic_vector(2 downto 0);
      data_STALL_I : in  std_logic;

      instr_ADR_O   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      instr_DAT_I   : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      instr_DAT_O   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      instr_WE_O    : out std_logic;
      instr_SEL_O   : out std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
      instr_STB_O   : out std_logic;
      instr_ACK_I   : in  std_logic;
      instr_CYC_O   : out std_logic;
      instr_CTI_O   : out std_logic_vector(2 downto 0);
      instr_STALL_I : in  std_logic

      );
  end component riscV_wishbone;

  component wb_ram is
    generic (
      size             : integer := 4096;
      DATA_WIDTH       : integer := 32;
      INIT_FILE_FORMAT : string  := "hex";
      INIT_FILE_NAME   : string  := "none";
      LATTICE_FAMILY   : string  := "ICE40");
    port (
      CLK_I : in std_logic;
      RST_I : in std_logic;

      ADR_I  : in std_logic_vector(31 downto 0);
      DAT_I  : in std_logic_vector(DATA_WIDTH-1 downto 0);
      WE_I   : in std_logic;
      CYC_I  : in std_logic;
      STB_I  : in std_logic;
      SEL_I  : in std_logic_vector(DATA_WIDTH/8-1 downto 0);
      CTI_I  : in std_logic_vector(2 downto 0);
      BTE_I  : in std_logic_vector(1 downto 0);
      LOCK_I : in std_logic;

      STALL_O : out std_logic;
      DAT_O   : out std_logic_vector(DATA_WIDTH-1 downto 0);
      ACK_O   : out std_logic;
      ERR_O   : out std_logic;
      RTY_O   : out std_logic);
  end component wb_ram;

  component wb_arbiter is
    generic (
      PRIORITY_SLAVE : integer := 1;    --slave which always gets priority
      DATA_WIDTH     : integer := 32
      );
    port (
      CLK_I : in std_logic;
      RST_I : in std_logic;

      slave1_ADR_I : in std_logic_vector(31 downto 0);
      slave1_DAT_I : in std_logic_vector(DATA_WIDTH-1 downto 0);
      slave1_WE_I  : in std_logic;
      slave1_CYC_I : in std_logic;
      slave1_STB_I : in std_logic;
      slave1_SEL_I : in std_logic_vector(DATA_WIDTH/8-1 downto 0);
      slave1_CTI_I : in std_logic_vector(2 downto 0);
      slave1_BTE_I : in std_logic_vector(1 downto 0);

      slave1_LOCK_I : in std_logic;

      slave1_STALL_O : out std_logic;
      slave1_DAT_O   : out std_logic_vector(DATA_WIDTH-1 downto 0);
      slave1_ACK_O   : out std_logic;
      slave1_ERR_O   : out std_logic;
      slave1_RTY_O   : out std_logic;

      slave2_ADR_I : in std_logic_vector(31 downto 0);
      slave2_DAT_I : in std_logic_vector(DATA_WIDTH-1 downto 0);
      slave2_WE_I  : in std_logic;
      slave2_CYC_I : in std_logic;
      slave2_STB_I : in std_logic;
      slave2_SEL_I : in std_logic_vector(DATA_WIDTH/8-1 downto 0);
      slave2_CTI_I : in std_logic_vector(2 downto 0);
      slave2_BTE_I : in std_logic_vector(1 downto 0);

      slave2_LOCK_I : in std_logic;

      slave2_STALL_O : out std_logic;
      slave2_DAT_O   : out std_logic_vector(DATA_WIDTH-1 downto 0);
      slave2_ACK_O   : out std_logic;
      slave2_ERR_O   : out std_logic;
      slave2_RTY_O   : out std_logic;

      master_ADR_O  : out std_logic_vector(31 downto 0);
      master_DAT_O  : out std_logic_vector(DATA_WIDTH-1 downto 0);
      master_WE_O   : out std_logic;
      master_CYC_O  : out std_logic;
      master_STB_O  : out std_logic;
      master_SEL_O  : out std_logic_vector(DATA_WIDTH/8-1 downto 0);
      master_CTI_O  : out std_logic_vector(2 downto 0);
      master_BTE_O  : out std_logic_vector(1 downto 0);
      master_LOCK_O : out std_logic;

      master_STALL_I : in std_logic;
      master_DAT_I   : in std_logic_vector(DATA_WIDTH-1 downto 0);
      master_ACK_I   : in std_logic;
      master_ERR_I   : in std_logic;
      master_RTY_I   : in std_logic


      );
  end component;

end package;

package body top_component_pkg is
end top_component_pkg;
