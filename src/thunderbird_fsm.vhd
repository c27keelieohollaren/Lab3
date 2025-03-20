--+----------------------------------------------------------------------------
--| 
--| COPYRIGHT 2017 United States Air Force Academy All rights reserved.
--| 
--| United States Air Force Academy     __  _______ ___    _________ 
--| Dept of Electrical &               / / / / ___//   |  / ____/   |
--| Computer Engineering              / / / /\__ \/ /| | / /_  / /| |
--| 2354 Fairchild Drive Ste 2F6     / /_/ /___/ / ___ |/ __/ / ___ |
--| USAF Academy, CO 80840           \____//____/_/  |_/_/   /_/  |_|
--| 
--| ---------------------------------------------------------------------------
--|
--| FILENAME      : thunderbird_fsm_tb.vhd (TEST BENCH)
--| AUTHOR(S)     : Capt Phillip Warner
--| CREATED       : 03/2017
--| DESCRIPTION   : This file tests the thunderbird_fsm modules.
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : thunderbird_fsm_enumerated.vhd, thunderbird_fsm_binary.vhd, 
--|				   or thunderbird_fsm_onehot.vhd
--|
--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  
entity thunderbird_fsm_tb is
end thunderbird_fsm_tb;

architecture test_bench of thunderbird_fsm_tb is 
	
	component thunderbird_fsm is 
port (
        i_clk, i_reset  : in    std_logic;
        i_left, i_right : in    std_logic;
        o_lights_L      : out   std_logic_vector(2 downto 0);
        o_lights_R      : out   std_logic_vector(2 downto 0)
    );
	end component thunderbird_fsm;

	-- test I/O signals
	signal clk_tb      : std_logic := '0';
    signal reset_tb    : std_logic := '0';
    signal left_tb     : std_logic := '0';
    signal right_tb    : std_logic := '0';
    signal lights_L_tb : std_logic_vector(2 downto 0);
    signal lights_R_tb : std_logic_vector(2 downto 0);

	-- constants
	constant clk_period : time := 10 ns;

	
begin
	-- PORT MAPS ----------------------------------------
	 uut: thunderbird_fsm 
        port map (
            i_clk      => clk_tb,
            i_reset    => reset_tb,
            i_left     => left_tb,
            i_right    => right_tb,
            o_lights_L => lights_L_tb,
            o_lights_R => lights_R_tb
        );

	-----------------------------------------------------
	
	-- PROCESSES ----------------------------------------	
    -- Clock process ------------------------------------
    clk_process : process
    begin
        while true loop
            clk_tb <= '0';
            wait for clk_period / 2;
            clk_tb <= '1';
            wait for clk_period / 2;
        end loop;
    end process;
	-----------------------------------------------------
	
	-- Test Plan Process --------------------------------
	stim_proc: process
    begin
        -- Reset sequence
        reset_tb <= '1';
        wait for 2 * clk_period;
        reset_tb <= '0';
        wait for clk_period;

        -- Left Turn Sequence
        left_tb <= '1';
        wait for 5 * clk_period;
        left_tb <= '0';
        wait for 5 * clk_period;

        -- Right Turn Sequence
        right_tb <= '1';
        wait for 5 * clk_period;
        right_tb <= '0';
        wait for 5 * clk_period;

        -- Hazard Lights (Both ON)
        left_tb <= '1';
        right_tb <= '1';
        wait for 5 * clk_period;
        left_tb <= '0';
        right_tb <= '0';
        wait for 5 * clk_period;

	-----------------------------------------------------	
 wait;
 end process;
	
end test_bench;
