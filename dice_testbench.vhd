-- Testbenc for students dice entity
-- Copyright 2017-2023 Aston University

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity dice_testbench is
end dice_testbench;

architecture sim of dice_testbench is

  component dice is
  port (
    clk: in std_logic;
    roll: in std_logic;
    sum: out unsigned(3 downto 0);
    dice1,dice0: out unsigned(2 downto 0)
    );
  end component;

  constant clk_period   : time := 100 ns;
  constant clear_period : time := 10 ns;
  signal clk,finished,roll: std_logic;
  signal sum: unsigned(3 downto 0);
  signal dice1,dice0: unsigned(2 downto 0);

begin
  uut: dice
    port map(clk=>clk, roll=>roll, sum=>sum, dice1=>dice1, dice0=>dice0);
  
  clock: process -- generate clock until test_end is set to 1
  begin
    while finished/='1' loop
      clk <= '1';
      wait for clk_period/2 ;
      clk <= '0' ;
      wait for clk_period/2;
    end loop;
    wait;
  end process clock;

  check_proc: process(clk)
  begin
    if rising_edge(clk) then
      assert to_integer(sum)=to_integer(dice0)+to_integer(dice1)
        report "Sum incorrect";
    end if;
  end process check_proc;

  stim_proc: process
  begin
    finished<='0';
    roll<='1';
    wait for clk_period;
    assert dice0=1 and dice1=1;
    wait for clk_period;
    assert dice0=2 and dice1=1;
    wait for clk_period*4;
    assert dice0=6 and dice1=1;
    wait for clk_period;
    assert dice0=1 and dice1=2;
    wait for clk_period*29;
    assert dice0=6 and dice1=6;
    finished<='1';
    wait;
  end process stim_proc;
    
end sim;
