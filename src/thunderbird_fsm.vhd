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
--| FILENAME      : thunderbird_fsm.vhd
--| AUTHOR(S)     : Capt Phillip Warner, Capt Dan Johnson
--| CREATED       : 03/2017 Last modified 06/25/2020
--| DESCRIPTION   : This file implements the ECE 281 Lab 2 Thunderbird tail lights
--|					FSM using enumerated types.  This was used to create the
--|					erroneous sim for GR1
--|
--|					Inputs:  i_clk 	 --> 100 MHz clock from FPGA
--|                          i_left  --> left turn signal
--|                          i_right --> right turn signal
--|                          i_reset --> FSM reset
--|
--|					Outputs:  o_lights_L (2:0) --> 3-bit left turn signal lights
--|					          o_lights_R (2:0) --> 3-bit right turn signal lights
--|
--|					Upon reset, the FSM by defaults has all lights off.
--|					Left ON - pattern of increasing lights to left
--|						(OFF, LA, LA/LB, LA/LB/LC, repeat)
--|					Right ON - pattern of increasing lights to right
--|						(OFF, RA, RA/RB, RA/RB/RC, repeat)
--|					L and R ON - hazard lights (OFF, ALL ON, repeat)
--|					A is LSB of lights output and C is MSB.
--|					Once a pattern starts, it finishes back at OFF before it 
--|					can be changed by the inputs
--|					
--|
--|                 One Hot State Encoding key
--|                 --------------------
--|                  State | Encoding
--|                 --------------------
--|                  OFF   | 1,0,0,0,0,0,0,0
--|                  ON    | 0,1,0,0,0,0,0,0
--|                  R1    | 0,0,1,0,0,0,0,0    
--|                  R2    | 0,0,0,1,0,0,0,0
--|                  R3    | 0,0,0,0,1,0,0,0    
--|                  L1    | 0,0,0,0,0,1,0,0
--|                  L2    | 0,0,0,0,0,0,1,0
--|                  L3    | 0,0,0,0,0,0,0,1
--|                 --------------------
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : None
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
 
entity thunderbird_fsm is
    port (
        i_clk, i_reset  : in    std_logic;
        i_left, i_right : in    std_logic;
        o_lights_L      : out   std_logic_vector(2 downto 0);
        o_lights_R      : out   std_logic_vector(2 downto 0)
    );
end thunderbird_fsm;

architecture thunderbird_fsm_arch of thunderbird_fsm is 

-- CONSTANTS ------------------------------------------------------------------
  type state_type is (
        S_OFF, S_ON, S_R1, S_R2, S_R3, S_L1, S_L2, S_L3
    );
  signal f_state, f_next_state : state_type;
  signal state_reg : std_logic_vector(7 downto 0);
begin

	-- CONCURRENT STATEMENTS --------------------------------------------------------	
	
    ---------------------------------------------------------------------------------
	
	-- PROCESSES --------------------------------------------------------------------
     process (i_clk, i_reset)
    begin
        if i_reset = '1' then
            f_state <= S_OFF;  -- Reset to OFF state
        elsif rising_edge(i_clk) then
            f_state <= f_next_state;
        end if;
    end process;
    
    
    process (f_state, i_left, i_right)
    begin
        case f_state is
            when S_OFF =>
                if i_left = '1' and i_right = '0' then
                    f_next_state <= S_L1;
                elsif i_right = '1' and i_left = '0' then
                    f_next_state <= S_R1;
                elsif i_left = '1' and i_right = '1' then
                    f_next_state <= S_ON;  -- Hazard mode
                else
                    f_next_state <= S_OFF;
                end if;
            
            when S_ON =>
                f_next_state <= S_OFF;  -- Hazard mode toggles back to OFF
            
            when S_R1 =>
                f_next_state <= S_R2;
            when S_R2 =>
                f_next_state <= S_R3;
            when S_R3 =>
                f_next_state <= S_OFF;
            
            when S_L1 =>
                f_next_state <= S_L2;
            when S_L2 =>
                f_next_state <= S_L3;
            when S_L3 =>
                f_next_state <= S_OFF;
            
            when others =>
                f_next_state <= S_OFF;
        end case;
    end process;


process (f_state)
    begin
        -- Default outputs
        o_lights_L <= "000";
        o_lights_R <= "000";
        state_reg  <= "10000000";
        
        case f_state is
            when S_ON =>
                o_lights_L <= "111";
                o_lights_R <= "111";
                state_reg  <= "01000000";
            when S_R1 =>
                o_lights_R <= "001";
                state_reg  <= "00100000";
            when S_R2 =>
                o_lights_R <= "011";
                state_reg  <= "00010000";
            when S_R3 =>
                o_lights_R <= "111";
                state_reg  <= "00001000";
            when S_L1 =>
                o_lights_L <= "001";
                state_reg  <= "00000100";
            when S_L2 =>
                o_lights_L <= "011";
                state_reg  <= "00000010";
            when S_L3 =>
                o_lights_L <= "111";
                state_reg  <= "00000001";
            when others =>
                o_lights_L <= "000";
                o_lights_R <= "000";
                state_reg  <= "10000000";
        end case;
    end process;

	-----------------------------------------------------					   
				  
end thunderbird_fsm_arch;
