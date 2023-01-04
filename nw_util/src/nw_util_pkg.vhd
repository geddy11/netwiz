-------------------------------------------------------------------------------
-- Title      : Network Wizard Utilities package
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: 
--!\file
--!\brief Utilities for bitflipping, endianness and repacking arrays to others data widths.
--
-------------------------------------------------------------------------------
-- MIT License
--
-- Copyright (c) 2023 Geir Drange and contributors
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
--! @endcond

package nw_util_pkg is

  -------------------------------------------------------------------------------
  -- Types
  -------------------------------------------------------------------------------
  type t_slv_arr is array (natural range <>) of std_logic_vector; --! Array of std_logic_vector is the primary data type

  -------------------------------------------------------------------------------
  -- Constants
  -------------------------------------------------------------------------------
  constant C_PAD_AFTER     : boolean := True; --! Put padding at the end
  constant C_PAD_BEFORE    : boolean := False; --! Put padding in front
  constant C_MSB_FIRST     : boolean := True;  --! Extract/insert most significant bits first
  constant C_LSB_FIRST     : boolean := False; --! Extract/insert least significant bits first

  -------------------------------------------------------------------------------
  -- 
  -------------------------------------------------------------------------------
  function f_bitflip(data: t_slv_arr) return t_slv_arr;

  function f_repack(data: t_slv_arr; 
                    new_width:  natural;
                    msb_first: boolean;
                    pad_after: boolean;
                    pad_value: std_logic_vector) return t_slv_arr;

  function f_repack(data: t_slv_arr; 
                    new_width:  natural;
                    msb_first: boolean) return t_slv_arr;


  function f_swap_endian(data: t_slv_arr) return t_slv_arr;

end package nw_util_pkg;

package body nw_util_pkg is

  -------------------------------------------------------------------------------
  --! \brief Reverse bits in each data word
  --! \param data   Input data array 
  --! \return       Bit-flipped data array
  --!
  --! **Example use**
  --! ~~~
  --! array_8bit    := (x"c1", x"67");
  --! array_flipped := f_bitflip(array_8bit); -- array_flipped is now (x"83", x"e6")
  --! ~~~
  -------------------------------------------------------------------------------
  function f_bitflip(data: t_slv_arr)  
    return t_slv_arr is

    variable v_data_size : natural := data(data'low)'length;
    variable v_data: t_slv_arr(0 to data'length - 1)(v_data_size - 1 downto 0);
    variable v_tmp : std_logic_vector(v_data_size - 1 downto 0);
  begin
    assert data'ascending report "f_bitflip: input data array must be ascending" severity C_SEVERITY;
    assert data(data'low)'ascending = False report "f_bitflip: input data words must be descending" severity C_SEVERITY;

    for i in data'low to data'high loop
      v_tmp := data(i);
      for j in v_data(0)'range loop
        v_data(i - data'low)(j) := v_tmp(v_data(0)'left - j);
      end loop;
    end loop;
    return v_data;
  end function f_bitflip;

  -------------------------------------------------------------------------------
  --! \brief Repack array to new word size
  --! \param data      Input data array 
  --! \param new_width Target data width
  --! \param msb_first Insert/extract most significant bits first if True, least significant bits if False
  --! \param pad_after Put padding after if True, before if False
  --! \param pad_value Value to pad with (same word size as data)
  --! \return          Repacked data array
  --!
  --! Array will be repacked to wider or narrower data words. The only limit is that there must be an integer relationship between
  --! the input data word size and the new data width. When increasing the data width, padding will be added before or after as required
  --! with a user-defined pad word.
  --!
  --! **Example use**
  --! ~~~
  --! array_8bit  := (x"11", x"22", x"33", x"44", x"55", x"66", x"77");
  --! array_32bit := f_repack(array_8bit, 32, C_MSB_FIRST, C_PAD_BEFORE, x"ff"); -- array_32bit is now (x"ff112233", x"44556677")
  --! array_32bit := f_repack(array_8bit, 32, C_LSB_FIRST, C_PAD_BEFORE, x"ff"); -- array_32bit is now (x"332211ff", x"77665544")
  --! array_1bit  := f_repack(array_8bit(0 to 0), 1, C_MSB_FIRST); -- array_1bit is now ("0", "0", "0", "1", "0", "0", "0", "1")
  --! array_3bit  := f_repack(array_1bit, 3, C_LSB_FIRST);         -- array_3bit is now ("000", "001", "010")
  --! ~~~
  -------------------------------------------------------------------------------
  function f_repack(data: t_slv_arr; 
                    new_width:  natural;
                    msb_first: boolean;
                    pad_after: boolean;
                    pad_value: std_logic_vector) 
    return t_slv_arr is

    variable v_data_size : natural := data(data'low)'length;
    variable v_pack_factor: natural := new_width / v_data_size;
    variable v_data: t_slv_arr(0 to data'length * v_data_size / new_width)(new_width - 1 downto 0);
    variable v_tmp: std_logic_vector(new_width - 1 downto 0);
    variable v_old: std_logic_vector(v_data_size - 1 downto 0);
    variable v_idx : natural := 0;
    variable v_didx: natural := 0;
    variable v_pad : std_logic_vector(v_data_size - 1 downto 0);
    variable v_pad_words : natural;
  begin
    assert data'ascending report "f_repack: input data array must be ascending" severity C_SEVERITY;
    assert data(data'low)'ascending = False report "f_repack: input data words must be descending" severity C_SEVERITY;
    
    if v_data_size = new_width then -- no change, just realign to zero indexed
      for i in data'low to data'high loop
        v_tmp := data(i);
        v_data(i - data'low) := v_tmp;
      end loop;
      v_didx := data'length;
      
    elsif v_data_size > new_width then -- downsizing, no padding required
      v_pack_factor := v_data_size / new_width;
      assert v_pack_factor * new_width = v_data_size report "f_repack: data width must be integer factor of new_width" severity C_SEVERITY;

      for i in data'low to data'high loop
        v_old := data(i);
        if msb_first then
          for j in v_pack_factor - 1 downto 0 loop
            v_data(v_idx) := v_old((j + 1) * new_width - 1 downto j * new_width);
            v_idx := v_idx + 1;
          end loop;
        else
          for j in 0 to v_pack_factor - 1 loop
            v_data(v_idx) := v_old((j + 1) * new_width - 1 downto j * new_width);
            v_idx := v_idx + 1;
          end loop;
        end if;
      end loop;
      v_didx := v_pack_factor * data'length;

    else -- upsizing, padding might be required
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
      if v_pad_words > 0 and pad_after = False then
        if msb_first then
          for j in 0 to v_pad_words - 1 loop
            v_tmp((v_pack_factor - j) * v_data_size - 1 downto (v_pack_factor - j - 1) * v_data_size) := v_pad;
          end loop;
          for j in v_pad_words to v_pack_factor - 1 loop
            v_tmp((v_pack_factor - j) * v_data_size - 1 downto (v_pack_factor - j - 1) * v_data_size) := data(data'low + v_idx);
            v_idx := v_idx + 1;
          end loop;
        else
          for j in v_pack_factor - v_pad_words - 1 downto 0 loop
            v_tmp((v_pack_factor - j) * v_data_size - 1 downto (v_pack_factor - j - 1) * v_data_size) := data(data'low + v_idx);
            v_idx := v_idx + 1;
          end loop;
          for j in v_pack_factor - v_pad_words to v_pack_factor - 1 loop
            v_tmp((v_pack_factor - j) * v_data_size - 1 downto (v_pack_factor - j - 1) * v_data_size) := v_pad;
          end loop;
        end if;
        v_data(0) := v_tmp;
        v_didx := 1;
      end if;
      -- pack data
      if data'length >= v_pack_factor then
        for i in 0 to data'length / v_pack_factor - 1 loop
          if msb_first then
            for j in 0 to v_pack_factor - 1 loop
              v_data(v_didx)((v_pack_factor - j) * v_data_size - 1 downto (v_pack_factor - j - 1) * v_data_size) := data(data'low + v_idx);
              v_idx := v_idx + 1;
            end loop;
          else
            for j in v_pack_factor - 1 downto 0 loop
              v_data(v_didx)((v_pack_factor - j) * v_data_size - 1 downto (v_pack_factor - j - 1) * v_data_size) := data(data'low + v_idx);
              v_idx := v_idx + 1;
            end loop;
          end if;
          v_didx := v_didx + 1;
        end loop;
      end if;
      -- pad after
      if v_pad_words > 0 and pad_after = True then
        if msb_first then
          for j in 0 to v_pack_factor - v_pad_words - 1 loop
            v_tmp((v_pack_factor - j) * v_data_size - 1 downto (v_pack_factor - j - 1) * v_data_size) := data(data'low + v_idx);
            v_idx := v_idx + 1;
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
            v_idx := v_idx + 1;
          end loop;
        end if;
        v_data(v_didx) := v_tmp;
        v_didx := v_didx + 1;
      end if;
    end if;

    return v_data(0 to v_didx - 1);
  end function f_repack;

  -------------------------------------------------------------------------------
  --! \param data      Input data array 
  --! \param new_width Target data width
  --! \param msb_first Insert/extract most significant bits first if True, least significant bits if False
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
  function f_repack(data: t_slv_arr; 
                    new_width:  natural;
                    msb_first: boolean) 
    return t_slv_arr is
    variable v_pad_value: std_logic_vector(data(data'low)'length - 1 downto 0) := (others => '0');
  begin
    return f_repack(data, new_width, msb_first, C_PAD_AFTER, v_pad_value);
  end function f_repack;

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
  --! array_32bit := (x"11223344", x"abcdef00);
  --! array_swapped := f_swap_endian(array_32bit); -- array_swapped is now (x"44332211",  x"00efcdab")
  --! ~~~
  -------------------------------------------------------------------------------
  function f_swap_endian(data: t_slv_arr) 
    return t_slv_arr is

    variable v_data_size : natural := data(data'low)'length;
    variable v_bytes : natural := v_data_size / 8;
    variable v_data: t_slv_arr(0 to data'length - 1)(v_data_size - 1 downto 0);
    variable v_tmp : std_logic_vector(v_data_size - 1 downto 0);
  begin
    assert v_data_size mod 8 = 0 report "f_swap_endian: input data array word width must be integer factor of 8" severity C_SEVERITY;
    assert data'ascending report "f_swap_endian: input data array must be ascending" severity C_SEVERITY;
    assert data(data'low)'ascending = False report "f_swap_endian: input data words must be descending" severity C_SEVERITY;
    assert data(data'low)'right = 0 report "f_swap_endian: input data words must be descending to zero" severity C_SEVERITY;

    for i in data'low to data'high loop
      v_tmp := data(i);
      for b in 0 to v_bytes - 1 loop
        v_data(i - data'low)((b + 1) * 8 - 1 downto b * 8) := v_tmp((v_bytes - b) * 8 - 1 downto (v_bytes - b - 1) * 8);
      end loop;
    end loop;
    return v_data;
  end function f_swap_endian;

end package body nw_util_pkg;
