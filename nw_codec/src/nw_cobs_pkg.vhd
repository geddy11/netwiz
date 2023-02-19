-------------------------------------------------------------------------------
-- Title      : Network Wizard Consistent Overhead Byte Stuffing
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: 
--!\file
--!\brief COBS codec functions
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

--! \page nw_cobs COBS
--! \tableofcontents
--! \section cobs Consistent Overhead Byte Stuffing
--! This library provides functions for the COBS algorithm.  
--!
--! \subsection cobs_subsec1 Functionality
--! \li Perform COBS encoding and decoding of 8bit arrays. 
--!
--! The COBS algorithm replaces all zeros in the data to be encoded. Worst case overhead for large packets is 0.4%.
--!
--! \n More details in \ref nw_cobs_pkg
--! \subsection cobs_subsec2 Example use
--! Include the libraries:
--! ~~~
--! library nw_codec;
--! context nw_codec.nw_codec_context;
--! ~~~
--! The encoding process will replace all zeros in the data to be encoded. 
--! ~~~
--! v_data                    := (x"00", x"00", x"00", x"01", x"80", x"57", x"68", x"00", x"00", x"00"); -- data array to be encoded
--! v_len                     := f_cobs_enc_len(v_data); -- get length of encoded data (v_len is now 11)
--! v_encoded(0 to v_len - 1) := f_cobs_enc(v_data); -- v_encoded is now (x"01", x"01", x"01", x"05", x"01", x"80", x"57", x"68", x"01", x"01", x"01")
--! ~~~
--! Decode the encoded data:
--! ~~~
--! v_dlen                     := f_cobs_dec_len(v_encoded(0 to v_len - 1)); -- get length od decoded data (v_dlen is now 10)
--! v_decoded(0 to v_dlen - 1) := f_cobs_dec(v_encoded(0 to v_len - 1)); -- v_decoded is now equal to v_data
--! ~~~
--! See further examples in the test bench nw_codec_tb.vhd.
package nw_cobs_pkg is

  -------------------------------------------------------------------------------
  -- Functions
  -------------------------------------------------------------------------------
  function f_cobs_enc(data : t_slv_arr) return t_slv_arr;

  function f_cobs_enc_len (data : t_slv_arr) return natural;

  function f_cobs_dec(data : t_slv_arr) return t_slv_arr;

  function f_cobs_dec_len (data : t_slv_arr) return natural;


end package nw_cobs_pkg;

package body nw_cobs_pkg is

  constant C_ZERO : t_slv_arr(0 to 0)(7 downto 0) := (others => x"00");

  -------------------------------------------------------------------------------
  -- Encode data (internal)
  -------------------------------------------------------------------------------
  function f_cobs_enc(data       : t_slv_arr;
                      get_length : boolean := false)
    return t_slv_arr is
    variable v_data   : t_slv_arr(0 to 2 * data'length)(7 downto 0);
    variable v_idx    : natural := 0;
    variable v_hpos   : natural := 0;
    variable v_cnt    : natural := 0;
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    assert data'ascending report "f_cobs_enc: data array must be ascending" severity C_SEVERITY;
    assert data(data'low)'length = 8 report "f_cobs_enc: data must be 8bit" severity C_SEVERITY;

    v_data := (others => x"00");
    v_idx  := 1;

    for i in data'low to data'high loop
      if data(i) = x"00" then
        v_data(v_hpos) := std_logic_vector(to_unsigned(v_cnt + 1, 8));
        v_hpos         := v_hpos + v_cnt + 1;
        v_cnt          := 0;
        if i = data'high then
          v_data(v_idx) := x"01";
        else
          v_data(v_idx) := x"00";
        end if;
        v_idx := v_idx + 1;
      else
        v_data(v_idx) := data(i);
        v_idx         := v_idx + 1;
        v_cnt         := v_cnt + 1;
        if v_cnt = 254 then
          v_data(v_hpos) := std_logic_vector(to_unsigned(v_cnt + 1, 8));
          v_hpos         := v_hpos + v_cnt + 1;
          v_cnt          := 0;
          if i /= data'high then
            v_data(v_idx) := x"00";
            v_idx         := v_idx + 1;
          end if;
        end if;
        if i = data'high and v_hpos < v_idx then
          v_data(v_hpos) := std_logic_vector(to_unsigned(v_cnt + 1, 8));
        end if;
      end if;
    end loop;

    if get_length then
      v_length(0) := std_logic_vector(to_unsigned(v_idx, 31));
      return v_length;
    else
      return v_data(0 to v_idx - 1);
    end if;
  end function f_cobs_enc;

  -------------------------------------------------------------------------------
  --! \brief Encode data
  --! \param data  Data array (8bit)
  --! \return      Encoded data
  --!
  --! Encode data with the COBS algorithm.
  --!
  --! **Example use**
  --! ~~~
  --! encoded_data := f_cobs_enc(data_8bit);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_cobs_enc(data : t_slv_arr)
    return t_slv_arr is
  begin
    return f_cobs_enc(data, false);
  end function f_cobs_enc;

  -------------------------------------------------------------------------------
  --! \brief Get encoded data length
  --! \param data  Data array (8bit)
  --! \return      Encoded data length
  --!
  --! Get length of encoded data after applying COBS.
  --!
  --! **Example use**
  --! ~~~
  --! v_len := f_cobs_enc_len(data_8bit);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_cobs_enc_len(data : t_slv_arr)
    return natural is
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    v_length := f_cobs_enc(data, true);
    return to_integer(unsigned(v_length(0)));
  end function f_cobs_enc_len;

  -------------------------------------------------------------------------------
  -- Decode data (internal)
  -------------------------------------------------------------------------------
  function f_cobs_dec(data       : t_slv_arr;
                      get_length : boolean := false)
    return t_slv_arr is
    variable v_data    : t_slv_arr(0 to data'length)(7 downto 0) := (others => x"00");
    variable v_length  : t_slv_arr(0 to 0)(30 downto 0);
    variable v_idx     : natural                                 := 0;
    variable v_cnt     : natural                                 := 0;
    variable v_header  : boolean                                 := true;
    variable v_addzero : boolean                                 := false;
  begin
    assert data'ascending report "f_cobs_dec: data array must be ascending" severity C_SEVERITY;
    assert data(data'low)'length = 8 report "f_cobs_dec: data must be 8bit" severity C_SEVERITY;

    for i in data'low to data'high loop
      if v_header then
        v_header  := false;
        v_addzero := false;
        if data(i) = x"01" and i < data'high then
          v_data(v_idx) := x"00";
          v_idx         := v_idx + 1;
          v_header      := true;
        else
          v_cnt := to_integer(unsigned(data(i))) - 1;
          if v_cnt < 254 then
            v_addzero := true;
          end if;
        end if;
      else
        v_data(v_idx) := data(i);
        v_idx         := v_idx + 1;
        v_cnt         := v_cnt - 1;
        if v_cnt = 0 then
          v_header := true;
          if v_addzero and i < data'high then
            v_data(v_idx) := x"00";
            v_idx         := v_idx + 1;
          end if;
        end if;
      end if;
    end loop;

    if get_length then
      v_length(0) := std_logic_vector(to_unsigned(v_idx, 31));
      return v_length;
    else
      return v_data(0 to v_idx - 1);
    end if;
  end function f_cobs_dec;

  -------------------------------------------------------------------------------
  --! \brief Decode data
  --! \param data  Data array (8bit)
  --! \return      Decoded data
  --!
  --! Decode data with the COBS algorithm. 
  --!
  --! **Example use**
  --! ~~~
  --! decoded_data := f_cobs_dec(data_8bit);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_cobs_dec(data : t_slv_arr)
    return t_slv_arr is
  begin
    return f_cobs_dec(data, false);
  end function f_cobs_dec;

  -------------------------------------------------------------------------------
  --! \brief Get decoded data length
  --! \param data  Data array (8bit)
  --! \return      Decoded data length
  --!
  --! Get length of decoded data after applying COBS.
  --!
  --! **Example use**
  --! ~~~
  --! v_len := f_cobs_dec_len(data_8bit);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_cobs_dec_len(data : t_slv_arr)
    return natural is
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    v_length := f_cobs_dec(data, true);
    return to_integer(unsigned(v_length(0)));
  end function f_cobs_dec_len;


end package body nw_cobs_pkg;

