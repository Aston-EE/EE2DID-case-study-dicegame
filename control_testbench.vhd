-- A three process finite state machine design in VHDL as per Xilinx
-- recommendations

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity control_testbench is
end control_testbench;

architecture sim of control_testbench is

  component control is
  port (
    clk: in std_logic;
    reset,Rb,D711,D2312,EQ,D7: in std_logic;
    SP,ROLL,WIN,LOSE: out std_logic
    );
  end component;

   component compare is
     port (
    clk: in std_logic;
    sp: in std_logic:='0';
    sum: in unsigned(3 downto 0);
    d7,d711,d2312,eq: out std_logic
    );
   end component;
  
  constant clk_period   : time := 100 ns;
  constant clear_period : time := 10 ns;
  signal clk,finished,sp,d7,d711,d2312,eq,roll: std_logic;
  signal sum: unsigned(3 downto 0):="0000";
  signal win,lose,rb,reset: std_logic;

  -- after first role of dice player wins if sum is 7 or 11 
  -- loses if sum is 2,3 or 12.
  -- Otherwise the sum the player obtained on first roll
  -- is saved as point and they must roll again
  -- on second and subsequent rolls player wins if sum equal point
  -- or loses if sum is 7, otherwise must roll again
  type throw_set is array(0 to 11) of integer range 2 to 12;
  constant throws: throw_set :=(7,11,2,3,12, 8,7, 4,4, 8,4,7);
--  constant resets: STD_LOGIC_VECTOR(0 to 11) :=("111110101001");
  constant twin: STD_LOGIC_VECTOR(0 to 11)   :=("110000001000");
  constant tlose: STD_LOGIC_VECTOR(0 to 11)  :=("001110100001");
  constant tsp:   STD_LOGIC_VECTOR(0 to 11)  :=("000001010100");
begin
  cmp: compare
    port map(clk=>clk, sp=>sp, sum=>sum,d7=>d7,d711=>d711,d2312=>d2312,eq=>eq);
  uut: control
    port map(clk=>clk, reset=>reset, rb=>rb, roll=>roll, win=>win, lose=>lose,
             sp=>sp, d7=>d7,d711=>d711,d2312=>d2312,eq=>eq);
             
  clock: process -- generate clock until finished is set to 1
  begin
    while finished/='1' loop
      clk <= '1';
      wait for clk_period/2 ;
      clk <= '0' ;
      wait for clk_period/2;
    end loop;
    wait;
  end process clock;

  stim_proc: process
  begin
    finished<='0';
    reset<='0'; rb<='0';
    wait until rising_edge(clk);
    assert win='0' and lose='0' and roll='0' and sp='0';
    for i in 0 to 11 loop
      rb<='1'; wait until rising_edge(clk); wait for 1 ns;
      assert win='0' and lose='0' and roll='1' and sp='0'
        report "Roll:"&std_logic'image(win)&std_logic'image(lose)
        &std_logic'image(roll)&std_logic'image(sp);
      rb<='0'; sum<=to_unsigned(throws(I),4); wait until rising_edge(clk);
      wait until rising_edge(clk); wait for 1 ns;
      assert win=twin(i) and lose=tlose(i) and sp=tsp(i) and roll='0'
        report "Throw "&integer'image(to_integer(sum))&": (win,lose,roll,sp)=>"&std_logic'image(win)&std_logic'image(lose)
        &std_logic'image(roll)&std_logic'image(sp);
      wait until rising_edge(clk); wait for 1 ns;
      if win='1' or lose='1' then
        reset<='1'; wait until rising_edge(clk);
        reset<='0'; wait until rising_edge(clk);
      end if;
    end loop;
   
    finished<='1';
    wait;
  end process stim_proc;
    
end sim;
