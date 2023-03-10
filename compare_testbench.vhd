-- Testnech to  chek students compare entity
-- Copyright 2017-2023 Aston University

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity compare_testbench is
end compare_testbench;

architecture behavioural of compare_testbench is

  component compare is
  port (
    clk: in std_logic;
    sp: in std_logic;
    sum: in unsigned(3 downto 0);
    d7,d711,d2312,eq: out std_logic
    );
  end component;

  constant clk_period   : time := 100 ns;
  constant clear_period : time := 10 ns;
  signal clk,finished,sp,d7,d711,d2312,eq: std_logic:='0';
  signal sum,p: unsigned(3 downto 0):="0000";
  
begin
  uut: compare
    port map(clk=>clk, sp=>sp, sum=>sum,d7=>d7,d711=>d711,d2312=>d2312,eq=>eq);
  
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

  check1: process(clk)
  begin
    if rising_edge(clk) and sum/="0000" then
      if sum=7 then
        assert d7='1' and d711='1' report "7";
      end if;
      if sum=11 then
        assert d711='1' report "11";
      end if;
      if sum=2 or sum=3 or sum=12 then
        assert d2312='1' report "2,3or12";
      end if ;
    end if;
  end process check1;

  stim_proc: process
  begin
    finished<='0'; wait until rising_edge(clk);
    for i in 2 to 12 loop
      sum<=to_unsigned(i,4); wait until rising_edge(clk);
    end loop;
    sum<=to_unsigned(5,4); sp<='1'; p<=sum; wait until rising_edge(clk);
    sp<='0'; wait until rising_edge(clk);
    assert eq='1';
    sum<=to_unsigned(8,4); wait until rising_edge(clk);
    assert eq='0';
    finished<='1';
    wait;
  end process stim_proc;
    
end behavioural;
