-------------------------------------------------------------------------------
-- Title      : Network Wizard RTP test bench
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: Test bench for the NetWiz RTP package.
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

library nw_util;
context nw_util.nw_util_context;
library nw_rtp;
use nw_rtp.nw_rtp_pkg.all;

entity nw_rtp_tb is
end entity nw_rtp_tb;

architecture tb of nw_rtp_tb is

  constant C_RTP_1: t_slv_arr(0 to 251)(7 downto 0) := (x"80", x"08", x"25", x"8c", x"00", x"00", x"0c", x"30", x"f3", x"cb", x"20", x"01", x"50", x"d4", x"55", x"51",
                                                        x"d5", x"d4", x"d3", x"d4", x"d5", x"d7", x"d4", x"d4", x"d7", x"55", x"54", x"51", x"56", x"d4", x"56", x"56",
                                                        x"d5", x"d6", x"50", x"5c", x"d6", x"d3", x"57", x"55", x"d6", x"50", x"57", x"d3", x"55", x"51", x"d5", x"54",
                                                        x"51", x"55", x"d6", x"d1", x"51", x"5d", x"50", x"56", x"53", x"51", x"d3", x"d0", x"d1", x"d1", x"57", x"55",
                                                        x"d3", x"d4", x"51", x"d1", x"d1", x"56", x"d5", x"d7", x"d5", x"d6", x"d5", x"d7", x"d4", x"54", x"d7", x"50",
                                                        x"50", x"d7", x"d5", x"50", x"54", x"d4", x"d5", x"d7", x"d5", x"51", x"d5", x"d4", x"57", x"50", x"d5", x"d1",
                                                        x"53", x"5d", x"54", x"d1", x"54", x"51", x"d6", x"d3", x"56", x"53", x"d0", x"d1", x"57", x"57", x"57", x"d3",
                                                        x"d7", x"50", x"d0", x"d1", x"56", x"56", x"d7", x"54", x"57", x"55", x"57", x"55", x"57", x"55", x"57", x"54",
                                                        x"d5", x"56", x"d5", x"d3", x"d6", x"d5", x"d1", x"d7", x"d5", x"d5", x"d5", x"d5", x"d5", x"d7", x"54", x"57",
                                                        x"d1", x"dd", x"51", x"50", x"d7", x"57", x"50", x"d5", x"d3", x"53", x"5e", x"d7", x"d7", x"51", x"54", x"d5",
                                                        x"56", x"54", x"d4", x"57", x"51", x"d4", x"d6", x"d5", x"54", x"54", x"d5", x"57", x"57", x"54", x"d5", x"d1",
                                                        x"d5", x"57", x"d7", x"d2", x"d6", x"54", x"d7", x"d7", x"d5", x"d7", x"d6", x"57", x"54", x"55", x"57", x"54",
                                                        x"57", x"d5", x"51", x"57", x"d7", x"57", x"56", x"d5", x"d6", x"d5", x"57", x"d5", x"d6", x"d4", x"54", x"54",
                                                        x"d5", x"56", x"51", x"d5", x"d5", x"55", x"54", x"54", x"d7", x"d5", x"d5", x"d4", x"d5", x"54", x"55", x"d4",
                                                        x"54", x"d5", x"d7", x"d5", x"d5", x"d4", x"d5", x"54", x"57", x"50", x"54", x"d1", x"54", x"50", x"d1", x"d4",
                                                        x"51", x"d4", x"d1", x"56", x"54", x"d6", x"d5", x"55", x"d5", x"d5", x"d5", x"55");
  constant C_RTP_2: t_slv_arr(0 to 25)(7 downto 0) := (x"81", x"b5", x"02", x"e3", x"93", x"0b", x"2e", x"9c", x"69", x"38", x"8f", x"77", x"e6", x"1b", x"18", x"5e",
                                                       x"10", x"37", x"bb", x"0f", x"a5", x"a4", x"58", x"ec", x"86", x"5b");

begin

  p_main : process
    variable v_header : t_rtp_header;
    variable v_len    : natural;
    variable v_data   : t_slv_arr(0 to 239)(7 downto 0);
    variable v_pkt    : t_slv_arr(0 to 99)(7 downto 0);
  begin
    wait for 0.9674 ns;
    -------------------------------------------------------------------------------
    -- nw_rtp_pkg functions
    -------------------------------------------------------------------------------
    msg("Part 1: Verify nw_rtp_pkg get functions");

    v_header := f_rtp_get_header(C_RTP_1);
    assert v_header.version = "10"
      report "Test 1.1 failed (version)" severity failure;

    assert v_header.padding = '0'
      report "Test 1.2 failed (padding)" severity failure;

    assert v_header.extension = '0'
      report "Test 1.3 failed (extension)" severity failure;

    assert v_header.cc = "0000"
      report "Test 1.4 failed (cc)" severity failure;

    assert v_header.marker = '0'
      report "Test 1.5 failed (marker)" severity failure;

    assert v_header.payload_type = "0001000"
      report "Test 1.6 failed (payload type)" severity failure;

    assert v_header.sequence_id = x"258c"
      report "Test 1.7 failed (sequence id)" severity failure;

    assert v_header.timestamp = x"00000c30"
      report "Test 1.8 failed (timestamp)" severity failure;

    assert v_header.ssrc = x"f3cb2001"
      report "Test 1.9 failed (ssrc)" severity failure;

    v_len := f_rtp_get_payload_len(C_RTP_1);
    assert v_len = 240
      report "Test 1.10 failed (payload length)" severity failure;

    v_data(0 to v_len - 1) := f_rtp_get_payload(C_RTP_1);
    assert v_data(0 to v_len - 1) = C_RTP_1(12 to 11 + v_len)
      report "Test 1.11 failed (payload)" severity failure;

    v_header := f_rtp_get_header(C_RTP_2);
    assert v_header.version = "10"
      report "Test 1.12 failed (version)" severity failure;

    assert v_header.padding = '0'
      report "Test 1.13 failed (padding)" severity failure;

    assert v_header.extension = '0'
      report "Test 1.14 failed (extension)" severity failure;

    assert v_header.cc = "0001"
      report "Test 1.15 failed (cc)" severity failure;

    assert v_header.marker = '1'
      report "Test 1.16 failed (marker)" severity failure;

    assert v_header.payload_type = "0110101"
      report "Test 1.17 failed (payload type)" severity failure;

    assert v_header.sequence_id = x"02e3"
      report "Test 1.18 failed (sequence id)" severity failure;

    assert v_header.timestamp = x"930b2e9c"
      report "Test 1.19 failed (timestamp)" severity failure;

    assert v_header.ssrc = x"69388f77"
      report "Test 1.20 failed (ssrc)" severity failure;

    assert v_header.csrc(0) = x"e61b185e"
      report "Test 1.21 failed (csrc)" severity failure;

    wait for 50 ns;
    msg("Part 2: Verify nw_rtp_pkg create functions");
    
    v_len := f_rtp_get_payload_len(C_RTP_2);
    assert v_len = 10
      report "Test 1.22 failed (payload length)" severity failure;

    v_data(0 to v_len - 1) := f_rtp_get_payload(C_RTP_2);
    assert v_data(0 to v_len - 1) = C_RTP_2(16 to 15 + v_len)
      report "Test 1.23 failed (payload)" severity failure;

    v_len := f_rtp_create_pkt_len(v_header, v_data(0 to 9));
    assert v_len = 26
      report "Test 1.24 failed" severity failure;

    v_pkt(0 to v_len - 1) := f_rtp_create_pkt(v_header, v_data(0 to 9));
    assert v_pkt(0 to 25) = C_RTP_2
      report "Test 1.25 failed" severity failure;

    wait for 100 ns;
    -- Finish the simulation
    msg("All tests are pass!");
    std.env.stop;
    wait;                               -- to stop completely
  end process p_main;

end architecture tb;
