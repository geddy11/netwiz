-------------------------------------------------------------------------------
-- Title      : Network Wizard Utilities test bench
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: Test bench for the netwiz utilities package.
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


entity nw_util_tb is
end entity nw_util_tb;

architecture behav of nw_util_tb is

  constant C_PRBS_5  : t_slv_arr(0 to 0)(30 downto 0) := (others => "1001101001000010101110110001111");
  constant C_CRC16   : std_logic_vector(15 downto 0)  := x"8005";
  constant C_STACKED : t_slv_arr(0 to 1)(15 downto 0) := (x"5511", x"4222");

begin

  p_main : process
    variable v_a_8   : t_slv_arr(0 to 6)(7 downto 0)       := (x"11", x"22", x"33", x"44", x"55", x"66", x"77");
    variable v_a_24  : t_slv_arr(0 to 15)(23 downto 0);
    variable v_a_144 : t_slv_arr(0 to 0)(143 downto 0);
    variable v_a_4   : t_slv_arr(0 to 35)(3 downto 0);
    variable v_len   : natural;
    variable v_token : t_slv_arr(0 to 1)(7 downto 0)       := (x"55", x"42");
    variable v_udata : t_unsigned_arr(0 to 3)(15 downto 0) := (x"1234", x"ff65", x"7899", x"ade1");
    variable v_data  : t_slv_arr(0 to 3)(15 downto 0)      := (x"1234", x"ff65", x"7899", x"ade1");
    variable v_crc   : std_logic_vector(31 downto 0);
    variable v_a_16  : t_slv_arr(0 to 9)(15 downto 0)      := (x"4500", x"0073", x"0000", x"4000", x"4011", x"0000", x"c0a8", x"0001", x"c0a8", x"00c7");
    variable v_nrs   : t_slv_arr(0 to 255)(7 downto 0);
  begin
    wait for 1 ns;
    -------------------------------------------------------------------------------
    -- nw_util_pkg functions
    -------------------------------------------------------------------------------
    msg("Part 1: Verify nw_util_pkg functions");
    v_len                  := f_repack_len(v_a_8, 24);
    v_a_24(0 to v_len - 1) := f_repack(v_a_8, 24, C_MSB_FIRST, C_PAD_BEFORE, x"ff");
    v_a_144                := f_repack(f_concat(v_a_24(0 to v_len - 1), v_a_24(0 to v_len - 1)), 144, C_MSB_FIRST);
    v_len                  := f_repack_len(v_a_144, 4);
    v_a_4(0 to v_len - 1)  := f_bitflip(f_repack(v_a_144, 4));
    assert v_a_4 = f_bitflip(f_repack(f_concat(v_a_24(0 to 2), v_a_24(0 to 2)), 4))
      report "Test 1.1 failed" severity failure;

    assert f_repack(f_concat(v_a_8, v_a_8), 16, C_LSB_FIRST) = f_swap_endian(f_repack(f_concat(v_a_8, v_a_8), 16, C_MSB_FIRST))
      report "Test 1.2 failed" severity failure;

    assert v_udata = f_to_unsigned_arr(v_data)
      report "Test 1.3 failed" severity failure;

    assert v_data = f_to_slv_arr(v_udata)
      report "Test 1.4 failed" severity failure;

    assert C_STACKED = f_stack(v_token, v_a_8)
      report "Test 1.5 failed" severity failure;

    assert f_search(v_a_8, v_token(0 to 0)) = 4
      report "Test 1.6 failed" severity failure;

    assert f_search(v_a_8, v_token(1 to 1)) = -1
      report "Test 1.7 failed" severity failure;

    -------------------------------------------------------------------------------
    -- nw_prbs_pkg functions
    -------------------------------------------------------------------------------
    wait for 1.0009 ns;
    msg("Part 2: Verify nw_prbs_pkg functions");
    assert f_gen_prbs(C_POLY_X8_X6_X5_X4_1, 8, 32, C_MSB_FIRST, x"ff") = f_bitflip(f_gen_prbs(C_POLY_X8_X6_X5_X4_1, 8, 32, C_LSB_FIRST, x"ff"))
      report "Test 2.1 failed" severity failure;

    assert f_gen_prbs(C_POLY_X5_X3_1, 1, 31) = f_repack(C_PRBS_5, 1)
      report "Test 2.2 failed" severity failure;

    -------------------------------------------------------------------------------
    -- nw_crc_pkg functions
    -------------------------------------------------------------------------------
    wait for 1.736423 ns;
    msg("Part 3: Verify nw_crc_pkg functions");
    assert x"e177" = f_bitflip(f_gen_crc(C_CRC16, v_a_8, x"ffff", C_LSB_FIRST))  -- CRC-16/MODBUS
      report "Test 3.1 failed" severity failure;

    assert x"b861" = not f_gen_chksum(v_a_16, 16, true)
      report "Test 3.2 failed" severity failure;

    -------------------------------------------------------------------------------
    -- nw_nrs_pkg functions
    -------------------------------------------------------------------------------
    wait for 0.333 ns;
    msg("Part 4: Verify nw_nrs_pkg functions");
    assert f_gen_nrs(x"55", 256) = f_gen_nrs(x"55", 256, x"ff", false)
      report "Test 4.1 failed" severity failure;


    wait for 100 ns;
    -- Finish the simulation
    msg("All tests are pass!");
    std.env.stop;
    wait;                               -- to stop completely
  end process p_main;

end architecture behav;
