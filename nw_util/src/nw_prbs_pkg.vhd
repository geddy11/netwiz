-------------------------------------------------------------------------------
-- Title      : PRBS package
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: 
--!\file
--!\brief Generate Pseudo-Random Binary Sequences
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
--! @cond libraries
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library nw_adapt;
use nw_adapt.nw_adaptations_pkg.all;

use work.nw_types_pkg.all;
use work.nw_util_pkg.all;
--! @endcond

--! \page nw_prbs PRBS
--! \tableofcontents
--! \section prbs Pseudo-Random Binary Sequences
--! This library provides functions for generation of Pseudo-Random Binary Sequences.
--! A maximum length sequence has some unique properties. If the order of the polynomial is n, then
--! the length of the sequence will be 2^n - 1, the longest run of 1's will be n and the longest run of 0's in that sequence will be n - 1.
--!
--! \subsection prbs_subsec1 Functionality
--! \li Predefined polynomials for maximum-length sequences
--! \li Any data width and length
--!
--! \n More details in \ref nw_prbs_pkg
--! \subsection prbs_subsec2 Example use
--! Include the libraries:
--! ~~~
--! library nw_util;
--! context nw_util.nw_util_context;
--! ~~~
--! Generate a data array of 8bit pseudo-random numbers:
--! ~~~
--! array_8bit(0 to 127) := f_gen_prbs(C_POLY_X16_X15_X13_X4_1, 8, 128);
--! array_8bit(0 to 127) := f_gen_prbs(C_POLY_X16_X15_X13_X4_1, 8, 128, C_LSB_FIRST); -- same sequence, but words bitflipped
--! array_8bit(0 to 127) := f_gen_prbs(C_POLY_X16_X15_X13_X4_1, 8, 128, C_LSB_FIRST, x"8123"); -- same polynomial, but different init value
--! ~~~
--! Maximum length sequences can also be utilized to generate a range of unique, random numbers. 
--! Say we want to generate 1024 unique MAC addresses to verify a MAC lookup table, from the range \c 7c:10:xx:xx:xx:xx:
--! ~~~
--! mac_array(0 to 1023) := f_stack(f_gen_nrs(x"7c10", 1024, "0"), f_gen_prbs(C_POLY_X32_X22_X2_X1_1, 32, 1024));
--! ~~~
--! See further examples in the test bench nw_util_tb.vhd.
package nw_prbs_pkg is

  -------------------------------------------------------------------------------
  -- Example maximum length polynomials
  -- Source: https://en.wikipedia.org/wiki/Linear-feedback_shift_register
  -- @cond constants
  -------------------------------------------------------------------------------
  constant C_POLY_X2_X_1            : std_logic_vector(1 downto 0)  := "11";  -- x^2+x+1    
  constant C_POLY_X3_X2_1           : std_logic_vector(2 downto 0)  := "110";  -- x^3+x^2+1        
  constant C_POLY_X4_X3_1           : std_logic_vector(3 downto 0)  := "1100";  -- x^4+x^3+1
  constant C_POLY_X5_X3_1           : std_logic_vector(4 downto 0)  := "10100";  -- x^5+x^3+1
  constant C_POLY_X6_X5_1           : std_logic_vector(5 downto 0)  := "110000";  -- x^6+x^5+1
  constant C_POLY_X7_X6_1           : std_logic_vector(6 downto 0)  := "1100000";  -- x^7+x^6+1
  constant C_POLY_X8_X6_X5_X4_1     : std_logic_vector(7 downto 0)  := "10110100";  -- x^8+x^6+x^5+x^4+1
  constant C_POLY_X9_X5_1           : std_logic_vector(8 downto 0)  := "100010000";  -- x^9+x^5+1
  constant C_POLY_X10_X7_1          : std_logic_vector(9 downto 0)  := "1001000000";  -- x^10+x^7+1
  constant C_POLY_X11_X9_1          : std_logic_vector(10 downto 0) := "10100000000";  -- x^11+x^9+1
  constant C_POLY_X12_X11_X10_X4_1  : std_logic_vector(11 downto 0) := "111000001000";  -- x^12+x^11+x^10+x^4+1
  constant C_POLY_X13_X12_X11_X8_1  : std_logic_vector(12 downto 0) := "1110010000000";  -- x^13+x^12+x^11+x^8+1
  constant C_POLY_X14_X13_X12_X2_1  : std_logic_vector(13 downto 0) := "11100000000010";  -- x^14+x^13+x^12+x^2+1
  constant C_POLY_X15_X14_1         : std_logic_vector(14 downto 0) := "110000000000000";  -- x^15+x^14+1
  constant C_POLY_X16_X15_X13_X4_1  : std_logic_vector(15 downto 0) := "1101000000001000";  -- x^16+x^15+x^13+x^4+1
  constant C_POLY_X17_X14_1         : std_logic_vector(16 downto 0) := "10010000000000000";  -- x^17+x^14+1
  constant C_POLY_X18_X11_1         : std_logic_vector(17 downto 0) := "100000010000000000";  -- x^18+x^11+1
  constant C_POLY_X19_X18_X17_X14_1 : std_logic_vector(18 downto 0) := "1110010000000000000";  -- x^19+x^18+x^17+x^14+1
  constant C_POLY_X20_X17_1         : std_logic_vector(19 downto 0) := "10010000000000000000";  -- x^20+x^17+1
  constant C_POLY_X21_X19_1         : std_logic_vector(20 downto 0) := "101000000000000000000";  -- x^21+x^19+1
  constant C_POLY_X22_X21_1         : std_logic_vector(21 downto 0) := "1100000000000000000000";  -- x^22+x^21+1
  constant C_POLY_X23_X18_1         : std_logic_vector(22 downto 0) := "10000100000000000000000";  -- x^23+x^18+1
  constant C_POLY_X24_X23_X22_X17_1 : std_logic_vector(23 downto 0) := "111000010000000000000000";  -- x^24+x^23+x^22+x^17+1
  constant C_POLY_X25_X22_1         : std_logic_vector(24 downto 0) := "1001000000000000000000000";  -- x^25+x^22+1
  constant C_POLY_X26_X6_X2_X1_1    : std_logic_vector(25 downto 0) := "10000000000000000000100011";  -- x^26+x^6+x^2+x+1
  constant C_POLY_X27_X5_X2_X1_1    : std_logic_vector(26 downto 0) := "100000000000000000000010011";  -- x^27+x^5+1
  constant C_POLY_X28_X25_1         : std_logic_vector(27 downto 0) := "1001000000000000000000000000";  -- x^28+x^25+1
  constant C_POLY_X29_X27_1         : std_logic_vector(28 downto 0) := "10100000000000000000000000000";  -- x^29+x^27+1
  constant C_POLY_X30_X6_X4_X1_1    : std_logic_vector(29 downto 0) := "100000000000000000000000101001";  -- x^30+x^6+x^4+x^1+1
  constant C_POLY_X31_X28_1         : std_logic_vector(30 downto 0) := "1001000000000000000000000000000";  -- x^31+x^28+1
  constant C_POLY_X32_X22_X2_X1_1   : std_logic_vector(31 downto 0) := "10000000001000000000000000000011";  -- x^32+x^22+x^2+x^1+1
  -- @endcond

  -------------------------------------------------------------------------------
  -- PRBS functions
  --! @cond functions
  -------------------------------------------------------------------------------
  function f_gen_prbs(poly       : std_logic_vector;
                      data_width : positive;
                      length     : positive;
                      msb_first  : boolean;
                      init       : std_logic_vector) return t_slv_arr;

  function f_gen_prbs(poly       : std_logic_vector;
                      data_width : positive;
                      length     : positive;
                      msb_first  : boolean := true) return t_slv_arr;
  --! @endcond

end package nw_prbs_pkg;

package body nw_prbs_pkg is

  -------------------------------------------------------------------------------
  --! \brief Create PRBS sequence
  --! \param poly        Polynomial to use
  --! \param data_width  Data width
  --! \param length      Number of data words
  --! \param msb_first   Pack bits MSB in data words first (True), or LSB (False)
  --! \param init        LFSR init value 
  --! \return            PRBS sequence in data array
  --!
  --! Generate a PRBS sequence of given length and data width. The LFSR uses Galois configuration. 
  --! Example maximum length polynomials up to order 32 can be found as constants. Init value cannot be zero (would return all zero array). 
  --!
  --! **Example use**
  --! ~~~
  --! array_8bit := f_gen_prbs(C_POLY_X6_X5_1, 8, 6, C_MSB_FIRST, "1111111");
  --! ~~~
  -------------------------------------------------------------------------------
  function f_gen_prbs(poly       : std_logic_vector;  -- Polynomial to use
                      data_width : positive;          -- data width
                      length     : positive;          -- number of data words 
                      msb_first  : boolean;
                      init       : std_logic_vector)  -- LSFR init value
    return t_slv_arr is
    constant C_MSB      : natural                               := poly'length - 1;
    constant C_TAPS     : std_logic_vector(C_MSB downto 0)      := poly;
    constant C_INIT_MSB : natural                               := init'length - 1;
    constant C_INIT     : std_logic_vector(C_INIT_MSB downto 0) := init;

    variable v_prbs : t_slv_arr(0 to data_width * length - 1)(0 downto 0);
    variable v_sreg : std_logic_vector(C_MSB downto 0);
    variable v_fb   : std_logic_vector(C_MSB downto 0);
  begin
    assert poly'length > 1 report "f_gen_prbs: polynomial must be at least two-bit" severity C_SEVERITY;
    assert poly'length = init'length report "f_gen_prbs: init value must be same width as polynomial" severity C_SEVERITY;

    v_sreg := C_INIT;
    for i in 0 to data_width * length - 1 loop
      v_fb(0) := v_sreg(C_MSB);
      for k in 1 to C_MSB loop
        v_fb(k) := (v_sreg(C_MSB) and C_TAPS(k - 1)) xor v_sreg(k - 1);
      end loop;
      v_sreg    := v_fb;
      v_prbs(i) := (others => v_sreg(C_MSB));
    end loop;

    return f_repack(v_prbs, data_width, msb_first);
  end function f_gen_prbs;

  -------------------------------------------------------------------------------
  --! \brief Create PRBS sequence
  --! \param poly        Polynomial to use
  --! \param data_width  Data width
  --! \param length      Number of data words
  --! \param msb_first   Pack bits MSB in data words first (True, default), or LSB (False)
  --! \return            PRBS sequence in data array
  --!
  --! This is an overloaded verison of f_gen_prbs with init value set to all 1's.
  --!
  --! **Example use**
  --! ~~~
  --! array_8bit := f_gen_prbs(C_POLY_X6_X5_1, 8, 6);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_gen_prbs(poly       : std_logic_vector;
                      data_width : positive;
                      length     : positive;
                      msb_first  : boolean := true)
    return t_slv_arr is
    constant C_MSB  : natural                          := poly'length - 1;
    constant C_INIT : std_logic_vector(C_MSB downto 0) := (others => '1');
  begin
    return f_gen_prbs(poly, data_width, length, msb_first, C_INIT);
  end function f_gen_prbs;

end package body nw_prbs_pkg;
