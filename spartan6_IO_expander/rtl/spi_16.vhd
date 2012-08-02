--------------------------------------------------------------------------------
--! @file       spi_16.chd
--! @ingroup    RTL
--!
--! @brief      SPI 16 bitCore. usage, read and write only data when ack_o is \n
--!             set and en_i is deasserted
--!             
--------------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

entity spi_16 is
    port  (
        -- global signals
        clk_i         :   in std_logic;       -- input clock, xx MHz.
        rst_i         :   in std_logic;       -- sync reset
        -- control / status / data
        en_i          :   in std_logic;       -- enable & start 16 bit transfer
        ack_o         :   out std_logic;      -- 1 clk tick when transfer completed
        data_i        :   in std_logic_vector ( 15 downto 0 );     -- parrallel write data to slave
        data_o        :   out std_logic_vector ( 15 downto 0 );    -- parralel read data from slave
        --SPI signals
        sck_o         :   out std_logic;      -- SPI clk 25 or 50MHz
        sdo_o         :   out std_logic;      -- SPI data out
        sdi_i         :   in  std_logic;      -- SPI data input
        cs_o          :   out std_logic       -- SPI chip select
    );
end spi_16;


architecture arch of spi_16 is

    Type   SpiStateType is (IDLE, RUN, DONE);
    signal state_next, state_reg: SpiStateType;
    signal tick         :       std_logic;
    signal cnt_rst      :       std_logic;
    signal sample_tick  :       std_logic;
    signal cnt          :       std_logic_vector(5 downto 0);
    signal n            :       integer range 0 to 16; 
    signal i            :       integer range 0 to 31; 
       
begin

    -- instantiate a 6 bit binary counter for prescling clock, and 16 bit index counter
    counter: entity work.free_run_bin_counter(arch)
        generic map(N=>6)
        port map(clk=>clk_i, reset=>cnt_rst, en=>'1', q=>cnt, max_tick=>tick);
  
    --instantiate a 16 bit shift register
    shiftreg:entity work.univ_shift_reg(arch)
        generic map(N=>16)
        port map(clk=>clk_i, reset=>rst_i, ctrl => ("0" &  sample_tick), d=> ("000000000000000" & sdi_i), q => data_o);
  
    -- data is to be sampled after the falling edge clock
    -- (sample point is *)
    -- Clk          --  --  --  --  --  --  --  --  
    --            --  --  --  --  --  --  --  --  --
    -- 
    -- Cnt[0]       ----    ----    ----    ----
    --            --    ----    *---    ----    ----
    -- 
    -- Cnt[1]       --------        --------
    -- (sck)      --        ----*---        --------
    -- 
    sample_tick <=  cnt(0);
    --sample_tick <= ((not cnt(1) and cnt(0)));
        
    -- connect SPI clock to LSB+1 (clk_i / 2)
    sck_o <= cnt(0);
    -- connect SDO to parralel tx data- we need to sent MSB first
    sdo_o <= data_i(15 - n);
    -- connect n, and use as index
    n <= to_integer(unsigned(cnt(4 downto 1)));
    -- connect i and use to count spi clk 
    i <= to_integer(unsigned(cnt(5 downto 1)));
      

    -- register
    process(clk_i,rst_i)
    begin
        if (clk_i'event and clk_i='1') then
            if (rst_i='1') then
                state_reg <= IDLE;
            else           
                state_reg <= state_next;
            end if;
        end if;
    end process;
    
    
    -- next-state logic
    process(state_reg, en_i, n)
    begin
        case state_reg is        
            when IDLE =>
                if(en_i = '1') then
                    state_next <= RUN;
                end if;
                
            when RUN =>
                --if(n = 15) then
                if(i = 16) then
                    state_next <= DONE;
                end if;
                
            when DONE =>
                state_next <= IDLE;
            when others =>        
        end case;
    end process;    
    
       
    -- output logic (mealy type)
    cnt_rst <= '0' when (state_reg = RUN)  else '1';
    cs_o    <= '0' when (state_reg = RUN)  else '1';
    ack_o   <= '1' when (state_reg = DONE) else '0';
end arch;

