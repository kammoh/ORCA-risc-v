
library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.top_component_pkg.all;
use work.top_util_pkg.all;

entity top is
  port(
    clk   : in std_logic;
    reset : in std_logic;

    cts : in  std_logic;
    rts : out std_logic;
    txd : out std_logic;
    rxd : in  std_logic;


    R_LED  : out std_logic;
    G_LED  : out std_logic;
    B_LED  : out std_logic;
    HP_LED : out std_logic

    );
end entity;

architecture rtl of top is



  constant REGISTER_SIZE : natural := 32;
  signal RAM_ADR_I       : std_logic_vector(31 downto 0);
  signal RAM_DAT_I       : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal RAM_WE_I        : std_logic;
  signal RAM_CYC_I       : std_logic;
  signal RAM_STB_I       : std_logic;
  signal RAM_SEL_I       : std_logic_vector(REGISTER_SIZE/8-1 downto 0);
  signal RAM_CTI_I       : std_logic_vector(2 downto 0);
  signal RAM_BTE_I       : std_logic_vector(1 downto 0);
  signal RAM_LOCK_I      : std_logic;

  signal RAM_STALL_O : std_logic;
  signal RAM_DAT_O   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal RAM_ACK_O   : std_logic;
  signal RAM_ERR_O   : std_logic;
  signal RAM_RTY_O   : std_logic;

  signal data_ADR_O  : std_logic_vector(31 downto 0);
  signal data_DAT_O  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_WE_O   : std_logic;
  signal data_CYC_O  : std_logic;
  signal data_STB_O  : std_logic;
  signal data_SEL_O  : std_logic_vector(REGISTER_SIZE/8-1 downto 0);
  signal data_CTI_O  : std_logic_vector(2 downto 0);
  signal data_BTE_O  : std_logic_vector(1 downto 0);
  signal data_LOCK_O : std_logic;

  signal data_STALL_I : std_logic;
  signal data_DAT_I   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_ACK_I   : std_logic;
  signal data_ERR_I   : std_logic;
  signal data_RTY_I   : std_logic;

  signal instr_ADR_O  : std_logic_vector(31 downto 0);
  signal instr_DAT_O  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal instr_WE_O   : std_logic;
  signal instr_CYC_O  : std_logic;
  signal instr_STB_O  : std_logic;
  signal instr_SEL_O  : std_logic_vector(REGISTER_SIZE/8-1 downto 0);
  signal instr_CTI_O  : std_logic_vector(2 downto 0);
  signal instr_BTE_O  : std_logic_vector(1 downto 0);
  signal instr_LOCK_O : std_logic;

  signal instr_STALL_I : std_logic;
  signal instr_DAT_I   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal instr_ACK_I   : std_logic;
  signal instr_ERR_I   : std_logic;
  signal instr_RTY_I   : std_logic;


  constant DEBUG_ENABLE  : boolean := true;
  signal debug_en        : std_logic;
  signal debug_write     : std_logic;
  signal debug_writedata : std_logic_vector(7 downto 0);
  signal debug_address   : std_logic_vector(7 downto 0);

  signal serial_in  : std_logic;
  signal rxrdy_n    : std_logic;
  signal cts_n      : std_logic;
  signal serial_out : std_logic;
  signal txrdy_n    : std_logic;
  signal rts_n      : std_logic;
  signal dir_n      : std_logic;

  signal uart_adr_i     : std_logic_vector(7 downto 0);
  signal uart_dat_i     : std_logic_vector(15 downto 0);
  signal uart_dat_o     : std_logic_vector(15 downto 0);
  signal uart_data_32   : std_logic_vector(31 downto 0);
  signal uart_stb_i     : std_logic;
  signal uart_cyc_i     : std_logic;
  signal uart_we_i      : std_logic;
  signal uart_sel_i     : std_logic_vector(3 downto 0);
  signal uart_cti_i     : std_logic_vector(2 downto 0);
  signal uart_bte_i     : std_logic_vector(1 downto 0);
  signal uart_ack_o     : std_logic;
  signal uart_interrupt : std_logic;
  signal uart_debug_ack : std_logic;

  constant UART_ADDR_DAT         : std_logic_vector(7 downto 0) := "00000000";
  constant UART_ADDR_LSR         : std_logic_vector(7 downto 0) := "00000011";
  constant UART_LSR_8BIT_DEFAULT : std_logic_vector(7 downto 0) := "00000011";
  signal uart_stall              : std_logic;
  signal mem_instr_stall         : std_logic;
  signal mem_instr_ack           : std_logic;

  signal rgb_led     : std_logic_vector(2 downto 0);
  signal coe_to_host : std_logic_vector(31 downto 0);
  signal hp_pwm      : std_logic;

  constant SYSCLK_FREQ_HZ         : natural                                     := 12000000;
  constant HEARTBEAT_COUNTER_BITS : positive                                    := log2(SYSCLK_FREQ_HZ);  -- ~1 second to roll over
  signal heartbeat_counter        : unsigned(HEARTBEAT_COUNTER_BITS-1 downto 0) := (others => '0');



begin

  mem : component wb_ram
    generic map(
      SIZE             => 4*1024,
      INIT_FILE_FORMAT => "hex",
      INIT_FILE_NAME   => "test.mem",
      LATTICE_FAMILY   => "iCE5LP")
    port map(
      CLK_I => clk,
      RST_I => reset,

      ADR_I  => RAM_ADR_I,
      DAT_I  => RAM_DAT_I,
      WE_I   => RAM_WE_I,
      CYC_I  => RAM_CYC_I,
      STB_I  => RAM_STB_I,
      SEL_I  => RAM_SEL_I,
      CTI_I  => RAM_CTI_I,
      BTE_I  => RAM_BTE_I,
      LOCK_I => RAM_LOCK_I,

      STALL_O => RAM_STALL_O,
      DAT_O   => RAM_DAT_O,
      ACK_O   => RAM_ACK_O,
      ERR_O   => RAM_ERR_O,
      RTY_O   => RAM_RTY_O);

  arbiter : component wb_arbiter
    port map (
      CLK_I => clk,
      RST_I => reset,

      slave1_ADR_I  => data_ADR_O,
      slave1_DAT_I  => data_DAT_O,
      slave1_WE_I   => data_WE_O,
      slave1_CYC_I  => data_CYC_O,
      slave1_STB_I  => data_STB_O,
      slave1_SEL_I  => data_SEL_O,
      slave1_CTI_I  => data_CTI_O,
      slave1_BTE_I  => data_BTE_O,
      slave1_LOCK_I => data_LOCK_O,

      slave1_STALL_O => data_STALL_I,
      slave1_DAT_O   => data_DAT_I,
      slave1_ACK_O   => data_ACK_I,
      slave1_ERR_O   => data_ERR_I,
      slave1_RTY_O   => data_RTY_I,

      slave2_ADR_I  => instr_ADR_O,
      slave2_DAT_I  => instr_DAT_O,
      slave2_WE_I   => instr_WE_O,
      slave2_CYC_I  => instr_CYC_O,
      slave2_STB_I  => instr_STB_O,
      slave2_SEL_I  => instr_SEL_O,
      slave2_CTI_I  => instr_CTI_O,
      slave2_BTE_I  => instr_BTE_O,
      slave2_LOCK_I => instr_LOCK_O,

      slave2_STALL_O => mem_instr_stall,
      slave2_DAT_O   => instr_DAT_I,
      slave2_ACK_O   => mem_instr_ACK,
      slave2_ERR_O   => instr_ERR_I,
      slave2_RTY_O   => instr_RTY_I,

      master_ADR_O  => RAM_ADR_I,
      master_DAT_O  => RAM_DAT_I,
      master_WE_O   => RAM_WE_I,
      master_CYC_O  => RAM_CYC_I,
      master_STB_O  => RAM_STB_I,
      master_SEL_O  => RAM_SEL_I,
      master_CTI_O  => RAM_CTI_I,
      master_BTE_O  => RAM_BTE_I,
      master_LOCK_O => RAM_LOCK_I,

      master_STALL_I => ram_STALL_O,
      master_DAT_I   => RAM_DAT_O,
      master_ACK_I   => RAM_ACK_O,
      master_ERR_I   => RAM_ERR_O,
      master_RTY_I   => RAM_RTY_O);

  rv : component riscV_wishbone
    port map(

      clk   => clk,
      reset => reset,

      --conduit end point
      coe_to_host   => coe_to_host,
      coe_from_host => (others => '0'),
      --coe_program_counter =>

      data_ADR_O   => data_ADR_O,
      data_DAT_I   => data_DAT_I,
      data_DAT_O   => data_DAT_O,
      data_WE_O    => data_WE_O,
      data_SEL_O   => data_SEL_O,
      data_STB_O   => data_STB_O,
      data_ACK_I   => data_ACK_I,
      data_CYC_O   => data_CYC_O,
      data_STALL_I => data_STALL_I,
      data_CTI_O   => data_CTI_O,

      instr_ADR_O   => instr_ADR_O,
      instr_DAT_I   => instr_DAT_I,
      instr_DAT_O   => instr_DAT_O,
      instr_WE_O    => instr_WE_O,
      instr_SEL_O   => instr_SEL_O,
      instr_STB_O   => instr_STB_O,
      instr_ACK_I   => instr_ACK_I,
      instr_CYC_O   => instr_CYC_O,
      instr_CTI_O   => instr_CTI_O,
      instr_STALL_I => instr_STALL_I);

  data_BTE_O  <= "00";
  data_LOCK_O <= '0';

  instr_BTE_O  <= "00";
  instr_LOCK_O <= '0';

  instr_stall_i <= uart_stall or mem_instr_stall;
  instr_ack_i   <= not uart_stall and mem_instr_ack;

  rgb_led <=
    "000" when heartbeat_counter(6 downto 0) /= "0000001" else
    "111" when reset = '1' else
    "001" when coe_to_host = std_logic_vector(to_unsigned(0, coe_to_host'length)) else
    "010" when coe_to_host = std_logic_vector(to_unsigned(1, coe_to_host'length)) else
    "100";

  led : component my_led
    port map(
      red_i   => rgb_led(2),
      green_i => rgb_led(1),
      blue_i  => rgb_led(0),
      hp_i    => hp_pwm,
      red     => R_LED,
      green   => G_LED,
      blue    => B_LED,
      hp      => HP_LED
      );

  hp_pwm <= heartbeat_counter(heartbeat_counter'left) when heartbeat_counter(7 downto 0) = "00000001" else '0';


  process(clk, reset)
  begin
    if rising_edge(clk) then
      heartbeat_counter <= heartbeat_counter + to_unsigned(1, heartbeat_counter'length);
    end if;
  end process;



-----------------------------------------------------------------------------
-- Debugging logic (PC over UART)
-----------------------------------------------------------------------------
  debug_gen : if DEBUG_ENABLE generate
    signal last_valid_address : std_logic_vector(31 downto 0);
    signal last_valid_data    : std_logic_vector(31 downto 0);
    type debug_state_type is (INIT, IDLE, SPACE, ADR, DAT, CR, LF);
    signal debug_state        : debug_state_type;
    signal debug_count        : unsigned(log2((last_valid_data'length+3)/4)-1 downto 0);
    signal debug_wait         : std_logic;

    --Convert a hex digit to ASCII for outputting on the UART
    function to_ascii_hex (
      signal hex_in : std_logic_vector)
      return std_logic_vector is
    begin
      if unsigned(hex_in) > to_unsigned(9, hex_in'length) then
        --value + 'A' - 10
        return std_logic_vector(resize(unsigned(hex_in), 8) + to_unsigned(55, 8));
      end if;

      --value + '0'
      return std_logic_vector(resize(unsigned(hex_in), 8) + to_unsigned(48, 8));
    end to_ascii_hex;


  begin
    process (clk)
    begin  -- process
      if clk'event and clk = '1' then   -- rising clock edge
        case debug_state is
          when INIT =>
            debug_address   <= UART_ADDR_LSR;
            debug_writedata <= UART_LSR_8BIT_DEFAULT;
            debug_write <= '1';
            if debug_write = '1' and debug_wait = '0' then
              debug_state   <= IDLE;
              debug_address <= UART_ADDR_DAT;
              debug_write <= '0';
            end if;
          when IDLE =>
            uart_stall         <= '1';
            if instr_CYC_O = '1' then
              debug_write <= '1';
              last_valid_address <= instr_ADR_O(instr_ADR_O'left-4 downto 0) & "0000";
              debug_writedata    <= to_ascii_hex(instr_ADR_O(last_valid_address'left downto last_valid_address'left-3));
              debug_state        <= ADR;
              debug_count        <= to_unsigned(0, debug_count'length);
            end if;
          when ADR =>
            if debug_wait = '0' then
              if debug_count = to_unsigned(((last_valid_address'length+3)/4)-1, debug_count'length) then
                debug_writedata <= std_logic_vector(to_unsigned(32, 8));
                debug_count     <= to_unsigned(0, debug_count'length);
                debug_state     <= SPACE;
                last_valid_data <= instr_DAT_I;
              else
                debug_writedata    <= to_ascii_hex(last_valid_address(last_valid_address'left downto last_valid_address'left-3));
                last_valid_address <= last_valid_address(last_valid_address'left-4 downto 0) & "0000";
                debug_count        <= debug_count + to_unsigned(1, debug_count'length);
              end if;
            end if;
          when SPACE =>
            if debug_wait = '0' then
              debug_writedata <= to_ascii_hex(last_valid_data(last_valid_data'left downto last_valid_data'left-3));
              last_valid_data <= last_valid_data(last_valid_data'left-4 downto 0) & "0000";
              debug_state     <= DAT;
            end if;
          when DAT =>
            if debug_wait = '0' then
              if debug_count = to_unsigned(((last_valid_data'length+3)/4)-1, debug_count'length) then
                debug_writedata <= std_logic_vector(to_unsigned(13, 8));
                debug_count     <= to_unsigned(0, debug_count'length);
                debug_state     <= CR;
              else
                debug_writedata <= to_ascii_hex(last_valid_data(last_valid_data'left downto last_valid_data'left-3));
                last_valid_data <= last_valid_data(last_valid_data'left-4 downto 0) & "0000";
                debug_count     <= debug_count + to_unsigned(1, debug_count'length);
              end if;
            end if;

          when CR =>
            if debug_wait = '0' then
              debug_writedata <= std_logic_vector(to_unsigned(10, 8));
              debug_state     <= LF;
            end if;
          when LF =>
            if debug_wait = '0' then
              debug_write <= '0';
              debug_state     <= IDLE;
              uart_stall      <= '0';
            end if;

          when others =>
            debug_state <= IDLE;
        end case;

        if reset = '1' then
          debug_state <= INIT;
          debug_write <= '0';
          uart_stall  <= '1';
        end if;
      end if;
    end process;
    debug_wait <= not uart_ack_o;
  end generate debug_gen;
  no_debug_gen : if not DEBUG_ENABLE generate
    debug_write     <= '0';
    debug_writedata <= (others => '0');
    debug_address   <= (others => '0');
  end generate no_debug_gen;

  -----------------------------------------------------------------------------
  -- UART signals and interface
  -----------------------------------------------------------------------------
  --PmodUSBUART (0->RTS, 1->RXD, 2->TXD, 3->CTS)
  cts_n     <= not cts;
  txd       <= serial_out;
  serial_in <= rxd;
  rts       <= rts_n;
  the_uart : uart_core
    generic map (
      CLK_IN_MHZ => (SYSCLK_FREQ_HZ+500000)/1000000,
      BAUD_RATE  => 115200,
      ADDRWIDTH  => 3,
      DATAWIDTH  => 8,
      MODEM_B    => false,              --true by default...
      FIFO       => false
      )
    port map (
      -- Global reset and clock
      CLK        => clk,
      RESET      => reset,
      -- WISHBONE interface
      UART_ADR_I => uart_adr_i,
      UART_DAT_I => uart_dat_i,
      UART_DAT_O => uart_dat_o,
      UART_STB_I => uart_stb_i,
      UART_CYC_I => uart_cyc_i,
      UART_WE_I  => uart_we_i,
      UART_SEL_I => uart_sel_i,
      UART_CTI_I => uart_cti_i,
      UART_BTE_I => uart_bte_i,
      UART_ACK_O => uart_ack_o,
      INTR       => uart_interrupt,
      -- Receiver interface
      SIN        => serial_in,
      RXRDY_N    => rxrdy_n,
      -- MODEM
      DCD_N      => '1',
      CTS_N      => cts_n,
      DSR_N      => '1',
      RI_N       => '1',
      DTR_N      => dir_n,
      RTS_N      => rts_n,
      -- Transmitter interface
      SOUT       => serial_out,
      TXRDY_N    => txrdy_n
      );


  -----------------------------------------------------------------------------
  -- WISHBONE interconnect
  -----------------------------------------------------------------------------
  uart_dat_i(15 downto 8) <= (others => '0');
  uart_dat_i(7 downto 0)  <= debug_writedata;
  uart_we_i               <= debug_write;

  uart_stb_i <= uart_we_i and (not txrdy_n);
  uart_adr_i <= debug_address;
  uart_cyc_i <= uart_stb_i and (not txrdy_n);

  uart_cti_i <= WB_CTI_CLASSIC;


end architecture rtl;
