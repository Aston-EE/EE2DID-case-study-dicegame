-- Testbench to test the clock prescaler.
-- Copyright 2017-2023 Aston University

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity clk_prescaler_testbench is
end clk_prescaler_testbench;

architecture sim of clk_prescaler_testbench is

  component clk_prescaler is
  generic (
    n: integer  --  divide clk by n to generate clk_div
  );
  port (
    clk: in std_logic; -- input (system) clock
    clk_div: out std_logic  -- output clock enable signal at clk/n frequency
    );
  end component;
    
  constant clk_period: time := 100 ns;
  constant n: integer:=10; -- clock divisor
  signal clk,clk_div: std_logic :='0';
  signal count: integer:=0;
  signal finished: boolean:=false;
  
begin
  uut: clk_prescaler
    generic map (n => n)
    port map(clk=>clk, clk_div=>clk_div);

  clock_gen: process -- generate clock until finished is set to true
  begin
    while not(finished) loop
      clk <= '1';
      wait for clk_period/2 ;
      clk <= '0' ;
      wait for clk_period/2;
      count<=count+1;
      assert count<30 report "clk_div period incorrect";
    end loop;
    wait;
  end process clock_gen;
  
  check_proc: process
    variable last_count: integer;
  begin
    wait until rising_edge(clk_div);
    last_count:=count;
    for i in 0 to 1 loop
      wait until rising_edge(clk_div);
      assert (last_count-count) mod n = 0 report "clk_div period incorrect";
      last_count:=count;
      if count>30 then
        finished<=true;
        wait;
      end if;
    end loop;
    finished<=true;
    wait;
  end process check_proc;

end sim;
