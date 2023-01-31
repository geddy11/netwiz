-------------------------------------------------------------------------------
-- Title      : Network Wizard IPv4 test bench
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: Test bench for the netwiz IPv4 package.
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

library nw_adapt;
use nw_adapt.nw_adaptations_pkg.all;
library nw_util;
context nw_util.nw_util_context;
library nw_ipv4;
context nw_ipv4.nw_ipv4_context;

--library nw_ipv6;
--context nw_ipv6.nw_ipv4_context;
use work.nw_ipv6_pkg.all;

library nw_ethernet;
context nw_ethernet.nw_ethernet_context;

entity nw_ipv6_tb is
end entity nw_ipv6_tb;

architecture behav of nw_ipv6_tb is

  -- link: https://www.cloudshark.org/captures/a59f35d38471
  constant C_ICMPV6_PKT : t_slv_arr(0 to 89)(7 downto 0) := (x"33", x"33", x"00", x"00", x"00", x"16", x"00",
                                                             x"12", x"3f", x"97", x"92", x"01", x"86", x"dd",
                                                             x"60", x"00", x"00", x"00", x"00", x"24", x"00",
                                                             x"01", x"fe", x"80", x"00", x"00", x"00", x"00",
                                                             x"00", x"00", x"9c", x"09", x"b4", x"16", x"07",
                                                             x"68", x"ff", x"42", x"ff", x"02", x"00", x"00",
                                                             x"00", x"00", x"00", x"00", x"00", x"00", x"00",
                                                             x"00", x"00", x"00", x"00", x"16", x"3a", x"00",
                                                             x"05", x"02", x"00", x"00", x"01", x"00", x"8f",
                                                             x"00", x"19", x"3c", x"00", x"00", x"00", x"01",
                                                             x"04", x"00", x"00", x"00", x"ff", x"02", x"00",
                                                             x"00", x"00", x"00", x"00", x"00", x"00", x"00",
                                                             x"00", x"00", x"00", x"01", x"00", x"03");

  -- authentication header: https://www.cloudshark.org/captures/2e5e60b23671
  constant C_IPV6_OSPF : t_slv_arr(0 to 105)(7 downto 0) := (x"c2", x"01", x"68", x"b3", x"00", x"01", x"c2",
                                                             x"00", x"68", x"b3", x"00", x"01", x"86", x"dd",
                                                             x"6e", x"00", x"00", x"00", x"00", x"34", x"33",
                                                             x"01", x"fe", x"80", x"00", x"00", x"00", x"00",
                                                             x"00", x"00", x"00", x"00", x"00", x"00", x"00",
                                                             x"00", x"00", x"01", x"fe", x"80", x"00", x"00",
                                                             x"00", x"00", x"00", x"00", x"00", x"00", x"00",
                                                             x"00", x"00", x"00", x"00", x"02", x"59", x"04",
                                                             x"00", x"00", x"00", x"00", x"01", x"00", x"00",
                                                             x"00", x"00", x"16", x"d0", x"88", x"36", x"38",
                                                             x"d3", x"91", x"01", x"56", x"2e", x"83", x"66",
                                                             x"79", x"03", x"02", x"00", x"1c", x"01", x"01",
                                                             x"01", x"01", x"00", x"00", x"00", x"01", x"e4",
                                                             x"71", x"00", x"00", x"00", x"00", x"00", x"13",
                                                             x"05", x"dc", x"00", x"07", x"00", x"00", x"12",
                                                             x"fd");

begin

  p_main : process

    variable v_payload     : t_slv_arr(0 to 289)(7 downto 0);
    variable v_ipv6_pkt    : t_slv_arr(0 to 309)(7 downto 0);
    variable v_ipv6_header : t_ipv6_header;
    variable v_len         : natural;
    variable v_plen        : natural;
    variable v_ext_headers : t_ext_header_list := C_DEFAULT_EXT_HEADER_LIST;
    variable v_addr        : t_slv_arr(0 to 15)(7 downto 0);

  begin
    wait for 0.5674 ns;
    -------------------------------------------------------------------------------
    -- nw_ipv6_pkg functions
    -------------------------------------------------------------------------------
    msg("Part 1: Verify nw_ipv6_pkg functions");

    v_ipv6_header := f_ipv6_get_header(f_eth_get_payload(C_ICMPV6_PKT));
    v_ext_headers := f_ipv6_get_ext_headers(f_eth_get_payload(C_ICMPV6_PKT));

    assert v_ipv6_header.src_addr(14 to 15) = (x"ff", x"42")
      report "Test 1.1 failed" severity failure;

    assert v_ipv6_header.dest_addr(14 to 15) = (x"00", x"16")
      report "Test 1.2 failed" severity failure;

    assert v_ext_headers.header_cnt = 1
      report "Test 1.3 failed" severity failure;

    assert v_ext_headers.headers(0).header_type = C_HOPOPT
      report "Test 1.4 failed" severity failure;

    v_plen := f_ipv6_get_payload_len(f_eth_get_payload(C_ICMPV6_PKT));
    assert v_plen = 28
      report "Test 1.5 failed" severity failure;

    v_ipv6_header.next_header  := C_IPV6_ICMP;
    v_payload(0 to v_plen - 1) := f_ipv6_get_payload(f_eth_get_payload(C_ICMPV6_PKT));
    v_len                      := f_ipv6_create_pkt_len(v_ipv6_header, v_payload(0 to v_plen - 1), v_ext_headers);

    assert v_len = 76
      report "Test 1.6 failed" severity failure;

    v_ipv6_pkt(0 to v_len - 1) := f_ipv6_create_pkt(v_ipv6_header, v_payload(0 to v_plen - 1), v_ext_headers);
    assert v_ipv6_pkt(0 to v_len - 1) = C_ICMPV6_PKT(14 to 89)
      report "Test 1.7 failed" severity failure;

    wait for 1.27 ns;
    v_ipv6_header := f_ipv6_get_header(f_eth_get_payload(C_IPV6_OSPF));
    v_ext_headers := f_ipv6_get_ext_headers(f_eth_get_payload(C_IPV6_OSPF));

    assert v_ext_headers.headers(0).header_type = C_AH
      report "Test 1.8 failed" severity failure;

    assert v_ext_headers.headers(0).next_header = C_OSPF
      report "Test 1.9 failed" severity failure;

    assert v_ext_headers.headers(0).hdr_ext_len = x"04"
      report "Test 1.10 failed" severity failure;

    assert v_ext_headers.headers(0).spi = x"00000100"
      report "Test 1.11 failed" severity failure;

    assert v_ext_headers.headers(0).seq_no = x"00000016"
      report "Test 1.12 failed" severity failure;

    v_plen := f_ipv6_get_payload_len(f_eth_get_payload(C_IPV6_OSPF));

    assert v_plen = 28
      report "Test 1.13 failed" severity failure;

    v_ipv6_header.next_header  := C_OSPF;
    v_payload(0 to v_plen - 1) := f_ipv6_get_payload(f_eth_get_payload(C_IPV6_OSPF));
    v_len                      := f_ipv6_create_pkt_len(v_ipv6_header, v_payload(0 to v_plen - 1), v_ext_headers);

    assert v_len = 92
      report "Test 1.14 failed" severity failure;

    v_ipv6_pkt(0 to v_len - 1) := f_ipv6_create_pkt(v_ipv6_header, v_payload(0 to v_plen - 1), v_ext_headers);
    assert v_ipv6_pkt(0 to v_len - 1) = C_IPV6_OSPF(14 to 105)
      report "Test 1.15 failed" severity failure;

    wait for 1.75 ns;
    v_addr := f_ipv6_addr_2_slv_arr("2001:db8:aaaa:bbbb:cccc:dddd:eeee:1");
    assert v_addr = (x"20", x"01", x"0d", x"b8", x"aa", x"aa", x"bb", x"bb", x"cc", x"cc", x"dd", x"dd", x"ee", x"ee", x"00", x"01")
      report "Test 1.16 failed" severity failure;

    wait for 1.75 ns;
    v_addr := f_ipv6_addr_2_slv_arr("2102:ec7::2");
    assert v_addr = (x"21", x"02", x"0e", x"c7", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"02")
      report "Test 1.17 failed" severity failure;

    wait for 100 ns;
    -- Finish the simulation
    msg("All tests are pass!");
    std.env.stop;
    wait;                               -- to stop completely
  end process p_main;

end architecture behav;
