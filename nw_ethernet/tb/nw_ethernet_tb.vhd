-------------------------------------------------------------------------------
-- Title      : Network Wizard Ethernet test bench
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: Test bench for the netwiz ethernet package.
-------------------------------------------------------------------------------
-- MIT License
--
-- Copyright (c) 2023 Geir Drange and contributors
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

library nw_util;
context nw_util.nw_util_context;
library nw_ethernet;
use nw_ethernet.nw_ethernet_pkg.all;


entity nw_ethernet_tb is
end entity nw_ethernet_tb;

architecture behav of nw_ethernet_tb is

  -- ethernet packet from https://github.com/jwbensley/Ethernet-CRC32
  constant C_ETH_PKT : t_slv_arr(0 to 101)(7 downto 0) := (x"08", x"00", x"27", x"27", x"1a", x"d5", x"52", x"54",
                                                           x"00", x"12", x"35", x"02", x"08", x"00", x"45", x"00",
                                                           x"00", x"54", x"1e", x"49", x"40", x"00", x"40", x"01",
                                                           x"04", x"50", x"0a", x"00", x"02", x"02", x"0a", x"00",
                                                           x"02", x"0f", x"00", x"00", x"59", x"d6", x"0f", x"af",
                                                           x"00", x"01", x"fd", x"b5", x"f5", x"5a", x"00", x"00",
                                                           x"00", x"00", x"e1", x"95", x"03", x"00", x"00", x"00",
                                                           x"00", x"00", x"10", x"11", x"12", x"13", x"14", x"15",
                                                           x"16", x"17", x"18", x"19", x"1a", x"1b", x"1c", x"1d",
                                                           x"1e", x"1f", x"20", x"21", x"22", x"23", x"24", x"25",
                                                           x"26", x"27", x"28", x"29", x"2a", x"2b", x"2c", x"2d",
                                                           x"2e", x"2f", x"30", x"31", x"32", x"33", x"34", x"35",
                                                           x"36", x"37", x"e6", x"4c", x"b4", x"86");


begin

  p_main : process
    variable v_header : t_ethernet_header := (mac_dest  => C_ETH_PKT(0 to 5),
                                              mac_src   => C_ETH_PKT(6 to 11),
                                              vlan_tag  => C_DEFAULT_DOT1Q,
                                              ethertype => x"0800");
    variable v_data : t_slv_arr(0 to 101)(7 downto 0);
    variable v_len  : natural;
  begin
    wait for 0.5674 ns;
    -------------------------------------------------------------------------------
    -- nw_ethernet_pkg functions
    -------------------------------------------------------------------------------
    msg("Part 1: Verify nw_ethernet_pkg functions");
    assert v_header = f_eth_get_header(C_ETH_PKT)
      report "Test 1.1 failed" severity failure;

    assert C_ETH_PKT = f_eth_create_pkt(v_header, C_ETH_PKT(14 to 97))
      report "Test 1.2 failed" severity failure;

    assert f_eth_crc_ok(C_ETH_PKT)
      report "Test 1.3 failed" severity failure;

    v_data        := C_ETH_PKT;
    v_data(56)(5) := not v_data(56)(5);  -- insert bit error

    assert f_eth_crc_ok(v_data) = false
      report "Test 1.4 failed" severity failure;

    assert 102 = f_eth_create_pkt_len(v_header, C_ETH_PKT(14 to 97))
      report "Test 1.5 failed" severity failure;

    assert C_ETH_PKT(0 to 5) = f_eth_mac_2_slv_arr("08:00:27:27:1a:d5")
      report "Test 1.6 failed" severity failure;

    v_len := f_eth_get_payload_len(C_ETH_PKT);
    assert v_len = 88
      report "Test 1.7 failed" severity failure;

    v_data(0 to 87) := f_eth_get_payload(C_ETH_PKT);
    assert v_data(0 to 87) = C_ETH_PKT(14 to 101)
      report "Test 1.8 failed" severity failure;


    wait for 10 ns;
    -- Finish the simulation
    msg("All tests are pass!");
    std.env.stop;
    wait;                               -- to stop completely
  end process p_main;

end architecture behav;
