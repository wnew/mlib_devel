----------------------------------------------------------------------------
-- Import useful libraries
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

-- entity declaraction
entity  adc_unit  is
    port (
               -- System
               fabric_clk    :  in std_logic;
               line_clk      :  in std_logic;
               frame_clk     :  in std_logic;
               reset         :  in std_logic;

               -- ZDOK
               ser_a_p       :  in  std_logic_vector(3 downto 0);
               ser_a_n       :  in  std_logic_vector(3 downto 0);
               ser_b_p       :  in  std_logic_vector(3 downto 0);
               ser_b_n       :  in  std_logic_vector(3 downto 0);

               -- ISERDES Controller
               iserdes_bitslip  :  in  std_logic;
               p_data           :  out std_logic_vector(31 downto 0);

               -- IODELAY Controller
               delay_rst_a      :  in  std_logic_vector(3 downto 0);
               delay_rst_b      :  in  std_logic_vector(3 downto 0);
               delay_tap        :  in  std_logic_vector(4 downto 0)
    );

end  adc_unit;

architecture adc_unit_arc of adc_unit is

     -- Components
      component IODELAYE1 generic(
         CINVCTRL_SEL           :  boolean;         -- TRUE, FALSE
         DELAY_SRC              :  string;          -- I, IO, O, CLKIN, DATAIN
         HIGH_PERFORMANCE_MODE  :  boolean;         -- TRUE, FALSE
         IDELAY_TYPE            :  string;          -- FIXED, DEFAULT, VARIABLE, or VAR_LOADABLE
         IDELAY_VALUE           :  integer;         -- 0 to 31
         ODELAY_TYPE            :  string;          -- Has to be set to FIXED when IODELAYE1 is configured for Input
         ODELAY_VALUE           :  integer;         -- Set to 0 as IODELAYE1 is configured for Input
         REFCLK_FREQUENCY       :  real;
         SIGNAL_PATTERN         :  string           -- CLOCK, DATA
         );
       port (
         DATAOUT                : out std_logic;
         DATAIN                 : in  std_logic;
         C                      : in  std_logic;
         CE                     : in  std_logic;
         INC                    : in  std_logic;
         IDATAIN                : in  std_logic;
         ODATAIN                : in  std_logic;
         RST                    : in  std_logic;
         T                      : in  std_logic;
         CNTVALUEIN             : in  std_logic_vector(4 downto 0);
         CNTVALUEOUT            : out std_logic_vector(4 downto 0);
         CLKIN                  : in  std_logic;
         CINVCTRL               : in  std_logic
         );
      end component;

     component ADC_ISERDES   port (
               -- System
               reset        :  in  std_logic;
               bitslip      :  in  std_logic;

               -- Clock inputs
               clkin        :  in  std_logic; -- line
               clkdiv       :  in  std_logic; -- frame/system

               -- Data (serial in, parallel out)
               s_data       :  in  std_logic;
               p_data       :  out std_logic_vector(7 downto 0)
      );
     end component;

     component IBUFDS  generic (
               DIFF_TERM    : boolean;
               IOSTANDARD   : string
     );
     port (
               I            : in  std_logic;
               IB           : in  std_logic;
               O            : out std_logic
     );
     end component;

     -- Signals
     signal adc_iserdes_data_a : std_logic_vector(31 downto 0);
     signal adc_iserdes_data_b : std_logic_vector(31 downto 0);
     signal adc_iserdes_data_a_pipelined : std_logic_vector(31 downto 0);
     signal adc_iserdes_data_b_pipelined : std_logic_vector(31 downto 0);
     signal adc_iserdes_data : std_logic_vector(31 downto 0);

     signal ibuf_ser_a : std_logic_vector(3 downto 0);
     signal ibuf_ser_b : std_logic_vector(3 downto 0);

     signal delay_a_out     : std_logic_vector(3 downto 0);
     signal delay_b_out     : std_logic_vector(3 downto 0);

     begin

     process (fabric_clk, frame_clk, adc_iserdes_data_a, adc_iserdes_data_b)
     begin
       -- Pipeline serdes outputs (using slower frame clock)
       if frame_clk'event and frame_clk = '1' then
         adc_iserdes_data_a_pipelined <= adc_iserdes_data_a;
         adc_iserdes_data_b_pipelined <= adc_iserdes_data_b;
       end if;

       -- Mux pipelined data based on framing clock
       if frame_clk = '1' then
         adc_iserdes_data <= adc_iserdes_data_a_pipelined;
       else
         adc_iserdes_data <= adc_iserdes_data_b_pipelined;
       end if;

       -- Capture mux output on rising edge of fabric clock
       if fabric_clk'event and fabric_clk = '1' then
         p_data <= adc_iserdes_data;
       end if;
     end process;

     -- ISERDES block
     ISERDES_GEN : for i in 0 to 3 generate
     begin
     adc_iserdes_a_inst : ADC_ISERDES
     PORT MAP (
               reset      => reset,
               bitslip    => iserdes_bitslip,
               clkin      => line_clk,
               clkdiv     => frame_clk,
               s_data     => delay_a_out(i),
               p_data     => adc_iserdes_data_a(8*(3-i)+7 downto 8*(3-i))
      );

     adc_iserdes_b_inst : ADC_ISERDES
     PORT MAP (
               reset      => reset,
               bitslip    => iserdes_bitslip,
               clkin      => line_clk,
               clkdiv     => frame_clk,
               s_data     => delay_b_out(i),
               p_data     => adc_iserdes_data_b(8*(3-i)+7 downto 8*(3-i))
      );

     ibufds_ser_a_inst : IBUFDS
     generic map (
               DIFF_TERM  => TRUE,
               IOSTANDARD => "LVDS_25")
     port map (
               I   => ser_a_p(i),
               IB  => ser_a_n(i),
               O   => ibuf_ser_a(i)
     );

     ibufds_ser_b_inst : IBUFDS
     generic map (
               DIFF_TERM  => TRUE,
               IOSTANDARD => "LVDS_25")
     port map (
               I   => ser_b_p(i),
               IB  => ser_b_n(i),
               O   => ibuf_ser_b(i)
      );

     iodelay1_a : IODELAYE1
       generic map (
         CINVCTRL_SEL           => FALSE,            -- TRUE, FALSE
         DELAY_SRC              => "I",              -- I, IO, O, CLKIN, DATAIN
         HIGH_PERFORMANCE_MODE  => TRUE,             -- TRUE, FALSE
         IDELAY_TYPE            => "VAR_LOADABLE",   -- FIXED, DEFAULT, VARIABLE, or VAR_LOADABLE
         IDELAY_VALUE           => 0,                -- 0 to 31
         ODELAY_TYPE            => "FIXED",          -- Has to be set to FIXED when IODELAYE1 is configured for Input
         ODELAY_VALUE           => 0,                -- Set to 0 as IODELAYE1 is configured for Input
         REFCLK_FREQUENCY       => 200.0,
         SIGNAL_PATTERN         => "DATA"            -- CLOCK, DATA
         )
       port map (
         DATAOUT                => delay_a_out(i),
         DATAIN                 => '0',              -- Data from FPGA logic
         C                      => frame_clk,
         CE                     => '0',              -- DELAY_DATA_CE,
         INC                    => '0',              -- DELAY_DATA_INC,
         IDATAIN                => ibuf_ser_a(i),    -- Driven by IOB
         ODATAIN                => '0',
         RST                    => delay_rst_a(i),
         T                      => '1',
         CNTVALUEIN             => delay_tap,        -- DELAY_TAP_IN,
         CNTVALUEOUT            => open,             -- DELAY_TAP_OUT,
         CLKIN                  => '0',
         CINVCTRL               => '0'
         );

     iodelay1_b : IODELAYE1
       generic map (
         CINVCTRL_SEL           => FALSE,            -- TRUE, FALSE
         DELAY_SRC              => "I",              -- I, IO, O, CLKIN, DATAIN
         HIGH_PERFORMANCE_MODE  => TRUE,             -- TRUE, FALSE
         IDELAY_TYPE            => "VAR_LOADABLE",   -- FIXED, DEFAULT, VARIABLE, or VAR_LOADABLE
         IDELAY_VALUE           => 0,                -- 0 to 31
         ODELAY_TYPE            => "FIXED",          -- Has to be set to FIXED when IODELAYE1 is configured for Input
         ODELAY_VALUE           => 0,                -- Set to 0 as IODELAYE1 is configured for Input
         REFCLK_FREQUENCY       => 200.0,
         SIGNAL_PATTERN         => "DATA"            -- CLOCK, DATA
         )
       port map (
         DATAOUT                => delay_b_out(i),
         DATAIN                 => '0',              -- Data from FPGA logic
         C                      => frame_clk,
         CE                     => '0',              -- DELAY_DATA_CE,
         INC                    => '0',              -- DELAY_DATA_INC,
         IDATAIN                => ibuf_ser_b(i),    -- Driven by IOB
         ODATAIN                => '0',
         RST                    => delay_rst_b(i),
         T                      => '1',
         CNTVALUEIN             => delay_tap,        -- DELAY_TAP_IN,
         CNTVALUEOUT            => open,             -- DELAY_TAP_OUT,
         CLKIN                  => '0',
         CINVCTRL               => '0'
         );

     end generate ISERDES_GEN;

end adc_unit_arc;
