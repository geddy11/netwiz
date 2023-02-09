-------------------------------------------------------------------------------
-- Title      : Network Wizard PTP test bench
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: Test bench for the NetWiz PTP package.
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
library nw_ptp;
use nw_ptp.nw_ptpv2_pkg.all;

entity nw_ptp_tb is
end entity nw_ptp_tb;

architecture behav of nw_ptp_tb is

  constant C_ANNOUNCE_MSG : t_slv_arr(0 to 63)(7 downto 0) := (x"0b", x"02", x"00", x"40", x"00", x"00", x"00", x"0c",
                                                               x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
                                                               x"00", x"00", x"00", x"00", x"00", x"80", x"63", x"ff",
                                                               x"ff", x"00", x"09", x"ba", x"00", x"02", x"02", x"20",
                                                               x"05", x"01", x"00", x"00", x"45", x"b1", x"11", x"4d",
                                                               x"2e", x"3a", x"de", x"0c", x"00", x"00", x"00", x"60",
                                                               x"00", x"00", x"00", x"80", x"63", x"ff", x"ff", x"00",
                                                               x"09", x"ba", x"f8", x"21", x"00", x"00", x"80", x"80");

  constant C_SYNC_MSG : t_slv_arr(0 to 43)(7 downto 0) := (x"00", x"02", x"00", x"2c", x"00", x"00", x"00", x"00",
                                                           x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
                                                           x"00", x"00", x"00", x"00", x"00", x"80", x"63", x"ff",
                                                           x"ff", x"00", x"09", x"ba", x"00", x"02", x"04", x"41",
                                                           x"00", x"00", x"00", x"00", x"45", x"b1", x"11", x"4d",
                                                           x"2e", x"2c", x"f0", x"30");


begin

  p_main : process
    variable v_msg  : t_ptpv2_msg;
    variable v_len  : natural;
    variable v_data : t_slv_arr(0 to 63)(7 downto 0);
  begin
    wait for 0.9674 ns;
    -------------------------------------------------------------------------------
    -- nw_ptpv2_pkg functions
    -------------------------------------------------------------------------------
    msg("Part 1: Verify nw_ptpv2_pkg functions");

    v_msg := f_ptpv2_get_msg(C_ANNOUNCE_MSG);
    assert v_msg.header.flag_field = (C_PTP_TIMESCALE or C_PTP_UTC_OFFSET_VALID)
      report "Test 1.1 failed" severity failure;

    assert v_msg.header.version_ptp = x"2" and v_msg.header.message_length = x"0040"
      report "Test 1.2 failed" severity failure;

    assert v_msg.header.message_type = C_MSG_ANNOUNCE
      report "Test 1.3 failed" severity failure;

    assert v_msg.header.sequence_id = x"0220"
      report "Test 1.4 failed" severity failure;

    assert v_msg.origin_timestamp.seconds = x"000045b1114d"
      report "Test 1.5 failed" severity failure;

    assert v_msg.origin_timestamp.nanoseconds = x"2e3ade0c"
      report "Test 1.6 failed" severity failure;

    v_len := f_ptpv2_create_pkt_len(v_msg);
    assert v_len = 64
      report "Test 1.7 failed" severity failure;

    v_data(0 to v_len - 1) := f_ptpv2_create_pkt(v_msg);
    assert v_data = C_ANNOUNCE_MSG
      report "Test 1.8 failed" severity failure;

    wait for 2.87 ns;
    v_msg := f_ptpv2_get_msg(C_SYNC_MSG);
    assert v_msg.header.flag_field = x"0000"
      report "Test 1.9 failed" severity failure;

    assert v_msg.header.version_ptp = x"2" and v_msg.header.message_length = x"002c"
      report "Test 1.10 failed" severity failure;

    assert v_msg.header.message_type = C_MSG_SYNC
      report "Test 1.11 failed" severity failure;

    wait for 100 ns;
    -- Finish the simulation
    msg("All tests are pass!");
    std.env.stop;
    wait;                               -- to stop completely
  end process p_main;

end architecture behav;
