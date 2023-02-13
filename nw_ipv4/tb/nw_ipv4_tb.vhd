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

library nw_util;
context nw_util.nw_util_context;

library nw_ipv4;
context nw_ipv4.nw_ipv4_context;

entity nw_ipv4_tb is
  generic (
    GC_GHDL : integer := 0);            -- set to 1 when running GHDL
end entity nw_ipv4_tb;

architecture behav of nw_ipv4_tb is

  -- example UDP packet
  constant C_IPV4_UDP_PKT : t_slv_arr(0 to 309)(7 downto 0) := (x"45", x"00", x"01", x"36", x"00", x"00", x"40", x"00",
                                                                x"38", x"11", x"d8", x"3e", x"d8", x"3a", x"cf", x"ee",
                                                                x"c0", x"a8", x"00", x"a7", x"01", x"bb", x"ee", x"b5",
                                                                x"01", x"22", x"7f", x"12", x"40", x"62", x"45", x"db",
                                                                x"b0", x"b7", x"05", x"4b", x"31", x"98", x"0e", x"08",
                                                                x"21", x"b4", x"b2", x"5b", x"04", x"4d", x"fc", x"16",
                                                                x"0d", x"9d", x"f7", x"4c", x"16", x"9e", x"c7", x"72",
                                                                x"e0", x"b6", x"6c", x"60", x"db", x"0e", x"35", x"12",
                                                                x"88", x"e7", x"3b", x"c2", x"f2", x"e0", x"68", x"e3",
                                                                x"a2", x"c0", x"d4", x"b5", x"02", x"2b", x"c3", x"cb",
                                                                x"e6", x"ef", x"1f", x"dd", x"41", x"b5", x"45", x"65",
                                                                x"ab", x"58", x"b1", x"d7", x"26", x"68", x"bf", x"b7",
                                                                x"38", x"62", x"c1", x"ca", x"45", x"12", x"f8", x"e2",
                                                                x"5f", x"cc", x"e6", x"07", x"e6", x"83", x"75", x"54",
                                                                x"5d", x"94", x"3c", x"d2", x"5e", x"dc", x"5c", x"04",
                                                                x"de", x"f5", x"25", x"81", x"b3", x"29", x"b0", x"35",
                                                                x"13", x"23", x"e6", x"c0", x"b1", x"10", x"08", x"be",
                                                                x"33", x"22", x"c5", x"f1", x"59", x"fd", x"67", x"17",
                                                                x"e3", x"9f", x"7f", x"25", x"58", x"a7", x"6a", x"21",
                                                                x"46", x"6a", x"0d", x"86", x"ac", x"26", x"8a", x"b8",
                                                                x"38", x"2c", x"bd", x"99", x"20", x"07", x"9d", x"64",
                                                                x"c1", x"b8", x"70", x"2b", x"b0", x"0a", x"f8", x"c5",
                                                                x"c8", x"03", x"1a", x"de", x"59", x"75", x"ca", x"bb",
                                                                x"9b", x"50", x"0b", x"78", x"53", x"2a", x"5b", x"6e",
                                                                x"ec", x"e9", x"e1", x"97", x"08", x"2b", x"18", x"20",
                                                                x"5c", x"4d", x"b6", x"28", x"11", x"03", x"a9", x"42",
                                                                x"fc", x"76", x"d0", x"e5", x"8c", x"e1", x"cc", x"85",
                                                                x"cb", x"12", x"d1", x"f8", x"92", x"9e", x"62", x"5f",
                                                                x"ef", x"ec", x"7c", x"d3", x"6d", x"40", x"bd", x"36",
                                                                x"e2", x"ed", x"6c", x"e1", x"8a", x"ff", x"1c", x"63",
                                                                x"3a", x"a6", x"bb", x"3c", x"ac", x"f4", x"9a", x"35",
                                                                x"fe", x"8b", x"f8", x"53", x"df", x"20", x"75", x"3a",
                                                                x"7c", x"d6", x"d0", x"f5", x"66", x"ae", x"38", x"08",
                                                                x"f1", x"a2", x"01", x"ff", x"e1", x"f2", x"04", x"7c",
                                                                x"cf", x"0a", x"8d", x"5b", x"b6", x"31", x"13", x"95",
                                                                x"5f", x"57", x"2f", x"eb", x"1f", x"ed", x"f7", x"bd",
                                                                x"36", x"97", x"1d", x"44", x"ba", x"04", x"53", x"66",
                                                                x"13", x"30", x"9d", x"18", x"4e", x"3a", x"e7", x"d9",
                                                                x"1f", x"2c", x"63", x"53", x"dc", x"b8");
  -- captured ICMP packet
  constant C_ICMP_PKT : t_slv_arr(0 to 39)(7 downto 0) := (x"08", x"00", x"4d", x"5a", x"00", x"01", x"00", x"01",
                                                           x"61", x"62", x"63", x"64", x"65", x"66", x"67", x"68",
                                                           x"69", x"6a", x"6b", x"6c", x"6d", x"6e", x"6f", x"70",
                                                           x"71", x"72", x"73", x"74", x"75", x"76", x"77", x"61",
                                                           x"62", x"63", x"64", x"65", x"66", x"67", x"68", x"69");

  constant C_HEADER : t_slv_arr(0 to 19)(7 downto 0) := (x"45", x"00", x"00", x"73", x"00", x"00", x"40", x"00",
                                                         x"40", x"11", x"b8", x"61", x"c0", x"a8", x"00", x"01",
                                                         x"c0", x"a8", x"00", x"c7");

  -- captured TCP/IP packet (no payload)
  constant C_TCP_PKT1 : t_slv_arr(0 to 43)(7 downto 0) := (x"45", x"00", x"00", x"2c", x"00", x"00", x"40", x"00",
                                                           x"40", x"06", x"ab", x"55", x"c0", x"a8", x"07", x"1a",
                                                           x"c0", x"a8", x"07", x"0c",
                                                           x"df", x"85", x"04", x"cf", x"b8", x"9e", x"04", x"2a",
                                                           x"00", x"7b", x"4a", x"83", x"60", x"12", x"ff", x"ff",
                                                           x"1c", x"84", x"00", x"00", x"02", x"04", x"05", x"b4");

  -- TCP/IP packet with payload
  constant C_TCP_PKT2 : t_slv_arr(0 to 183)(7 downto 0) := (x"45", x"00", x"00", x"b8", x"5a", x"3e", x"40", x"00",
                                                            x"3d", x"06", x"c8", x"30", x"54", x"d0", x"04", x"b2",
                                                            x"c0", x"a8", x"00", x"a7", x"01", x"bb", x"e7", x"24",
                                                            x"92", x"3a", x"2c", x"a6", x"da", x"e3", x"1c", x"e1",
                                                            x"50", x"18", x"01", x"f5", x"57", x"66", x"00", x"00",
                                                            x"ef", x"f3", x"5e", x"f8", x"9c", x"e5", x"0e", x"3f",
                                                            x"83", x"32", x"4b", x"f2", x"a5", x"82", x"41", x"5e",
                                                            x"c1", x"00", x"b0", x"a4", x"d1", x"14", x"bf", x"30",
                                                            x"d1", x"85", x"80", x"f9", x"6d", x"dc", x"8b", x"0e",
                                                            x"d3", x"82", x"e0", x"af", x"b4", x"33", x"c1", x"e3",
                                                            x"19", x"f9", x"40", x"59", x"62", x"12", x"98", x"4d",
                                                            x"c2", x"c3", x"78", x"d4", x"ff", x"27", x"5d", x"b2",
                                                            x"aa", x"a3", x"6c", x"77", x"7d", x"a9", x"c4", x"67",
                                                            x"4f", x"ba", x"fe", x"fd", x"f0", x"bf", x"6f", x"88",
                                                            x"ab", x"b2", x"b7", x"93", x"d4", x"ab", x"b4", x"1f",
                                                            x"0f", x"2c", x"45", x"e4", x"4c", x"64", x"e1", x"8d",
                                                            x"ad", x"8e", x"c8", x"a3", x"9a", x"dc", x"79", x"c9",
                                                            x"59", x"bf", x"ff", x"c3", x"e4", x"81", x"43", x"e2",
                                                            x"f8", x"4a", x"b8", x"0c", x"ee", x"be", x"b1", x"f2",
                                                            x"75", x"dd", x"6d", x"c3", x"ea", x"61", x"f7", x"d3",
                                                            x"1c", x"c6", x"7a", x"58", x"d1", x"65", x"b8", x"6f",
                                                            x"a1", x"0d", x"2b", x"db", x"84", x"fe", x"bf", x"80",
                                                            x"24", x"fd", x"ec", x"2d", x"00", x"34", x"a8", x"12");

begin

  p_main : process

    variable v_payload     : t_slv_arr(0 to 289)(7 downto 0);
    variable v_ipv4_pkt    : t_slv_arr(0 to 309)(7 downto 0);
    variable v_ipv4_header : t_ipv4_header;
    variable v_len         : natural;
    variable v_plen        : natural;
    variable v_chksum      : std_logic_vector(15 downto 0);
    variable v_udp_header  : t_udp_header;
    variable v_icmp_header : t_icmpv4_header;
    variable v_icmpv4_pkt  : t_slv_arr(0 to 99)(7 downto 0);
    variable v_tcp_header  : t_tcp_header;
    variable v_tcp_pkt     : t_slv_arr(0 to 199)(7 downto 0);

  begin
    wait for 0.5674 ns;
    -------------------------------------------------------------------------------
    -- nw_ipv4_pkg functions
    -------------------------------------------------------------------------------
    msg("Part 1: Verify nw_ipv4_pkg functions");

    assert f_ipv4_chksum_ok(C_HEADER)
      report "Test 1.1 failed" severity failure;

    assert f_ipv4_chksum_ok(C_IPV4_UDP_PKT)
      report "Test 1.2 failed" severity failure;

    v_ipv4_header := f_ipv4_get_header(C_IPV4_UDP_PKT);
    assert v_ipv4_header.chksum = x"d83e"
      report "Test 1.3 failed" severity failure;

    v_len := f_ipv4_get_payload_len(C_IPV4_UDP_PKT);
    assert v_len = 290
      report "Test 1.4 failed" severity failure;

    v_payload(0 to v_len - 1) := f_ipv4_get_payload(C_IPV4_UDP_PKT);
    assert v_payload(0 to v_len - 1) = C_IPV4_UDP_PKT(20 to 309)
      report "Test 1.5 failed" severity failure;

    wait for 5 ns;
    v_len := f_ipv4_create_pkt_len(v_ipv4_header, v_payload);
    wait for 5 ns;
    assert v_len = 310
      report "Test 1.6 failed" severity failure;

    v_ipv4_pkt := f_ipv4_create_pkt(v_ipv4_header, v_payload);
    if GC_GHDL /= 1 then  -- this test fails in GHDL (but not Modelsim)
      assert v_ipv4_pkt(0 to 309) = C_IPV4_UDP_PKT(0 to 309)
        report "Test 1.7 failed" severity failure;

      assert f_ipv4_chksum_ok(v_ipv4_pkt)
        report "Test 1.8 failed" severity failure;
    else
      msg("Note! Test 1.7 & 1.8 are skipped when running GHDL");
    end if;

    -------------------------------------------------------------------------------
    -- nw_udpv4_pkg functions
    -------------------------------------------------------------------------------
    wait for 2.78 ns;
    msg("Part 2: Verify nw_udpv4_pkg functions");
    assert f_udpv4_chksum_ok(f_ipv4_get_header(C_IPV4_UDP_PKT), f_ipv4_get_payload(C_IPV4_UDP_PKT))
      report "Test 2.1 failed" severity failure;

    v_udp_header := f_udpv4_get_header(f_ipv4_get_payload(C_IPV4_UDP_PKT));
    assert v_udp_header.chksum = x"7f12"
      report "Test 2.2 failed" severity failure;

    v_len := f_udpv4_get_payload_len(f_ipv4_get_payload(C_IPV4_UDP_PKT));
    assert v_len = 282
      report "Test 2.3 failed" severity failure;

    v_payload(0 to v_len - 1) := f_udpv4_get_payload(f_ipv4_get_payload(C_IPV4_UDP_PKT));
    assert v_payload(0 to v_len - 1) = C_IPV4_UDP_PKT(28 to 309)
      report "Test 2.4 failed" severity failure;

    v_len     := f_udpv4_create_pkt_len(v_udp_header, f_udpv4_get_payload(f_ipv4_get_payload(C_IPV4_UDP_PKT)));
    v_payload := f_udpv4_create_pkt(f_ipv4_get_header(C_IPV4_UDP_PKT), v_udp_header, f_udpv4_get_payload(f_ipv4_get_payload(C_IPV4_UDP_PKT)));
    if GC_GHDL /= 1 then  -- this test fails in GHDL (but not Modelsim)
      assert v_payload(0 to v_len - 1) = C_IPV4_UDP_PKT(20 to 309)
        report "Test 2.5 failed" severity failure;
    else
      msg("Note! Test 2.5 is skipped when running GHDL");
    end if;

    -------------------------------------------------------------------------------
    -- nw_icmpv4_pkg functions
    -------------------------------------------------------------------------------
    wait for 3.71 ns;
    msg("Part 3: Verify nw_icmpv4_pkg functions");
    assert f_icmpv4_chksum_ok(C_ICMP_PKT)
      report "Test 3.1 failed" severity failure;

    v_len := f_icmpv4_get_payload_len(C_ICMP_PKT);
    assert v_len = 32
      report "Test 3.2 failed" severity failure;

    v_payload(0 to v_len - 1) := f_icmpv4_get_payload(C_ICMP_PKT);
    assert v_payload(0 to v_len - 1) = C_ICMP_PKT(8 to 39)
      report "Test 3.3 failed" severity failure;

    v_icmp_header := f_icmpv4_get_header(C_ICMP_PKT);
    assert v_icmp_header.chksum = x"4d5a"
      report "Test 3.4 failed" severity failure;

    v_icmp_header.chksum := x"0000";
    v_len                := f_icmpv4_create_pkt_len(v_icmp_header, f_icmpv4_get_payload(C_ICMP_PKT));
    assert v_len = 40
      report "Test 3.5 failed" severity failure;

    v_icmpv4_pkt(0 to v_len - 1) := f_icmpv4_create_pkt(v_icmp_header, v_payload(0 to 31));

    if GC_GHDL /= 1 then  -- this test fails in GHDL (but not Modelsim)
      assert v_icmpv4_pkt(0 to v_len - 1) = C_ICMP_PKT
        report "Test 3.6 failed" severity failure;
    else
      msg("Note! Test 3.6 is skipped when running GHDL");
    end if;

    -------------------------------------------------------------------------------
    -- nw_tcpv4_pkg functions
    -------------------------------------------------------------------------------
    wait for 3.71 ns;
    msg("Part 4: Verify nw_tcpv4_pkg functions");
    v_payload(0 to 23) := f_ipv4_get_payload(C_TCP_PKT1);
    v_tcp_header       := f_tcpv4_get_header(v_payload(0 to 23));
    assert v_tcp_header.dest_port = x"04cf" and v_tcp_header.data_offset = x"6"
      report "Test 4.1 failed" severity failure;

    assert v_tcp_header.flags = (C_TCP_FLAG_ACK or C_TCP_FLAG_SYN)
      report "Test 4.2 failed" severity failure;

    assert v_tcp_header.options(0 to 3) = C_TCP_PKT1(40 to 43)
      report "Test 4.3 failed" severity failure;

    v_ipv4_header := f_ipv4_get_header(C_TCP_PKT1);
    assert f_tcpv4_chksum_ok(v_ipv4_header, v_payload(0 to 23))
      report "Test 4.4 failed" severity failure;
    wait for 1.01 ns;

    v_len := f_tcpv4_create_pkt_len(v_ipv4_header, v_tcp_header);
    assert v_len = 24
      report "Test 4.5 failed" severity failure;
    v_payload(0 to 23) := f_tcpv4_create_pkt(v_ipv4_header, v_tcp_header);

    assert v_payload(0 to 23) = C_TCP_PKT1(20 to 43)
      report "Test 4.6 failed" severity failure;

    v_plen := f_tcpv4_get_payload_len(f_ipv4_get_payload(C_TCP_PKT2));
    assert v_plen = 144
      report "Test 4.7 failed" severity failure;

    v_payload(0 to v_plen - 1) := f_tcpv4_get_payload(f_ipv4_get_payload(C_TCP_PKT2));

    wait for 2.2 ns;
    v_len := f_tcpv4_create_pkt_len(f_ipv4_get_header(C_TCP_PKT2),
                                    f_tcpv4_get_header(f_ipv4_get_payload(C_TCP_PKT2)),
                                    v_payload(0 to v_plen - 1));

    assert v_len = 164
      report "Test 4.8 failed" severity failure;

    v_tcp_pkt(0 to v_len - 1) := f_tcpv4_create_pkt(f_ipv4_get_header(C_TCP_PKT2),
                                                    f_tcpv4_get_header(f_ipv4_get_payload(C_TCP_PKT2)),
                                                    v_payload(0 to v_plen - 1));
    assert v_tcp_pkt(0 to v_len - 1) = C_TCP_PKT2(20 to 183)
      report "Test 4.9 failed" severity failure;

    wait for 100 ns;
    -- Finish the simulation
    msg("All tests are pass!");
    std.env.stop;
    wait;                               -- to stop completely
  end process p_main;

end architecture behav;
