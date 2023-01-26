-------------------------------------------------------------------------------
-- Title      : Network Wizard PCAP test bench
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: Test bench for the netwiz PCAP package.
-------------------------------------------------------------------------------
-- MIT License
--
-- Copyright (c) 2023 Geir Drange
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
use std.textio.all;

library nw_util;
context nw_util.nw_util_context;
library nw_pcap;
use nw_pcap.nw_pcap_pkg.all;


entity nw_pcap_tb is
end entity nw_pcap_tb;

architecture behav of nw_pcap_tb is

  -- the file below is documented here: https://www.cloudshark.org/captures/4f292d12d438
  constant C_PCAPNG_FILENAME : string := "F:/netwiz/nw_pcap/tb/ipv6-smtp.pcapng";
  -- the file below is documented here: https://www.cloudshark.org/captures/7a6644ad437e
  constant C_PCAP_FILENAME   : string := "F:/netwiz/nw_pcap/tb/PPTP_negotiation.pcap";

begin

  p_main : process
    variable v_data : t_slv_arr(0 to 1023)(7 downto 0);
    variable v_l    : natural;

  begin
    wait for 1 ns;
    msg("Part 1: Verify pcapng functions");
    
    assert 17 = f_pcap_get_pkt_cnt(C_PCAPNG_FILENAME)
      report "Test 1.1 failed" severity failure;

    v_l := f_pcap_get_pkt_len(C_PCAPNG_FILENAME, 3);
    assert 125 = f_pcap_get_pkt_len(C_PCAPNG_FILENAME, 3)
      report "Test 1.2 failed" severity failure;

    v_data(0 to 124) := f_pcap_get_pkt(C_PCAPNG_FILENAME, 3, 125);
    assert (x"68", x"a3", x"c4", x"f9", x"49") = v_data(0 to 4) and (x"74", x"70", x"0d", x"0a") = v_data(121 to 124)
      report "Test 1.3 failed" severity failure;

    wait for 6.66 ns;
    msg("Part 2: Verify pcap functions");

    assert 28 = f_pcap_get_pkt_cnt(C_PCAP_FILENAME)
      report "Test 2.1 failed" severity failure;

    v_l := f_pcap_get_pkt_len(C_PCAP_FILENAME, 26);
    assert 138 = f_pcap_get_pkt_len(C_PCAP_FILENAME, 26)
      report "Test 2.2 failed" severity failure;

    v_data(0 to 137) := f_pcap_get_pkt(C_PCAP_FILENAME, 26, 138);
    assert (x"00", x"14", x"00", x"00", x"02") = v_data(0 to 4) and (x"34", x"35", x"36", x"37") = v_data(134 to 137)
      report "Test 2.3 failed" severity failure;

    wait for 8.75 ns;
    -- Finish the simulation
    msg("All tests are pass!");
    std.env.stop;
    wait;
  end process p_main;

end architecture behav;
