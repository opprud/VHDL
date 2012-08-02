LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tb_spi16 IS
END tb_spi_16;

ARCHITECTURE behavioural OF tb_spi16 IS
    
    -- control / data signals from app
    signal clk      :std_logic := '0';
    signal reset    :std_logic := '0';
    signal en       :std_logic := '0';
    signal irq      :std_logic := '0';
    signal wdata    :std_logic_vector(27 downto 0) := (others -> '0');
    signal rdata    :std_logic_vector(27 downto 0) := (others -> '0');
    -- MAX7301 interface
    signal sclk     :std_logic := '0';
    signal din      :std_logic := '0';
    signal dout     :std_logic := '0';
    signal cs       :std_logic := '0';
    
    begin    
    
    --instantiate uut
    uut : entity work.max7301_simple(arch)
        port map( clk_i => clk, rst_i => reset, en_i => en, output_i => wdata ,
                  irq_o => irq ,input_o => rdata , sclk => sclk , din => din ,
                  dout => dout ,cs => cs );
    
    -- 100 MHz Clock process
    Clk_i_process :process
    begin
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
    end process;
    
    
    -- Stimulus process
   stim_proc: process
   begin        

        -- write
        reset <= '1';
        wait for 50 ns;
        reset <= '0';
        wdata <= "0000111100110101111100000111";
        wait for 10 ns;
        en <= '1';       
        wait for 3000 ns;
    
    end process;
    
    end;