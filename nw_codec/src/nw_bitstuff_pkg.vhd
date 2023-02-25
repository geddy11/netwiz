-------------------------------------------------------------------------------
-- Title      : Network Wizard Bit Stuffing
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: 
--!\file
--!\brief Bit stuffing functions
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
library nw_util;
context nw_util.nw_util_context;
--! @endcond

--! \page nw_bstuff Bit stuffing
--! \tableofcontents
--! \section bitstuff Bit Stuffing
--! This library provides functions for bit stuffing.  
--!
--! \subsection bstuff_subsec1 Functionality
--! \li Perform bit-stuffing encoding and decoding of 1bit arrays. 
--!
--! The bit-stuffing algorithm inserts an extra bit if a sequence of bits with the same value is longer than a specified threshold.
--!
--! \n More details in \ref nw_bitstuff_pkg
--! \subsection bstuff_subsec2 Example use
--! Include the libraries:
--! ~~~
--! library nw_codec;
--! context nw_codec.nw_codec_context;
--! ~~~
--! Example: HDLC-style bit-stuffing. Assume we have a HDLC frame in the variable \c v_data (8bit format). A zero-bit shall be inserted after each sequence of 5 one's.
--! The 8-bit frame is converted to 1-bit with f_repack().
--! ~~~
--! v_len                     := f_bitstuff_enc_len(f_repack(v_data, 1), 5); -- get length of encoded data (v_data is here 8bit, and is repacked to 1bit)
--! v_encoded(0 to v_len - 1) := f_bitstuff_enc(f_repack(v_data, 1), 5); -- encode 
--! ~~~
--! Add FEC (0x7e) before and after the bit-stuffed HDLC frame:
--! ~~~
--! v_encoded(0 to v_len + 15) :=  f_concat("01111110", f_concat(v_encoded, "01111110")); -- add FEC before and after data frame
--! ~~~
--! Decoding of a bit-stuffed frame:
--! ~~~
--! v_dlen                     := f_bitstuff_dec_len(v_encoded(0 to v_len - 1)); -- get length of decoded data 
--! v_decoded(0 to v_dlen - 1) := f_bitstuff_dec(v_encoded(0 to v_len - 1)); 
--! ~~~
--! See further examples in the test bench nw_codec_tb.vhd.
package nw_bitstuff_pkg is

  -------------------------------------------------------------------------------
  -- Functions
  -------------------------------------------------------------------------------
  function f_bitstuff_enc(data       : t_slv_arr;
                          run_length : positive;
                          run_type   : std_logic := '1') return t_slv_arr;

  function f_bitstuff_enc_len (data       : t_slv_arr;
                               run_length : positive;
                               run_type   : std_logic := '1') return natural;

  function f_bitstuff_dec(data       : t_slv_arr;
                          run_length : positive;
                          run_type   : std_logic := '1') return t_slv_arr;

  function f_bitstuff_dec_len (data       : t_slv_arr;
                               run_length : positive;
                               run_type   : std_logic := '1') return natural;

end package nw_bitstuff_pkg;

package body nw_bitstuff_pkg is

  -------------------------------------------------------------------------------
  -- Encode data (internal)
  -------------------------------------------------------------------------------
  function f_bitstuff_enc(data       : t_slv_arr;
                          run_length : positive;
                          run_type   : std_logic;
                          get_length : boolean := false)
    return t_slv_arr is
    variable v_data   : t_slv_arr(0 to 2 * data'length)(0 downto 0);
    variable v_len    : natural := 0;
    variable v_cnt    : natural := 0;
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    assert data'ascending report "f_bitstuff_enc: data array must be ascending" severity C_SEVERITY;
    assert data(data'low)'length = 1 report "f_bitstuff_enc: data must be 1bit" severity C_SEVERITY;
    assert run_length > 1 report "f_bitstuff_enc: run_length must be > 1" severity C_SEVERITY;

    for i in data'low to data'high loop
      v_data(v_len) := data(i);
      v_len         := v_len + 1;
      if data(i)(0) = run_type then
        v_cnt := v_cnt + 1;
        if v_cnt = run_length then
          v_data(v_len)(0) := not run_type;
          v_len            := v_len + 1;
          v_cnt            := 0;
        end if;
      else
        v_cnt := 0;
      end if;
    end loop;
    if get_length then
      v_length(0) := std_logic_vector(to_unsigned(v_len, 31));
      return v_length;
    else
      return v_data(0 to v_len - 1);
    end if;
  end function f_bitstuff_enc;

  -------------------------------------------------------------------------------
  --! \brief Encode data
  --! \param data       Data array (1bit)
  --! \param run_length Maximum run length before stuff bit is inserted
  --! \param run_type   Run-length value (default '1')
  --! \return           Encoded data
  --!
  --! Encode data with bit-stuffing. If a sequence of bits with value run_type longer than run_length is enconutered, a stuff bit of inverse value is inserted.
  --!
  --! **Example use**
  --! ~~~
  --! encoded_data := f_bitstuff_enc(data_1bit, 5);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_bitstuff_enc(data       : t_slv_arr;
                          run_length : positive;
                          run_type   : std_logic := '1')
    return t_slv_arr is
  begin
    return f_bitstuff_enc(data, run_length, run_type, false);
  end function f_bitstuff_enc;

  -------------------------------------------------------------------------------
  --! \brief Get encoded data length
  --! \param data       Data array (1bit)
  --! \param run_length Maximum run length before stuff bit is inserted
  --! \param run_type   Run-length value (default '1')
  --! \return           Encoded data length
  --!
  --! Get length of encoded data after applying bit stuffing.
  --!
  --! **Example use**
  --! ~~~
  --! v_len := f_bitstuff_enc_len(data_1bit, 5);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_bitstuff_enc_len(data       : t_slv_arr;
                              run_length : positive;
                              run_type   : std_logic := '1')
    return natural is
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    v_length := f_bitstuff_enc(data, run_length, run_type, true);
    return to_integer(unsigned(v_length(0)));
  end function f_bitstuff_enc_len;

  -------------------------------------------------------------------------------
  -- Decode data (internal)
  -------------------------------------------------------------------------------
  function f_bitstuff_dec(data       : t_slv_arr;
                          run_length : positive;
                          run_type   : std_logic;
                          get_length : boolean := false)
    return t_slv_arr is
    variable v_data   : t_slv_arr(0 to data'length)(0 downto 0);
    variable v_len    : natural := 0;
    variable v_cnt    : natural := 0;
    variable v_skip   : boolean := false;
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    assert data'ascending report "f_bitstuff_dec: data array must be ascending" severity C_SEVERITY;
    assert data(data'low)'length = 1 report "f_bitstuff_dec: data must be 1bit" severity C_SEVERITY;
    assert run_length > 1 report "f_bitstuff_dec: run_length must be > 1" severity C_SEVERITY;

    for i in data'low to data'high loop
      if data(i)(0) = run_type then
        v_cnt := v_cnt + 1;
      else
        v_cnt := 0;
      end if;
      if not v_skip then
        if v_cnt < run_length then
          v_data(v_len) := data(i);
          v_len         := v_len + 1;
          v_skip        := false;
        elsif v_cnt = run_length then
          v_data(v_len) := data(i);
          v_len         := v_len + 1;
          v_skip        := true;
          v_cnt         := 0;
        end if;
      else
        v_cnt  := 0;
        v_skip := false;
      end if;
    end loop;
    if get_length then
      v_length(0) := std_logic_vector(to_unsigned(v_len, 31));
      return v_length;
    else
      return v_data(0 to v_len - 1);
    end if;
  end function f_bitstuff_dec;

  -------------------------------------------------------------------------------
  --! \brief Decode data
  --! \param data       Data array (1bit)
  --! \param run_length Maximum run length before stuff bit is inserted
  --! \param run_type   Run-length value (default '1')
  --! \return           Decoded data
  --!
  --! Decode bit-stuffed data. Remove bits inserted by the encoding process.
  --!
  --! **Example use**
  --! ~~~
  --! decoded_data := f_bitstuff_dec(data_1bit, 5);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_bitstuff_dec(data       : t_slv_arr;
                          run_length : positive;
                          run_type   : std_logic := '1')
    return t_slv_arr is
  begin
    return f_bitstuff_dec(data, run_length, run_type, false);
  end function f_bitstuff_dec;

  -------------------------------------------------------------------------------
  --! \brief Get decoded data length
  --! \param data       Data array (1bit)
  --! \param run_length Maximum run length before stuff bit is inserted
  --! \param run_type   Run-length value (default '1')
  --! \return           Decoded data length
  --!
  --! Get length of decoded data after bit stuffing is removed.
  --!
  --! **Example use**
  --! ~~~
  --! v_len := f_bitstuff_dec_len(data_1bit, 5);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_bitstuff_dec_len(data       : t_slv_arr;
                              run_length : positive;
                              run_type   : std_logic := '1')
    return natural is
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    v_length := f_bitstuff_dec(data, run_length, run_type, true);
    return to_integer(unsigned(v_length(0)));
  end function f_bitstuff_dec_len;


end package body nw_bitstuff_pkg;
