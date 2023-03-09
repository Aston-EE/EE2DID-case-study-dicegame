-- Template for debounce implementation
-- Copyright 2017-2023 Aston University

library IEEE;
use IEEE.std_logic_1164.all;

entity debounce is
  port (
    clk: in std_logic;    -- system clock
    clk_en: in std_logic; -- low frequency sampling clock enable (e.g. 1kHz)
    button: in std_logic;    -- input from button
    debounced: out std_logic:='0'; -- the debounced button level output 
    down_event: out std_logic:='0' -- enable event signal when button pressed
    );
end debounce;

architecture behavioural of debounce is
  -- put your local signal definitions here
  -- Hint you declare signal(s) to store previous two samples
  -- and debounced output.
begin
  -- put any combinational logic here

  tr: process(clk) -- clocked transition process
  begin
    if(rising_edge(clk)) then
      if clk_en='1' then
      -- Hint: logic to store previous (2) samples
      end if;
      -- Hint: logic to set outputs as necessary 
      -- setting output here will ensure it is synchronised with clk
      -- i.e. can be used in subsequent synchronous logic
    end if;
  end process;

end behavioural;
