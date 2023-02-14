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
library nw_ipv6;
context nw_ipv6.nw_ipv6_context;
library nw_ethernet;
context nw_ethernet.nw_ethernet_context;

entity nw_ipv6_tb is
  generic (
    GC_GHDL : integer := 0);            -- set to 1 when running GHDL
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

  constant C_UDPV6_PKT : t_slv_arr(0 to 79)(7 downto 0) := (x"60", x"00", x"00", x"00", x"00", x"28", x"11", x"1a",
                                                            x"2a", x"01", x"02", x"38", x"43", x"63", x"ee", x"00",
                                                            x"91", x"69", x"a8", x"a4", x"e5", x"72", x"d5", x"f8",
                                                            x"2a", x"01", x"04", x"88", x"00", x"42", x"10", x"00",
                                                            x"50", x"ed", x"85", x"88", x"00", x"8a", x"c5", x"70",
                                                            x"b2", x"91", x"82", x"e6", x"00", x"28", x"a6", x"ce",
                                                            x"40", x"41", x"42", x"43", x"44", x"45", x"46", x"47",
                                                            x"48", x"49", x"4a", x"4b", x"4c", x"4d", x"4e", x"4f",
                                                            x"50", x"51", x"52", x"53", x"54", x"55", x"56", x"57",
                                                            x"58", x"59", x"5a", x"5b", x"5c", x"5d", x"5e", x"5f");

  constant C_TCP_IPV6_PKT : t_slv_arr(0 to 71)(7 downto 0) := (x"60", x"01", x"48", x"a4", x"00", x"20", x"06", x"40",
                                                               x"26", x"07", x"f0", x"10", x"03", x"f9", x"00", x"00",
                                                               x"00", x"00", x"00", x"00", x"00", x"00", x"10", x"01",
                                                               x"26", x"07", x"f0", x"10", x"03", x"f9", x"00", x"00",
                                                               x"00", x"00", x"00", x"00", x"00", x"11", x"00", x"00",
                                                               x"18", x"db", x"b3", x"c9", x"81", x"27", x"aa", x"b1",
                                                               x"c3", x"20", x"06", x"58", x"80", x"10", x"0f", x"ff",
                                                               x"3a", x"01", x"00", x"00", x"01", x"01", x"08", x"0a",
                                                               x"5a", x"c9", x"fd", x"45", x"2a", x"a6", x"a3", x"dd");

begin

  p_main : process

    variable v_payload       : t_slv_arr(0 to 289)(7 downto 0);
    variable v_ipv6_pkt      : t_slv_arr(0 to 309)(7 downto 0);
    variable v_ipv6_header   : t_ipv6_header;
    variable v_len           : natural;
    variable v_plen          : natural;
    variable v_ext_headers   : t_ext_header_list := C_DEFAULT_EXT_HEADER_LIST;
    variable v_addr          : t_slv_arr(0 to 15)(7 downto 0);
    variable v_udp_header    : t_udp_header;
    variable v_tcp_header    : t_tcp_header;
    variable v_icmpv6_header : t_icmpv6_header;
    variable v_icmpv6_pkt    : t_slv_arr(0 to 99)(7 downto 0);
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

    -------------------------------------------------------------------------------
    -- nw_udpv6_pkg functions
    -------------------------------------------------------------------------------
    wait for 3.01 ns;
    msg("Part 2: Verify nw_udpv6_pkg functions");

    assert f_udpv6_chksum_ok(f_ipv6_get_header(C_UDPV6_PKT), f_ipv6_get_payload(C_UDPV6_PKT))
      report "Test 2.1 failed" severity failure;

    v_udp_header := f_udpv6_get_header(f_ipv6_get_payload(C_UDPV6_PKT));
    assert v_udp_header.chksum = x"a6ce"
      report "Test 2.2 failed" severity failure;

    v_len := f_udpv6_get_payload_len(f_ipv6_get_payload(C_UDPV6_PKT));
    assert v_len = 32
      report "Test 2.3 failed" severity failure;

    v_payload(0 to v_len - 1) := f_udpv6_get_payload(f_ipv6_get_payload(C_UDPV6_PKT));
    assert v_payload(0 to v_len - 1) = C_UDPV6_PKT(48 to 79)
      report "Test 2.4 failed" severity failure;

    v_len                     := f_udpv6_create_pkt_len(f_ipv6_get_header(C_UDPV6_PKT), v_udp_header, f_udpv6_get_payload(f_ipv6_get_payload(C_UDPV6_PKT)));
    v_payload(0 to v_len - 1) := f_udpv6_create_pkt(f_ipv6_get_header(C_UDPV6_PKT), v_udp_header, f_udpv6_get_payload(f_ipv6_get_payload(C_UDPV6_PKT)));
    assert v_payload(0 to v_len - 1) = C_UDPV6_PKT(40 to 79)
      report "Test 2.5 failed" severity failure;

    -------------------------------------------------------------------------------
    -- nw_icmpv6_pkg functions
    -------------------------------------------------------------------------------
    wait for 3.01 ns;
    msg("Part 3: Verify nw_icmpv6_pkg functions");

    v_ipv6_header := f_ipv6_get_header(f_eth_get_payload(C_ICMPV6_PKT));

    assert f_icmpv6_chksum_ok(v_ipv6_header, f_ipv6_get_payload(f_eth_get_payload(C_ICMPV6_PKT)))
      report "Test 3.1 failed" severity failure;

    v_icmpv6_header := f_icmpv6_get_header(f_ipv6_get_payload(f_eth_get_payload(C_ICMPV6_PKT)));
    assert v_icmpv6_header.icmp_type = C_ICMPV6_PKT(62)
      report "Test 3.2 failed" severity failure;

    assert v_icmpv6_header.icmp_code = C_ICMPV6_PKT(63)
      report "Test 3.3 failed" severity failure;

    assert v_icmpv6_header.chksum = C_ICMPV6_PKT(64) & C_ICMPV6_PKT(65)
      report "Test 3.4 failed" severity failure;

    v_plen := f_icmpv6_get_payload_len(f_ipv6_get_payload(f_eth_get_payload(C_ICMPV6_PKT)));
    assert v_plen = 24
      report "Test 3.5 failed" severity failure;

    v_payload(0 to v_plen - 1) := f_icmpv6_get_payload(f_ipv6_get_payload(f_eth_get_payload(C_ICMPV6_PKT)));
    assert v_payload(0 to v_plen - 1) = C_ICMPV6_PKT(66 to 89)
      report "Test 3.6 failed" severity failure;

    v_len := f_icmpv6_create_pkt_len(v_ipv6_header, v_icmpv6_header, v_payload(0 to v_plen - 1));
    assert v_len = 28
      report "Test 3.7 failed" severity failure;

    v_icmpv6_pkt(0 to v_len - 1) := f_icmpv6_create_pkt(v_ipv6_header, v_icmpv6_header, v_payload(0 to v_plen - 1));
    if GC_GHDL /= 1 then  -- this test fails in GHDL (but not Modelsim)
      assert v_icmpv6_pkt(0 to v_len - 1) = C_ICMPV6_PKT(62 to 89)
        report "Test 3.8 failed" severity failure;
    else
      msg("Note! Test 3.8 is skipped when running GHDL");
    end if;

    -------------------------------------------------------------------------------
    -- nw_tcpv6_pkg functions
    -------------------------------------------------------------------------------
    wait for 1.47 ns;
    msg("Part 4: Verify nw_tcpv6_pkg functions");
    v_payload(0 to 31) := f_ipv6_get_payload(C_TCP_IPV6_PKT);
    v_tcp_header       := f_tcpv6_get_header(v_payload(0 to 31));
    assert v_tcp_header.src_port = x"18db" and v_tcp_header.data_offset = x"8"
      report "Test 4.1 failed" severity failure;

    assert v_tcp_header.flags = C_TCP_FLAG_ACK
      report "Test 4.2 failed" severity failure;

    assert v_tcp_header.options(0 to 11) = C_TCP_IPV6_PKT(60 to 71)
      report "Test 4.3 failed" severity failure;

    wait for 1.01 ns;
    v_ipv6_header := f_ipv6_get_header(C_TCP_IPV6_PKT);
    assert f_tcpv6_chksum_ok(f_ipv6_get_header(C_TCP_IPV6_PKT), f_ipv6_get_payload(C_TCP_IPV6_PKT))
      report "Test 4.4 failed" severity failure;

    v_plen := f_tcpv6_get_payload_len(f_ipv6_get_payload(C_TCP_IPV6_PKT));
    assert v_plen = 0
      report "Test 4.5 failed" severity failure;

    v_len := f_tcpv6_create_pkt_len(v_ipv6_header, v_tcp_header);
    assert v_len = 32
      report "Test 4.6 failed" severity failure;

    v_payload(0 to 31) := f_tcpv6_create_pkt(v_ipv6_header, v_tcp_header);

    assert v_payload(0 to 31) = C_TCP_IPV6_PKT(40 to 71)
      report "Test 4.7 failed" severity failure;



    wait for 100 ns;
    -- Finish the simulation
    msg("All tests are pass!");
    std.env.stop;
    wait;                               -- to stop completely
  end process p_main;

end architecture behav;
