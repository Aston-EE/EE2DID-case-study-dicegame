-- Template to test debounce implementation
-- Copyright 2017-2023 Aston University

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity debounce_testbench is

end debounce_testbench;

architecture testbench of debounce_testbench is
  constant clk_period: time := 10 ns;
  constant clear_period: time := 2 ns;
  constant strobe_divider:integer :=10;
  constant strobe_t: time := clk_period*strobe_divider;
 
  
  component debounce is
  port (
    clk: in std_logic; -- system clock
    clk_en: in std_logic; -- low frequency sampling clock enable (e.g. 1kHz)
    button: in std_logic; -- input from button
    debounced,down_event: out std_logic:='0' -- debounced output event signals
    );
  end component;

  component clk_prescaler
    generic ( n: integer );
    port ( clk: in std_logic; clk_div: out std_logic );
  end component;

  signal finished: boolean :=false;
  signal clk,sample_clk,sw: std_logic :='0';
  signal down,debounced: std_logic:='0';
  signal cdown: integer:=0;

begin
  sc: clk_prescaler
    generic map (n => strobe_divider) -- low freq strobe
    port map (clk => clk, clk_div => sample_clk);
  db: debounce
    port map (clk=>clk, clk_en => sample_clk, button => sw,
              debounced=>debounced, down_event=>down);

  clock: process -- generate clock until test_end is set to 1
  begin
    clk <= '0';
    wait for clk_period/2 ;
    clk <= '1' ;
    wait for clk_period/2;
    if finished then  wait; end if;
  end process clock;

  stim: process
  begin
    sw<='0';
    wait for strobe_t; -- +clk_period/10; 
    sw<='1'; wait for clk_period/10; 
    sw<='0'; wait for strobe_t*1.3;
    assert(debounced='0') report "Expected debounced to be 0";
    sw<='1'; wait for strobe_t*0.99; 
    assert(debounced='0') report "Expected debounced to be 0";
    sw<='0'; wait for strobe_t; 
    assert(debounced='0') report "Expected debounced to be 0";
    sw<='1'; wait for strobe_t*5.5;  
    assert(debounced='1') report "Expected debounced to be 1";
    sw<='0'; wait for strobe_t; 
    wait for 2*strobe_t;
    assert(debounced='0') report "Expected debounced to be 0";
    assert cdown=1 report "Number of debounced presses not equal to 1.";

    finished<=true;
    wait;
  end process stim;

  cproc: process(clk) -- count down events
  begin
    if rising_edge(clk) then
      if down='1' then cdown<=cdown+1; end if;
    end if;
  end process cproc;
  
end testbench;
