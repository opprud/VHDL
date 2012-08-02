LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tb_spi16 IS
END tb_spi_16;

ARCHITECTURE behavioural OF tb_spi16 IS
    
    -- inputs
    signal clk      :std_logic := '0';
    signal reset    :std_logic := '0';
    signal en       :std_logic := '0';
    signal wdata    :std_logic_vector(15 downto 0) := (others -> '0');
    signal spi_data :std_logic := '0';
    -- OUTPUTS
    signal ack      :std_logic := '0';
    signal sck      :std_logic := '0';
    signal sdo      :std_logic := '0';
    signal cs       :std_logic := '0';
    signal rdata    :std_logic_vector(15 downto 0) := (others -> '0');

    -- spi rx data
    signal rdata    :std_logic_vector(15 downto 0) := X"1234";
    
    begin    
    
    --instantiate uut
    uut : entity work.spi_16(arch)
        port map( clk_i => clk, rst_i => reset, en_i => en, data_i => wdata, sdi_i =>spi_data
               ack_o => ack, sck_o => sck, sdo_o => sdo, cs_o => cs, data_o => rdata );
        
    
    -- 100 MHz Clock process
    Clk_i_process :process
    begin
        Clk_i <= '0';
        wait for 5 ns;
        Clk_i <= '1';
        wait for 5 ns;
    end process;
    
    
    -- Stimulus process
   stim_proc: process
   begin        

        -- write
        reset <= '1';
        wait for 50 ns;
        reset <= '0';
        wdata <= "0000111100110101";
        wait for 10 ns;
        en <= '1';
        wait for 10 ns;
        en <= '0';
        wait until (ack = '1');
        
        -- read
        wait for 10 ns;
        en <= '1';
        wait for 10 ns;
        en <= '0';
       
        FOR i IN 0 TO 15 LOOP
            wait for 20 ns;
            spi_data <= rdata(15-i);
            wait for 20 ns;
        END LOOP;

        wait for 300 ns;
    
    end process;
    
    end;