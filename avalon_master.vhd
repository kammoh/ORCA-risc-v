library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity avalon_master is
  generic (
    DATA_WIDTH : natural;
    ADDR_WIDTH : natural);
  port (
    clk : in std_logic;

    --CPU signals
    read_enable  : in  std_logic;
    write_enable : in  std_logic;
    byte_enable  : in  std_logic_vector(DATA_WIDTH/8 -1 downto 0);
    address      : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    write_data   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    read_data    : out std_logic_vector(DATA_WIDTH-1 downto 0);
    xfer_in_prog : out std_logic;


    --avalon bus signals
    av_address       : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    av_byteenable    : out std_logic_vector(DATA_WIDTH/8 -1 downto 0);
    av_read          : out std_logic;
    av_readdata      : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    av_response      : in  std_logic_vector(1 downto 0);
    av_write         : out std_logic;
    av_writedata     : out std_logic_vector(DATA_WIDTH-1 downto 0);
    av_lock          : out std_logic;
    av_waitrequest   : in  std_logic;
    av_readdatavalid : in  std_logic);
end entity avalon_master;

architecture rtl of avalon_master is
  signal wait_request_mask : std_logic;
  signal readvalid_mask    : std_logic;
begin  -- architecture rtl
  av_read  <= read_enable;
  av_write <= write_enable;

  process(clk)
    type state_t is (ADDR_ASSERT, WAIT_REQUEST, WAIT_STATE, READVALID);
    variable state : state_t := ADDR_ASSERT;
  begin
    if rising_edge(clk) then
      case state is
        when ADDR_ASSERT =>
          av_address <= address;
          av_write   <= write_enable;
          av_read    <= read_enable;
          if write_enable = '1' or read_enable = '1' then
            state             := WAIT_REQUEST;
            wait_request_mask <= '1';
          else
            wait_request_mask <= '0';
          end if;
        when WAIT_REQUEST =>
          --stay in this state unit
          --waitrequest is deasserted
          if av_waitrequest = '0' then
            wait_request_mask <= '0';
            if read_enable = '1' then
              --transfer is a read
              --check if we are done or
              --if we have to wait
              if av_readdatavalid = '1' then
                read_data <= av_readdata;
                state     := ADDR_ASSERT;
              else
                readvalid_mask <= '1';
                state          := WAIT_STATE;
              end if;
            else
              --transfer is a write,
              --we are done
              state := ADDR_ASSERT;
            end if;
          end if;
        when WAIT_STATE =>
          if av_readdatavalid = '1' then
            read_data <= av_readdata;
            state     := ADDR_ASSERT;
            readvalid_mask <= '0';
          end if;

        when others =>
          state := ADDR_ASSERT;
      end case;
    end if;
  end process;

  xfer_in_prog <= (wait_request_mask and av_waitrequest) or
                  (readvalid_mask and not av_readdatavalid);

end architecture rtl;
