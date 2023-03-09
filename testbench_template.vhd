-- Generic template for testbenches
-- Copyright 2017-2023 Aston University

-- declarations for standard logic as needed
library IEEE;
use IEEE.std_logic_1164.all;
-- use IEEE.numeric_std.all;
-- use ieee.math_real.all;

-- testbench entity has no inputs and outputs
entity uut_testbench is
end uut_testbench;

architecture testbench of uut_testbench is
  component uut is
    port (  -- copy ports from uut entity declaration here
      );
  end component;

-- other declarations needed for test go here e.g. signal declarations

begin
  -- entity instantiation with port maps goes here
  top: uut port map (
   -- map uut ports to local signals here
    );

  stim_proc : process
  begin
    -- test bench behaviour goes here

    -- stop process when finished test
    wait;
  end process;

end testbench;
