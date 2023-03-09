-- Testbench to test counter implementations
-- Copyright 2017-2023 Aston University

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity counter_testbench is
end counter_testbench;

architecture sim of counter_testbench is

  component counter is
  generic (
    nbits: integer:=4; -- num bits for counter
    start: integer:=0; -- where count starts from
    finish: integer:=9 -- where count ends
    );
  port (
    clk: in  STD_LOGIC;
    ce: in std_logic;
    reset: in std_logic; 
    count: out unsigned(nbits-1 downto 0);
    tc: out std_logic
    );
  end component;

  constant clk_period   : time := 100 ns;
  constant clear_period : time := 10 ns;
  signal clk,reset: std_logic :='0';
  signal overflow: std_logic:='0';
  signal finished: boolean:=false; 
  signal count0,count1: unsigned(3 downto 0):=(others=>'0');

begin
  uut0: counter
    generic map ( start=>0, finish=>9, nbits=>4)
    port map (clk=>clk, ce=>'1', reset=> reset, tc=>overflow, count=>count0);
  uut1: counter
    generic map ( start=>5, finish=>6, nbits=>4)
    port map(ce=>overflow, clk=>clk, reset=>reset, count=>count1);

  clock: process -- generate clock until test_end is set to 1
  begin
      clk <= '1';
      wait for clk_period/2 ;
      clk <= '0' ;
      wait for clk_period/2;
      if finished then wait;
      end if;
  end process clock;

  stim_proc: process
  begin
    reset<='1';
    wait until rising_edge(clk);
    wait for clk_period/100; -- delay to cope with counter skew
    reset<='0';
    for j in 5 to 6 loop
      for i in 0 to 9 loop
        assert count0=i and count1=j
          report "Expected "&integer'image(j)&integer'image(i)&" but got "
          & integer'image(to_integer(count1))&integer'image(to_integer(count0));
        wait for clk_period;
      end loop;
    end loop;
    assert count0=0 and count1=5
      report "Expected 50"; -- check roll around
    finished<=true;
    wait;
  end process stim_proc;
    
end sim;
