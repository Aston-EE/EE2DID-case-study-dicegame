-- A three process finite state machine design in VHDL as per Xilinx
-- recommendations
-- Copyright 2017-2023 Aston University

library IEEE;
use IEEE.std_logic_1164.all;

entity fsm is
  port (
    clk: in std_logic;
    reset: in std_logic;
    -- list other inputs here e.g.
    x :in std_logic;
    -- list outputs here e.g.
    parity: out std_logic
    );
end fsm;

architecture rtl of fsm is
  type state_type is (
    -- list states names for state type here e.g. S0,S1 etc
    );
  -- to declare you own state bit mapping use
  --attribute enum_encoding : string;
  --attribute enum_encoding of state_type : type is "001 010 100 110 111 101";
  
  signal state,next_state: state_type; -- current and next state
  -- we can specify the encoding regime to be used - this is implementation
  -- dependant. For vivado legitimate values are
  -- "auto","gray","johnson","one_hot","sequential"
  -- or "user"
  -- default is "auto"
  --attribute fsm_encoding: string;
  --attribute fsm_encoding of state is "auto";
  -- attribute if illegal state value is detected
  -- acceptable values are "auto","reset_state","power_on_state","default_state"
  --attribute fsm_safe_state : string;
  --attribute fsm_safe_state of state : signal is "reset_state";
  -- see https://www.xilinx.com/support/answers/60799.html for more info
  
begin

  -- process for synchronous (clocked) operation
  SYNC_PROC: process (clk) 
  begin
    if rising_edge(clk) then
      if (reset = '1') then -- here we have a synchronous reset
        state <= S0;         -- assign state to reset state value
      else
        state <= next_state;
      end if;
    end if;
  end process;

  -- process for the output decoding.
  -- for a Moore model it will be sensitive to state only, for a Mealy model
  -- it will also be sensitive to immediate inputs 
  OUTPUT_DECODE: process (state)
  begin
    -- assign default outputs here to ensure all outputs are set for each case
    
    -- case statement for each state which sets outputs as required
    -- Mealy outputs will also test inputs
    case (state) is
      when S0 =>
        -- .....
      when others => -- ALWAYS have when others catchall
        -- set output for catchall here
    end case;
  end process;

  -- process for next state decoding
  -- sensitive to state change and inputs
  NEXT_STATE_DECODE: process (state, <input list> )
  begin
    -- always assign a default next state
    next_state <= ...;
    -- case statement checking current state
    -- and checking inputs to determine next state.
    case (state) is
      when S0 =>
      when others =>  -- ALWAYS have when others catchall to go to a safe state
        next_state <= S0;
    end case;
  end process;
end rtl;
