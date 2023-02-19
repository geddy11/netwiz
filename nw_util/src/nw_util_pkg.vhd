-------------------------------------------------------------------------------
-- Title      : Network Wizard Utilities package
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: 
--!\file
--!\brief Utilities for data array manipulation.
--
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
use std.textio.all;

library nw_adapt;
use nw_adapt.nw_adaptations_pkg.all;
use work.nw_types_pkg.all;
--! @endcond

--! \page nw_util Utilities library
--! \tableofcontents
--! This library provides functions for data array manipulation.
--! \section util Utilities
--! \subsection util_subsec1 Functionality
--! \li Repack data arrays to new data width, padding before or after
--! \li Flip bits in data words or swap endianess
--! \li Concatenate data array lengthwise or widthwise
--! \li Search for token in data arrays
--!
--! Other libraries in Utilities are: 
--! \li \subpage nw_crc
--! \li \subpage nw_prbs
--! \li \subpage nw_nrs
--!
--! \n More details in \ref nw_util_pkg
--! \subsection util_subsec2 Example use
--! Include the libraries:
--! ~~~
--! library nw_util;
--! context nw_util.nw_util_context;
--! ~~~
--! Bit-flip (reflect) and swap endianness of data arrays and std_logic_vectors:
--! ~~~
--! array_8bit    := (x"c1", x"67");
--! array_flipped := f_bitflip(array_8bit); -- array_flipped is now (x"83", x"e6")
--! v_a           := "1100001111";
--! v_a_flipped   := f_bitflip(v_a); -- v_a_flipped is now "1111000011"
--! array_32bit   := (x"11223344", x"abcdef00);
--! array_swapped := f_swap_endian(array_32bit); -- array_swapped is now (x"44332211",  x"00efcdab")
--! ~~~
--! Concatenate data arrays:
--! ~~~
--! array_8bit   := (x"c1", x"67");
--! array2_8bit  := (x"55", x"8f", x"42);
--! array_concat := f_concat(array_8bit, array2_8bit); -- array_concat is now (x"c1", x"67", x"55", x"8f", x"42)
--! ~~~
--! Repack data arrays to new data word width:
--! ~~~
--! array_8bit  := (x"11", x"22", x"33", x"44", x"55", x"66", x"77");
--! array_32bit := f_repack(array_8bit, 32, C_MSB_FIRST, C_PAD_BEFORE, x"ff"); -- array_32bit is now (x"ff112233", x"44556677")
--! array_32bit := f_repack(array_8bit, 32, C_LSB_FIRST, C_PAD_BEFORE, x"ff"); -- array_32bit is now (x"332211ff", x"77665544")
--! array_1bit  := f_repack(array_8bit(0 to 0), 1, C_MSB_FIRST); -- array_1bit is now ("0", "0", "0", "1", "0", "0", "0", "1")
--! array_3bit  := f_repack(array_1bit, 3, C_LSB_FIRST);         -- array_3bit is now ("000", "001", "010")
--! array_7bit  := f_repack(f_repack(array_8bit, 1), 7); -- array_7bit is now ("0001000", "1001000", "1000110", "0110100", "0100010", ...)
--! ~~~
--! Reverse data arrays:
--! ~~~ 
--! array_8bit := (x"c1", x"67", x"42");
--! array_rev  := f_reverse(array_8bit); -- array_rev is now (x"42", x"67", x"c1")
--! ~~~
--! Stack data arrays to create wider data words:
--! ~~~ 
--! array_8bit  := (x"11", x"22", x"33", x"44", x"55", x"66", x"77");
--! array_4bit  := (x"0", x"1", x"2", x"3");
--! array_12bit := f_stack(array_4bit, array_8bit); -- array_12bit is now (x"011", x"122", x"233", x"344)
--! ~~~ 
--! See further examples in the test bench nw_util_tb.vhd.
package nw_util_pkg is

  -------------------------------------------------------------------------------
  -- Constants
  -- @cond constants
  -------------------------------------------------------------------------------
  constant C_PAD_AFTER  : boolean := true;  --! Put padding at the end
  constant C_PAD_BEFORE : boolean := false;  --! Put padding in front
  constant C_MSB_FIRST  : boolean := true;  --! Extract/insert most significant bits first
  constant C_LSB_FIRST  : boolean := false;  --! Extract/insert least significant bits first

  -------------------------------------------------------------------------------
  -- Functions
  --! @cond functions
  -------------------------------------------------------------------------------
  function f_bitflip(data : t_slv_arr) return t_slv_arr;
  function f_bitflip(data : std_logic_vector) return std_logic_vector;

  function f_concat(data1 : t_slv_arr;
                    data2 : t_slv_arr) return t_slv_arr;

  function f_repack(data      : t_slv_arr;
                    new_width : natural;
                    msb_first : boolean;
                    pad_after : boolean;
                    pad_value : std_logic_vector) return t_slv_arr;

  function f_repack(data      : t_slv_arr;
                    new_width : natural;
                    msb_first : boolean := C_MSB_FIRST) return t_slv_arr;

  function f_repack_len(data      : t_slv_arr;
                        new_width : natural;
                        msb_first : boolean := C_MSB_FIRST) return natural;

  function f_reverse(data : t_slv_arr) return t_slv_arr;

  function f_search(data  : t_slv_arr;
                    token : t_slv_arr) return integer;

  function f_stack(data_high : t_slv_arr;
                   data_low  : t_slv_arr) return t_slv_arr;

  function f_swap_endian(data : t_slv_arr) return t_slv_arr;
  function f_swap_endian(data : std_logic_vector) return std_logic_vector;

  function f_to_unsigned_arr(data : t_slv_arr) return t_unsigned_arr;
  function f_to_slv_arr(data      : t_unsigned_arr) return t_slv_arr;


  function f_str_2_slv(value    : string) return std_logic_vector;
  function f_str_2_slv_arr(str  : string) return t_slv_arr;
  function f_slv_arr_2_str(data : t_slv_arr) return string;
  --! @endcond

  -------------------------------------------------------------------------------
  -- Procedures
  --! @cond procedures
  -------------------------------------------------------------------------------
  procedure msg (
    constant msg_txt : in string);      -- message to be printed
  --! @endcond

end package nw_util_pkg;

package body nw_util_pkg is

  -------------------------------------------------------------------------------
  --! \brief Reverse bit order in each data word
  --! \param data   Input data array 
  --! \return       Bit-flipped data array
  --!
  --! **Example use**
  --! ~~~
  --! array_8bit    := (x"c1", x"67");
  --! array_flipped := f_bitflip(array_8bit); -- array_flipped is now (x"83", x"e6")
  --! ~~~
  -------------------------------------------------------------------------------
  function f_bitflip(data : t_slv_arr)
    return t_slv_arr is

    variable v_data_size : natural := data(data'low)'length;
    variable v_data      : t_slv_arr(0 to data'length - 1)(v_data_size - 1 downto 0);
    variable v_tmp       : std_logic_vector(v_data_size - 1 downto 0);
  begin
    assert data'ascending report "f_bitflip: input data array must be ascending" severity C_SEVERITY;
    assert data(data'low)'ascending = false report "f_bitflip: input data words must be descending" severity C_SEVERITY;

    for i in data'low to data'high loop
      v_tmp := data(i);
      for j in v_data(0)'range loop
        v_data(i - data'low)(j) := v_tmp(v_data(0)'left - j);
      end loop;
    end loop;
    return v_data;
  end function f_bitflip;

  -------------------------------------------------------------------------------
  --! \brief Reverse bit order in data word
  --! \param data   Input data 
  --! \return       Bit-flipped data 
  --!
  --! **Example use**
  --! ~~~
  --! v_a         := "1100001111";
  --! v_a_flipped := f_bitflip(v_a); -- v_a_flipped is now "1111000011"
  --! ~~~
  -------------------------------------------------------------------------------
  function f_bitflip(data : std_logic_vector)
    return std_logic_vector is

    variable v_data : std_logic_vector(data'length - 1 downto 0);
    variable v_tmp  : std_logic_vector(data'length - 1 downto 0);
  begin
    assert data'ascending = false report "f_bitflip: input data word must be descending" severity C_SEVERITY;

    for j in data'range loop
      v_tmp(data'high - j) := data(j);
    end loop;

    return v_tmp;
  end function f_bitflip;

  -------------------------------------------------------------------------------
  --! \brief Concatenate two arrays (of same data width)
  --! \param data1  First data array 
  --! \param data2  Second data array 
  --! \return       Concatenated data array
  --!
  --! **Example use**
  --! ~~~
  --! array_8bit   := (x"c1", x"67");
  --! array2_8bit  := (x"55", x"8f", x"42);
  --! array_concat := f_concat(array_8bit, array2_8bit); -- array_concat is now (x"c1", x"67", x"55", x"8f", x"42)
  --! ~~~
  -------------------------------------------------------------------------------
  function f_concat(data1 : t_slv_arr;
                    data2 : t_slv_arr) return t_slv_arr is
    variable v_data_size : natural := data1(data1'low)'length;
    variable v_data      : t_slv_arr(0 to data1'length + data2'length - 1)(v_data_size - 1 downto 0);
  begin
    assert data1(data1'low)'length = data1(data1'low)'length report "f_concat: data word sizes must be equal" severity C_SEVERITY;

    v_data(0 to data1'length - 1)                           := data1(data1'low to data1'high);
    v_data(data1'length to data1'length + data2'length - 1) := data2(data2'low to data2'high);
    return v_data;
  end function f_concat;


  -------------------------------------------------------------------------------
  -- Repack array to new word size (internal)
  -------------------------------------------------------------------------------
  function f_repack(data       : t_slv_arr;
                    new_width  : natural;
                    msb_first  : boolean;
                    pad_after  : boolean;
                    pad_value  : std_logic_vector;
                    get_length : boolean := false)
    return t_slv_arr is

    variable v_data_size   : natural := data(data'low)'length;
    variable v_pack_factor : natural := new_width / v_data_size;
    variable v_data        : t_slv_arr(0 to data'length * v_data_size / new_width)(new_width - 1 downto 0);
    variable v_tmp         : std_logic_vector(new_width - 1 downto 0);
    variable v_old         : std_logic_vector(v_data_size - 1 downto 0);
    variable v_idx         : natural := 0;
    variable v_didx        : natural := 0;
    variable v_pad         : std_logic_vector(v_data_size - 1 downto 0);
    variable v_pad_words   : natural;
    variable v_length      : t_slv_arr(0 to 0)(30 downto 0);
  begin
    assert data'ascending report "f_repack: input data array must be ascending" severity C_SEVERITY;
    assert data(data'low)'ascending = false report "f_repack: input data words must be descending" severity C_SEVERITY;

    if v_data_size = new_width then  -- no change, just realign to zero indexed
      for i in data'low to data'high loop
        v_tmp                := data(i);
        v_data(i - data'low) := v_tmp;
      end loop;
      v_didx := data'length;

    elsif v_data_size > new_width then  -- downsizing, no padding required
      v_pack_factor := v_data_size / new_width;
      assert v_pack_factor * new_width = v_data_size report "f_repack: data width must be integer factor of new_width" severity C_SEVERITY;

      for i in data'low to data'high loop
        v_old := data(i);
        if msb_first then
          for j in v_pack_factor - 1 downto 0 loop
            v_data(v_idx) := v_old((j + 1) * new_width - 1 downto j * new_width);
            v_idx         := v_idx + 1;
          end loop;
        else
          for j in 0 to v_pack_factor - 1 loop
            v_data(v_idx) := v_old((j + 1) * new_width - 1 downto j * new_width);
            v_idx         := v_idx + 1;
          end loop;
        end if;
      end loop;
      v_didx := v_pack_factor * data'length;

    else                                -- upsizing, padding might be required
      v_pack_factor := new_width / v_data_size;
      assert v_pack_factor * v_data_size = new_width report "f_repack: new_width must be integer factor of data width" severity C_SEVERITY;
      assert v_pad'left = v_data_size - 1 and v_pad'right = 0
        report "f_repack: pad_value must be same word size as input data" severity C_SEVERITY;

      -- calculate how many words need to be padded
      v_pad := pad_value;
      if (v_data_size * data'length) mod new_width = 0 then
        v_pad_words := 0;
      else
        v_pad_words := (new_width - (v_data_size * data'length) mod new_width) / v_data_size;
      end if;
      -- pad before
      if v_pad_words > 0 and pad_after = false then
        if msb_first then
          for j in 0 to v_pad_words - 1 loop
            v_tmp((v_pack_factor - j) * v_data_size - 1 downto (v_pack_factor - j - 1) * v_data_size) := v_pad;
          end loop;
          for j in v_pad_words to v_pack_factor - 1 loop
            v_tmp((v_pack_factor - j) * v_data_size - 1 downto (v_pack_factor - j - 1) * v_data_size) := data(data'low + v_idx);
            v_idx                                                                                     := v_idx + 1;
          end loop;
        else
          for j in v_pack_factor - v_pad_words - 1 downto 0 loop
            v_tmp((v_pack_factor - j) * v_data_size - 1 downto (v_pack_factor - j - 1) * v_data_size) := data(data'low + v_idx);
            v_idx                                                                                     := v_idx + 1;
          end loop;
          for j in v_pack_factor - v_pad_words to v_pack_factor - 1 loop
            v_tmp((v_pack_factor - j) * v_data_size - 1 downto (v_pack_factor - j - 1) * v_data_size) := v_pad;
          end loop;
        end if;
        v_data(0) := v_tmp;
        v_didx    := 1;
      end if;
      -- pack data
      if data'length >= v_pack_factor then
        for i in 0 to data'length / v_pack_factor - 1 loop
          if msb_first then
            for j in 0 to v_pack_factor - 1 loop
              v_data(v_didx)((v_pack_factor - j) * v_data_size - 1 downto (v_pack_factor - j - 1) * v_data_size) := data(data'low + v_idx);
              v_idx                                                                                              := v_idx + 1;
            end loop;
          else
            for j in v_pack_factor - 1 downto 0 loop
              v_data(v_didx)((v_pack_factor - j) * v_data_size - 1 downto (v_pack_factor - j - 1) * v_data_size) := data(data'low + v_idx);
              v_idx                                                                                              := v_idx + 1;
            end loop;
          end if;
          v_didx := v_didx + 1;
        end loop;
      end if;
      -- pad after
      if v_pad_words > 0 and pad_after = true then
        if msb_first then
          for j in 0 to v_pack_factor - v_pad_words - 1 loop
            v_tmp((v_pack_factor - j) * v_data_size - 1 downto (v_pack_factor - j - 1) * v_data_size) := data(data'low + v_idx);
            v_idx                                                                                     := v_idx + 1;
          end loop;
          for j in v_pack_factor - v_pad_words to v_pack_factor - 1 loop
            v_tmp((v_pack_factor - j) * v_data_size - 1 downto (v_pack_factor - j - 1) * v_data_size) := v_pad;
          end loop;
        else
          for j in 0 to v_pad_words - 1 loop
            v_tmp((v_pack_factor - j) * v_data_size - 1 downto (v_pack_factor - j - 1) * v_data_size) := v_pad;
          end loop;
          for j in v_pack_factor - 1 downto v_pad_words loop
            v_tmp((v_pack_factor - j) * v_data_size - 1 downto (v_pack_factor - j - 1) * v_data_size) := data(data'low + v_idx);
            v_idx                                                                                     := v_idx + 1;
          end loop;
        end if;
        v_data(v_didx) := v_tmp;
        v_didx         := v_didx + 1;
      end if;
    end if;
    if get_length then
      v_length(0) := std_logic_vector(to_unsigned(v_didx, 31));
      return v_length;
    else
      return v_data(0 to v_didx - 1);
    end if;
  end function f_repack;

  -------------------------------------------------------------------------------
  --! \brief Repack array to new word size
  --! \param data       Input data array 
  --! \param new_width  Target data width
  --! \param msb_first  Insert/extract most significant bits first if True, least significant bits if False
  --! \param pad_after  Put padding after if True, before if False
  --! \param pad_value  Value to pad with (same word size as data)
  --! \return           Repacked data array
  --!
  --! Array will be repacked to wider or narrower data words. The only limit is that there must be an integer relationship between
  --! the input data word size and the new data width. This limit is circumvented by first repacking to 1bit, then to target width. 
  --! When increasing the data width, padding will be added before or after as required with a user-defined pad word. 
  --!
  --! **Example use**
  --! ~~~
  --! array_8bit  := (x"11", x"22", x"33", x"44", x"55", x"66", x"77");
  --! array_32bit := f_repack(array_8bit, 32, C_MSB_FIRST, C_PAD_BEFORE, x"ff"); -- array_32bit is now (x"ff112233", x"44556677")
  --! array_32bit := f_repack(array_8bit, 32, C_LSB_FIRST, C_PAD_BEFORE, x"ff"); -- array_32bit is now (x"332211ff", x"77665544")
  --! array_1bit  := f_repack(array_8bit(0 to 0), 1, C_MSB_FIRST); -- array_1bit is now ("0", "0", "0", "1", "0", "0", "0", "1")
  --! array_3bit  := f_repack(array_1bit, 3, C_LSB_FIRST);         -- array_3bit is now ("000", "001", "010")
  --! array_7bit  := f_repack(f_repack(array_8bit, 1), 7); -- array_7bit is now ("0001000", "1001000", "1000110", "0110100", "0100010", ...)
  --! ~~~
  -------------------------------------------------------------------------------
  function f_repack(data      : t_slv_arr;
                    new_width : natural;
                    msb_first : boolean;
                    pad_after : boolean;
                    pad_value : std_logic_vector)
    return t_slv_arr is
  begin
    return f_repack(data, new_width, msb_first, pad_after, pad_value, false);
  end function f_repack;

  -------------------------------------------------------------------------------
  --! \param data      Input data array 
  --! \param new_width Target data width
  --! \param msb_first Insert/extract most significant bits first if True (default), least significant bits if False
  --! \return          Repacked data array
  --!
  --! This is an overload of f_repack with the following parameters set:\n
  --!<pre>
  --! pad_after: True
  --! pad_value: (others => '0')
  --!</pre>
  --! **Example use**
  --! ~~~
  --! array_8bit   := (x"11", x"22", x"33", x"44", x"55", x"66", x"77");
  --! array_24bit  := f_repack(array_8bit, 24, C_MSB_FIRST);  -- array_24bit is now (x"112233", x"445566", x"770000")
  --! array_24bit  := f_repack(array_8bit, 24, C_LSB_FIRST);  -- array_24bit is now (x"332211", x"665544", x"000077")
  --! array_128bit := f_repack(array_8bit, 128, C_MSB_FIRST); -- array_128bit is now (x"11223344556677000000000000000000")
  --! array_128bit := f_repack(array_8bit, 128, C_LSB_FIRST); -- array_128bit is now (x"00000000000000000077665544332211")
  --! ~~~
  -------------------------------------------------------------------------------
  function f_repack(data      : t_slv_arr;
                    new_width : natural;
                    msb_first : boolean := C_MSB_FIRST)
    return t_slv_arr is
    variable v_pad_value : std_logic_vector(data(data'low)'length - 1 downto 0) := (others => '0');

  begin
    return f_repack(data, new_width, msb_first, C_PAD_AFTER, v_pad_value, false);
  end function f_repack;

  -------------------------------------------------------------------------------
  --! \brief Return length of repacked array.
  --! \param data      Input data array 
  --! \param new_width Target data width
  --! \return          Length of repacked data array
  --!
  --! Return the length of the array when repacked to new_width.
  --!
  --! **Example use**
  --! ~~~
  --! array_8bit := (x"11", x"22", x"33", x"44", x"55", x"66", x"77");
  --! v_len      := f_repack_len(array_8bit,  2); -- v_len is now 28
  --! ~~~
  -------------------------------------------------------------------------------
  function f_repack_len(data      : t_slv_arr;
                        new_width : natural;
                        msb_first : boolean := C_MSB_FIRST)
    return natural is
    variable v_pad_value : std_logic_vector(data(data'low)'length - 1 downto 0) := (others => '0');
    variable v_length    : t_slv_arr(0 to 0)(30 downto 0);
  begin
    v_length := f_repack(data, new_width, msb_first, C_PAD_AFTER, v_pad_value, true);
    return to_integer(unsigned(v_length(0)));
  end function f_repack_len;

  -------------------------------------------------------------------------------
  --! \brief Reverse data array
  --! \param data   Input data array 
  --! \return       Reversed data array
  --!
  --! **Example use**
  --! ~~~
  --! array_8bit := (x"c1", x"67", x"42");
  --! array_rev  := f_reverse(array_8bit); -- array_rev is now (x"42", x"67", x"c1")
  --! ~~~
  -------------------------------------------------------------------------------
  function f_reverse(data : t_slv_arr)
    return t_slv_arr is

    variable v_data_size : natural := data(data'low)'length;
    variable v_data      : t_slv_arr(0 to data'length - 1)(v_data_size - 1 downto 0);
    variable v_idx       : natural := 0;
  begin

    for i in data'high to data'low loop
      v_data(v_idx) := data(i);
      v_idx         := v_idx + 1;
    end loop;
    return v_data;
  end function f_reverse;

  -------------------------------------------------------------------------------
  --! \brief Find sub-array in data array
  --! \param data      Input data array 
  --! \param token     Sub-array to search for
  --! \return          Index of first occurence, -1 if not found
  --!
  --! Search for a token in a data array. The token and data array must have the same data width. If the token is not found, -1 is returned.
  --!
  --! **Example use**
  --! ~~~
  --! array_8bit := (x"11", x"22", x"33", x"44", x"55", x"66", x"77");
  --! token      := (x"55", x"66");
  --! v_res      := f_search(array_8bit,  token); -- v_res is now 4
  --! token      := (x"55", x"77");
  --! v_res      := f_search(array_8bit,  token); -- v_res is now -1
  --! ~~~
  -------------------------------------------------------------------------------
  function f_search(data  : t_slv_arr;
                    token : t_slv_arr)
    return integer is

  begin
    assert data(data'low)'length = token(token'low)'length report "f_search: the token and data array must have the same data width" severity C_SEVERITY;
    assert data'length >= token'length report "f_search: the token length must be <= data array length" severity C_SEVERITY;

    for i in data'low to data'high - token'length + 1 loop
      if data(i to i + token'length - 1) = token then
        return i;
      end if;
    end loop;
    return -1;
  end function f_search;

  -------------------------------------------------------------------------------
  --! \brief Stack data words from two arrays
  --! \param data_high Input MSB data array 
  --! \param data_low  Input LSB data array 
  --! \return          Stacked arrays
  --!
  --! Stack two data arrays, word by word. If one array is longer than the other, it will be cropped to match the length of the shorter one.
  --!
  --! **Example use**
  --! ~~~
  --! array_8bit  := (x"11", x"22", x"33", x"44", x"55", x"66", x"77");
  --! array_4bit  := (x"0", x"1", x"2", x"3");
  --! array_12bit := f_stack(array_4bit, array_8bit); -- array_12bit is now (x"011", x"122", x"233", x"344)
  --! ~~~
  -------------------------------------------------------------------------------
  function f_stack(data_high : t_slv_arr;
                   data_low  : t_slv_arr)
    return t_slv_arr is
    variable v_len   : natural := minimum(data_high'length, data_low'length);
    variable v_width : natural := data_high(data_high'low)'length + data_low(data_low'low)'length;
    variable v_data  : t_slv_arr(0 to v_len - 1)(v_width - 1 downto 0);
  begin
    for i in 0 to v_len - 1 loop
      v_data(i) := data_high(i) & data_low(i);
    end loop;
    return v_data;
  end function f_stack;

  -------------------------------------------------------------------------------
  --! \brief Swap endianness of array
  --! \param data   Input data array 
  --! \return       Byteswapped data array
  --!
  --! This function will swap endianness of each dataword in the array. The width 
  --! of the input data must be an integer factor of 8. 
  --!
  --! **Example use**
  --! ~~~
  --! array_32bit   := (x"11223344", x"abcdef00);
  --! array_swapped := f_swap_endian(array_32bit); -- array_swapped is now (x"44332211",  x"00efcdab")
  --! ~~~
  -------------------------------------------------------------------------------
  function f_swap_endian(data : t_slv_arr)
    return t_slv_arr is

    variable v_data_size : natural := data(data'low)'length;
    variable v_bytes     : natural := v_data_size / 8;
    variable v_data      : t_slv_arr(0 to data'length - 1)(v_data_size - 1 downto 0);
    variable v_tmp       : std_logic_vector(v_data_size - 1 downto 0);
  begin
    assert v_data_size mod 8 = 0 report "f_swap_endian: input data array word width must be integer factor of 8" severity C_SEVERITY;
    assert data'ascending report "f_swap_endian: input data array must be ascending" severity C_SEVERITY;
    assert data(data'low)'ascending = false report "f_swap_endian: input data words must be descending" severity C_SEVERITY;

    for i in data'low to data'high loop
      v_tmp := data(i);
      for b in 0 to v_bytes - 1 loop
        v_data(i - data'low)((b + 1) * 8 - 1 downto b * 8) := v_tmp((v_bytes - b) * 8 - 1 downto (v_bytes - b - 1) * 8);
      end loop;
    end loop;
    return v_data;
  end function f_swap_endian;

  -------------------------------------------------------------------------------
  --! \brief Swap endianness of vector
  --! \param data   Input data vector
  --! \return       Byteswapped data vector
  --!
  --! This function will swap endianness of the dataword. The width 
  --! of the input data word must be an integer factor of 8. 
  --!
  --! **Example use**
  --! ~~~
  --! v_32bit   := x"11223344";
  --! v_swapped := f_swap_endian(v_32bit); -- v_swapped is now x"44332211"
  --! ~~~
  -------------------------------------------------------------------------------
  function f_swap_endian(data : std_logic_vector)
    return std_logic_vector is

    variable v_data_size : natural := data'length;
    variable v_bytes     : natural := v_data_size / 8;
    variable v_data      : std_logic_vector(v_data_size - 1 downto 0);
    variable v_tmp       : std_logic_vector(v_data_size - 1 downto 0);
  begin
    assert v_data_size mod 8 = 0 report "f_swap_endian: input data word width must be integer factor of 8" severity C_SEVERITY;
    assert data'ascending = false report "f_swap_endian: input data word must be descending" severity C_SEVERITY;

    v_tmp := data;
    for b in 0 to v_bytes - 1 loop
      v_data((b + 1) * 8 - 1 downto b * 8) := v_tmp((v_bytes - b) * 8 - 1 downto (v_bytes - b - 1) * 8);
    end loop;

    return v_data;
  end function f_swap_endian;

  -------------------------------------------------------------------------------
  --! \brief Convert hex string to slv
  --! \param value  Hex number in string format
  --! \return       Value as std_logic_vector
  --!
  --! This function converts a hex number in string format to slv. 
  --!
  --! **Example use**
  --! ~~~
  --! v_number   := f_str_2_slv("a50"); -- v_number is now "101001010000"
  --! ~~~
  -------------------------------------------------------------------------------
  function f_str_2_slv(value : string)
    return std_logic_vector is
    variable v_val   : std_logic_vector(value'length * 4 - 1 downto 0);
    variable v_digit : std_logic_vector(3 downto 0);
  begin
    for i in 0 to value'length - 1 loop
      case value(value'left + i) is
        when '0'       => v_digit := x"0";
        when '1'       => v_digit := x"1";
        when '2'       => v_digit := x"2";
        when '3'       => v_digit := x"3";
        when '4'       => v_digit := x"4";
        when '5'       => v_digit := x"5";
        when '6'       => v_digit := x"6";
        when '7'       => v_digit := x"7";
        when '8'       => v_digit := x"8";
        when '9'       => v_digit := x"9";
        when 'A' | 'a' => v_digit := x"a";
        when 'B' | 'b' => v_digit := x"b";
        when 'C' | 'c' => v_digit := x"c";
        when 'D' | 'd' => v_digit := x"d";
        when 'E' | 'e' => v_digit := x"e";
        when 'F' | 'f' => v_digit := x"f";
        when others =>
          assert false report "f_str_2_slv: string characters must be 0-9 or a-f" severity C_SEVERITY;
      end case;
      v_val((value'length - i) * 4 - 1 downto (value'length - i - 1) * 4) := v_digit;
    end loop;
    return v_val;
  end function f_str_2_slv;

  -------------------------------------------------------------------------------
  --! \brief Convert slv array to unsigned array
  --! \param data   slv array
  --! \return       unsigned array
  --!
  --! This function converts each word in the data array from std_logic_vector to unsigned type.
  --!
  --! **Example use**
  --! ~~~
  --! v_udata := f_to_unsigned_arr(v_data);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_to_unsigned_arr(data : t_slv_arr)
    return t_unsigned_arr is
    variable v_ret : t_unsigned_arr(0 to data'length - 1)(data(data'low)'length - 1 downto 0);
  begin
    assert data'ascending report "f_to_unsigned_arr: input data array must be ascending" severity C_SEVERITY;
    assert data(data'low)'ascending = false report "f_to_unsigned_arr: input data words must be descending" severity C_SEVERITY;

    for i in 0 to data'length - 1 loop
      v_ret(i) := unsigned(data(data'left + i));
    end loop;
    return v_ret;
  end function f_to_unsigned_arr;

  -------------------------------------------------------------------------------
  --! \brief Convert unsigned array to slv array
  --! \param data   unsigned array
  --! \return       slv array
  --!
  --! This function converts each word in the data array from unsigned to std_logic_vector type.
  --!
  --! **Example use**
  --! ~~~
  --! v_data := f_to_slv_arr(v_udata);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_to_slv_arr(data : t_unsigned_arr)
    return t_slv_arr is
    variable v_ret : t_slv_arr(0 to data'length - 1)(data(data'low)'length - 1 downto 0);
  begin
    assert data'ascending report "f_to_slv_arr: input data array must be ascending" severity C_SEVERITY;
    assert data(data'low)'ascending = false report "f_to_slv_arr: input data words must be descending" severity C_SEVERITY;

    for i in 0 to data'length - 1 loop
      v_ret(i) := std_logic_vector(data(data'left + i));
    end loop;
    return v_ret;
  end function f_to_slv_arr;

  -------------------------------------------------------------------------------
  --! \brief Convert string to slv array
  --! \param str    String
  --! \return       String as slv array
  --!
  --! This function converts a string to array of std_logic_vector(7 downto 0). 
  --!
  --! **Example use**
  --! ~~~
  --! v_array(0 to 5) := f_str_2_slv_arr("NetWiz"); -- v_array is now (x"4e", x"65", x"74", x"57", x"76", x"7a")
  --! ~~~
  -------------------------------------------------------------------------------
  function f_str_2_slv_arr(str : string)
    return t_slv_arr is
    variable v_data : t_slv_arr(0 to str'length - 1)(7 downto 0);
  begin
    for i in 1 to str'length loop
      v_data(i - 1) := std_logic_vector(to_unsigned(character'pos(str(i)), 8));
    end loop;
    return v_data;
  end function f_str_2_slv_arr;

  -------------------------------------------------------------------------------
  --! \brief Convert slv array to string
  --! \param data   8bit data array
  --! \return       Data as string
  --!
  --! This function converts an 8bit slv array to string. 
  --!
  --! **Example use**
  --! ~~~
  --! v_array := (x"4e", x"65", x"74", x"57", x"76", x"7a");
  --! v_str   := f_slv_arr_2_str(v_array); -- v_str is now "NetWiz"
  --! ~~~
  -------------------------------------------------------------------------------
  function f_slv_arr_2_str(data : t_slv_arr)
    return string is
    variable v_str : string(1 to data'length);
  begin
    for i in 0 to data'length - 1 loop
      v_str(i + 1) := character'val(to_integer(unsigned(data(data'low + i))));
    end loop;
    return v_str;
  end function f_slv_arr_2_str;

  -----------------------------------------------------------------------------
  --! \brief Print message in simulation log
  --! \param msg   Message to print 
  --!
  --! The input string is printed with a timestamp. 
  --!
  --! **Example use**
  --! ~~~
  --! msg("Hello world");
  --! ~~~
  -----------------------------------------------------------------------------
  procedure msg (
    constant msg_txt : in string) is
    variable txt : line;
  begin
    write(txt, string'("@"));
    write(txt, now, right, C_TIME_WIDTH);
    write(txt, string'(" -- ") & msg_txt);
    writeline(OUTPUT, txt);
  end;

end package body nw_util_pkg;
