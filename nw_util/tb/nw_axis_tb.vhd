-------------------------------------------------------------------------------
-- Title      : Network Wizard AXI-Stream test bench
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: Test bench for the netwiz AXI-Stream modules.
-------------------------------------------------------------------------------
-- MIT License
--
-- Copyright (c) 2026 Geir Drange
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is 
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in 
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
-- WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR 
-- IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library nw_adapt;
use nw_adapt.nw_adaptations_pkg.all;

library nw_util;
context nw_util.nw_util_context;

entity nw_axis_tb is
end entity nw_axis_tb;

architecture behav of nw_axis_tb is

  type t_nat_arr is array (natural range <>) of natural;

  constant C_DUTS     : integer                    := 4; -- number of DUT instances
  constant C_DWIDTH   : t_nat_arr(0 to C_DUTS - 1) := (1, 3, 4, 32); -- DUT data width
  constant C_MAX_SIZE : integer                    := 2000; -- Max packet size

  signal pkt       : t_slv_arr(0 to 1950)(7 downto 0);
  signal pkt_valid : std_logic;
  signal pkt_len   : natural;
  signal ready     : std_logic_vector(C_DUTS - 1 downto 0);
  signal done      : std_logic_vector(C_DUTS - 1 downto 0);
  signal aclk      : std_logic;
  signal aresetn   : std_logic;

begin

  -------------------------------------------------------------------------------
  -- DUT
  -------------------------------------------------------------------------------
  g_dut: for i in 0 to 3 generate

    signal tdata        : std_logic_vector(C_DWIDTH(i) * 8 - 1 downto 0);
    signal tkeep        : std_logic_vector(C_DWIDTH(i) - 1 downto 0);
    signal tstrb        : std_logic_vector(C_DWIDTH(i) - 1 downto 0);
    signal tready       : std_logic;
    signal tlast        : std_logic;
    signal tvalid       : std_logic;
    signal rx_pkt       : t_slv_arr(0 to C_MAX_SIZE - 1)(7 downto 0);
    signal rx_pkt_len   : natural;
    signal rx_pkt_valid : std_logic;

  begin
    i_axis_source : entity nw_util.axis_source
      generic map (
        GC_BYTES => C_DWIDTH(i)
      )
      port map (
        aclk      => aclk,
        aresetn   => aresetn,
        tready    => tready,
        tvalid    => tvalid,
        tdata     => tdata,
        tkeep     => tkeep,
        tstrb     => tstrb,
        tlast     => tlast,
        done      => done(i), 
        pkt_len   => pkt_len,
        pkt_valid => pkt_valid,
        pkt       => pkt
      );

    i_axis_sink : entity nw_util.axis_sink
      generic map (
        GC_BYTES        => C_DWIDTH(i),
        GC_MAX_PKT_SIZE => C_MAX_SIZE
      )
      port map (
        aclk      => aclk,
        aresetn   => aresetn,
        tready    => tready,
        tvalid    => tvalid,
        tdata     => tdata,
        tkeep     => tkeep,
        tstrb     => tstrb,
        tlast     => tlast,
        pkt_len   => rx_pkt_len,
        pkt_valid => rx_pkt_valid,
        pkt       => rx_pkt
      );

    p_chk: process (aclk) is
    begin
      if falling_edge(aclk) then
        if rx_pkt_valid = '1' then
          assert pkt(0 to pkt_len - 1) = rx_pkt(0 to pkt_len - 1) report "Packet mismatch, DUT #" & to_string(i) severity C_SEVERITY;
        end if;
      end if;
    end process p_chk;


  end generate g_dut;

  -------------------------------------------------------------------------------
  -- Clock and reset
  -------------------------------------------------------------------------------
  p_clk : process is
  begin
    aclk <= '0';
    wait for 5 ns;
    aclk <= '1';
    wait for 5 ns;
  end process p_clk;

  p_rst : process is
  begin
    aresetn <= '0';
    wait for 120 ns;
    aresetn <= '1';
    wait;
  end process p_rst;

  -------------------------------------------------------------------------------
  -- Sequencer
  -------------------------------------------------------------------------------
  p_main : process is
    variable v_len: integer;
  begin
    pkt_valid <= '0';
    wait for 200 ns;
    msg("Part 1: Verify nw_axis, small packets");
    for p in 0 to 5 loop
      wait until rising_edge(aclk);
      v_len := 14 + p * 17;
      pkt_len <= v_len;
      pkt(0 to v_len - 1) <= f_gen_prbs(C_POLY_X18_X11_1, 8, v_len);
      pkt_valid <= '1';
      wait until rising_edge(aclk);
      pkt_valid <= '0';
      wait until done = "1111";
      wait for 100 ns;
    end loop;

    msg("Part 2: Verify nw_axis, large packets");
    for p in 0 to 5 loop
      wait until rising_edge(aclk);
      v_len := f_randnat(100, 2000);
      pkt_len <= v_len;
      pkt(0 to v_len - 1) <= f_gen_prbs(C_POLY_X18_X11_1, 8, v_len);
      pkt_valid <= '1';
      wait until rising_edge(aclk);
      pkt_valid <= '0';
      wait until done = "1111";
      wait for 100 ns;
    end loop;

    -- Finish the simulation
    msg("All tests are pass!");
    std.env.stop;
    wait; -- to stop completely
  end process p_main;


end architecture behav;
