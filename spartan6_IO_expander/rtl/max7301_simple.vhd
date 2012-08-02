--------------------------------------------------------------------------------
--! @file       max7301_simple.vhd
--! @ingroup    RTL
--!
--! @brief      Controller for acessing MAX 7301 via SPI. Input / output directions \n 
--!             are to be instantiaed, default are outputs.
--!             controller runs continiously   
--             
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity max7301_simple is
    port  (
        -- Application interface :
        clk_i       :   in std_logic;        -- input clock, xx MHz.
        rst_i       :   in std_logic;        -- sync reset.
        en_i        :   in std_logic;        -- enable, forces re-init of pins on MAX7301.
        output_i    :   in std_logic_vector(27 downto 0);   --data to write to output pins on MAX7301
        irq_o       :   out std_logic;       -- IRQ, TODO: what triggers, change on inputs ?
        input_o     :   out std_logic_vector(27 downto 0);  --data read from input pins on MAX7301
        -- MAX7301 SPI interface
        sclk        :   in std_logic;        -- SPI clock
        din         :   in std_logic;        -- SPI data input
        dout        :   out std_logic;       -- SPI read data
        cs          :   out std_logic        -- SPI chip select
    );
end max7301_simple;

architecture arch of max7301_simple is

    -- PORT configuration data
    TYPE MAX7301_Init_t IS ARRAY (1 to 7) OF INTEGER;
    CONSTANT MAX7301_Init : MAX7301_Init_t := (X"0911",X"0A22",X"0B33",X"0C44",X"0D55",X"0E66",X"OF77");
    -- PORT address definitions    
    TYPE MAX7301_Port_Addr_t IS ARRAY (1 to 8) OF INTEGER;
    CONSTANT MAX7301_RW_Addr : MAX7301_Port_Addr_t := (X"5C",X"00",X"54",X"00",X"4C",X"00",X"44"X"00"); -- NOTE read and write are combined, eg 1:write read register addres, 2: write output data and read input from "1"
    -- CONTROLLER states
    Type   maxStateType is (INIT, DO_SETUP, IDLE, DO_READ, LATCH, DO_WRITE);
    signal state_next, state_reg: maxStateType;
    -- MISC signals
    signal spi_ack      :       std_logic;
    signal cnt_en       :       std_logic;
    signal cnt_reset    :       std_logic;
    signal cnt          :       std_logic_vector(3 downto 0);
    signal n            :       integer range 0 to 7; 
    signal txdata       :       std_logic_vector(15 downto 0);
    signal rxdata       :       std_logic_vector(15 downto 0);
    signal i            :       integer range 0 to 15; 
    -- shift register for assembling incoming spi data 
    signal si_next      :       std_logic_vector(27 downto 0);
    signal si_reg       :       std_logic_vector(27 downto 0);
    
begin

    -- instantiate a 4 bit binary counter for indexing spi transfers
    counter: entity work.free_run_bin_counter(arch)
        generic map(N=>4)
        port map(clk=>clk_i, reset=>cnt_rst, en=>cnt_en, q=>cnt, max_tick=>open);

    spi: entity work.spi_16(arch)
        port map(clk_i => clk_i, rst_i => rst_i, en_i => en_i, ack_o => spi_ack, data_i => txdata, data_o => rxdata, sck_o => sclk , sdo_o => dout , sdi_i => din , cs_o => cs )

    -- connect i and use to hold ack's and index SPI data arrays
    i <= to_integer(unsigned(cnt(3 downto 0)));


    -- register
    process(clk_i,rst_i)
    begin
        if (clk_i'event and clk_i='1') then
            if (rst_i='1') then
                state_reg <= IDLE;
                si_reg <= (others => '0');
            else           
                state_reg <= state_next;
                si_reg <= si_next;
            end if;
        end if;
    end process;
    
    
    -- next-state logic
    process(state_reg, en_i, i)
    begin
        -- default assignments
        state_next <= state_reg;
        si_next <= si_reg;
        case state_reg is        
            when RESET =>
               if(en_i = '1') then
                    state_next <= DO_SETUP;
                end if;
            --when INIT =>
                
            when DO_SETUP =>
                -- fisished doing setup ?
                if(spi_ack = '1') then
                    if(i = 8) then
                        state_next = IDLE;
                    end if;
                end if;
            
            when IDLE =>
                if(en_i = '0') then
                    state_next <= RESET;
                else
                    state_next <= DO_READ;
                end if;
                
            
            when DO_READ =>
                if(spi_ack = '1') then
                    state_next <= DO_WRITE;
                end if;
    
            --when LATCH =>
                --if(n = 15) then
            when DO_WRITE =>
                if(spi_ack = '1') then
                    -- read and concatenate incoming data, also shift left << 8
                    -- lower 8 LSB's of rxdata are to be used
                    si_next <= si_reg(20 downto 0) & rxdata(7 downto 0);
                    -- fisnished writing and reading 4 registers (=8 spi_ack's) ?
                    if(i = 8) then
                        state_next <= IDLE;
                    end if;
                end if;
            when others =>        
        end case;
    end process;    
    
    --output logic
    -- reset counter before init or read/write
    cnt_rst <= '1' when ( (state_reg = RESET) or (state_reg = IDLE) )  else '1';
    -- count spi_ack's in "cnt"
    cnt_en <= spi_ack;
    -- select dataset from init or RW array, based on state
    txdata <= MAX7301_Init(i) when (state_reg = DO_SETUP) else MAX7301_RW_Addr(i);

end arch;

