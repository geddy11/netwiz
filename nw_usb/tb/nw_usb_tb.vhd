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
library nw_usb;
use nw_usb.nw_usb_pkg.all;

entity nw_usb_tb is
end entity nw_usb_tb;

architecture behav of nw_usb_tb is

  constant C_DATA1 : t_slv_arr(0 to 3)(7 downto 0) := (x"00", x"01", x"02", x"03");
  constant C_DATA2 : std_logic_vector(31 downto 0) := x"23456789";

begin

  p_main : process
    variable v_len       : natural;
    variable v_token     : t_slv_arr(0 to 0)(10 downto 0);
    variable v_data      : t_slv_arr(0 to 0)(31 downto 0);
    variable v_crc5      : std_logic_vector(4 downto 0);
    variable v_crc16     : std_logic_vector(15 downto 0);
    variable v_data_1bit : t_slv_arr(0 to 31)(0 downto 0);
    variable v_usb_pkt   : t_usb_packet;
    variable v_usb_pkt2  : t_usb_packet;
    variable v_pkt       : t_slv_arr(0 to 127)(7 downto 0);
  begin
    wait for 3.14 ns;
    -------------------------------------------------------------------------------
    -- nw_usb_pkg functions
    -------------------------------------------------------------------------------
    msg("Part 1: Verify nw_usb_pkg functions");

    v_token(0) := "10101000111";
    v_crc5     := not f_gen_crc(C_USB_CRC5, v_token, "11111");
    assert v_crc5 = "10111"
      report "Test 1.1 failed" severity failure;

    v_token(0) := "01011100101";
    v_crc5     := not f_gen_crc(C_USB_CRC5, v_token, "11111");
    assert v_crc5 = "11100"
      report "Test 1.2 failed" severity failure;

    v_data(0) := "00000000100000000100000011000000";
    v_crc16   := not f_gen_crc(C_USB_CRC16, v_data, x"ffff");
    assert v_crc16 = "1111011101011110"
      report "Test 1.3 failed" severity failure;

    v_data(0) := "11000100101000101110011010010001";
    v_crc16   := not f_gen_crc(C_USB_CRC16, v_data, x"ffff");
    assert v_crc16 = "0111000000111000"
      report "Test 1.4 failed" severity failure;

    wait for 2 ns;
    v_data_1bit := f_repack(C_DATA1, 1, true);
    v_crc16     := not f_gen_crc(C_USB_CRC16, C_DATA1, x"ffff", false);
    assert v_crc16 = "1111011101011110"
      report "Test 1.5 failed" severity failure;

    wait for 1.76 ns;
    v_usb_pkt                        := C_DEFAULT_USB_PACKET;
    v_usb_pkt.pkt_type               := DATA;
    v_usb_pkt.data_pkt.data_len      := 17;
    v_usb_pkt.data_pkt.data(0 to 16) := f_gen_prbs(C_POLY_X16_X15_X13_X4_1, 8, 17);
    v_len                            := f_usb_create_pkt_len(v_usb_pkt);
    assert v_len = 20
      report "Test 1.6 failed" severity failure;

    v_pkt(0 to v_len - 1) := f_usb_create_pkt(v_usb_pkt);
    v_crc16               := not f_gen_crc(C_USB_CRC16, v_pkt(1 to v_len - 3), x"ffff", false);
    assert v_crc16 = v_pkt(v_len - 2) & v_pkt(v_len - 1)
      report "Test 1.7 failed" severity failure;

    v_usb_pkt2 := f_usb_get_pkt(v_pkt(0 to v_len - 1));
    assert v_usb_pkt2.data_pkt.data(0 to 16) = v_usb_pkt.data_pkt.data(0 to 16)
      report "Test 1.8 failed" severity failure;

    wait for 100 ns;
    -- Finish the simulation
    msg("All tests are pass!");
    std.env.stop;
    wait;                               -- to stop completely
  end process p_main;

end architecture behav;
