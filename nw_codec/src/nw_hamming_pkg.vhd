-------------------------------------------------------------------------------
-- Title      : Network Wizard Hamming Codec
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: 
--!\file
--!\brief Hamming codec functions
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

--! \page nw_hamming Codec library
--! \tableofcontents
--! \section codec Hamming codec
--! This library provides functions for Hamming encoding and decoding.  
--! Single error correction/double error detection (SECDED)
--!
--! \subsection hamming__subsec1 Functionality
--! \li Perform Hamming encoding
--! \li Perform Hamming decoding
--! \li Perform parity calculation (odd/even)
--! 
--! The number of parity bits (r) for a data word of length n is given by the equation: 2^r &ge; r + n + 1.
--! Position of the parity bits are given by 2^p, p &isin; [0, r).
--!
--! \n More details in \ref nw_hamming_pkg
--! \subsection hamming_subsec2 Example use
--! Include the libraries:
--! ~~~
--! library nw_codec;
--! context nw_codec.nw_codec_context;
--! ~~~
--! Example 1: 
--! 
--! See further examples in the test bench nw_codec_tb.vhd.
package nw_hamming_pkg is

  -------------------------------------------------------------------------------
  -- Functions
  -------------------------------------------------------------------------------
  function f_calc_parity(data: std_logic_vector;
                         even_parity: boolean := true) return std_logic;

  function f_calc_parity(data: t_slv_arr;
                         even_parity: boolean := true) return t_slv_arr;

  function f_hamming_enc(data  : t_slv_arr;
                         extra_parity: boolean := False) return t_slv_arr;

  function f_hamming_enc(data  : t_slv_arr;
                         extra_parity: boolean := False) return t_slv_arr_ptr;

  function f_hamming_enc_width (data  : t_slv_arr;
                            extra_parity: boolean := False) return natural;

  -- function f_sl_dec(data  : t_slv_arr;
  --                   codec : t_codec) return t_slv_arr;

  -- function f_sl_dec_len (data  : t_slv_arr;
  --                        codec : t_codec) return natural;

end package nw_hamming_pkg;

package body nw_hamming_pkg is

  -------------------------------------------------------------------------------
  -- Calculate number of parity bits (internal)
  -------------------------------------------------------------------------------
  function f_calc_num_bits(data       : t_slv_arr)
    return integer is
      variable v_r: integer := 0;
      variable v_m: integer;
    begin
      v_m := data(data'low)'length;
      while 2**v_r < v_m + v_r + 1 loop
        v_r := v_r + 1;
      end loop;

      return v_r;
  end function f_calc_num_bits;

  -------------------------------------------------------------------------------
  --! \brief Caclulate parity
  --! \param data        Data vector
  --! \param even_parity True = Use even parity (default), false = use odd parity
  --! \return            Parity bit
  --!
  --! Calculate parity (even or odd) of a logic vector.
  --!
  --! **Example use**
  --! ~~~
  --! parity := f_calc_parity("0010101111101");
  --! ~~~
  -------------------------------------------------------------------------------
  function f_calc_parity(data: std_logic_vector;
                         even_parity: boolean := true) 
    return std_logic is
    begin
      if even_parity then
        return xor data;
      else
        return xnor data;
      end if;
    end function f_calc_parity;

  -------------------------------------------------------------------------------
  --! \brief Caclulate parity
  --! \param data        Data array
  --! \param even_parity True = Use even parity (default), false = use odd parity
  --! \return            Parity bit array
  --!
  --! Calculate parity (even or odd) of a logic vector array. Returns a one-bit array of parity.
  --!
  --! **Example use**
  --! ~~~
  --! parity_array := f_calc_parity(data_array);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_calc_parity(data: t_slv_arr;
                         even_parity: boolean := true) 
    return t_slv_arr is
      variable v_ret: t_slv_arr(0 to data'length - 1)(0 downto 0);
      variable v_idx : integer := 0;
    begin
      assert data'ascending report "f_calc_parity: data array must be ascending" severity C_SEVERITY;
      for i in data'low to data'high loop
        if even_parity then
          v_ret(v_idx)(0) := xor data(i);
        else
          v_ret(v_idx)(0) := xnor data(i);
        end if;
        v_idx := v_idx + 1;
      end loop;
      return v_ret;
    end function f_calc_parity;

  -------------------------------------------------------------------------------
  --! \brief Encode data
  --! \param data         Data array 
  --! \param extra_parity Add extra parity bit (default=false)
  --! \return             Encoded data array pointer
  --!
  --! Encode data with a Hamming encoder. The returned pointer should be deallocated after use to avoid memory leaks.
  --!
  --! **Example use**
  --! ~~~
  --! encoded_data_ptr := f_hamming_enc(data, true);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_hamming_enc(data  : t_slv_arr;
                         extra_parity: boolean := False)
    return t_slv_arr_ptr is
      variable v_r: integer;
      variable v_m: integer := data(data'low)'length;
      variable v_rtot: integer;
      variable v_res : t_slv_arr_ptr;
      variable v_didx : integer;
      variable v_pidx : integer;
      variable v_parity : integer;
      variable v_2pj: unsigned(30 downto 0);
  begin
    assert data'ascending report "f_hamming_enc: data array must be ascending" severity C_SEVERITY;
    assert data(data'low)'ascending = false report "f_hamming_enc: input data words must be descending" severity C_SEVERITY;
    -- calculate number of parity bits
    v_r := f_calc_num_bits(data); 
    -- allocate output array 
    v_rtot := v_m + v_r;
    if extra_parity then
      v_rtot := v_rtot + 1;
    end if;
    v_res := new t_slv_arr(data'low to data'high)(v_rtot - 1 downto 0);
    -- process data
    for i in data'range loop
      -- put data in right positions
      v_didx := 0;
      v_pidx := 0;
      for j in 0 to v_rtot - 1 loop
        if j + 1 = 2**v_pidx then -- parity bit position
          v_res(i)(j) := '0';
          v_pidx := v_pidx + 1;
        else
          v_res(i)(j) := data(i)(v_didx);
          v_didx := v_didx + 1;
        end if;
      end loop;
      -- calculate parity bits
      for j in 0 to v_r - 1 loop
        v_parity := 0;
        for k in 2**j to v_rtot - 1 loop
          v_2pj := to_unsigned(2**j, 31);
          if (to_unsigned(k+1, 31) and v_2pj) = v_2pj then
            if v_res(i)(k) = '1' then
              v_parity := v_parity + 1;
            end if;
          end if;
        end loop;
        if v_parity mod 2 = 1 then
          v_res(i)(2**j - 1) := '1';
        end if;
      end loop;
      -- extra parity bit
      if extra_parity then
        v_res(i)(v_rtot - 1) := f_calc_parity(v_res(i)(v_rtot - 2 downto 0), true);
      end if;
    end loop;
    
    return v_res;
  end function f_hamming_enc;

  -------------------------------------------------------------------------------
  --! \brief Encode data
  --! \param data         Data array 
  --! \param extra_parity Add extra parity bit (default=false)
  --! \return             Encoded data array
  --!
  --! Encode data with a Hamming encoder. 
  --!
  --! **Example use**
  --! ~~~
  --! encoded_data := f_hamming_enc(data, true);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_hamming_enc(data  : t_slv_arr;
                         extra_parity: boolean := False)
    return t_slv_arr is
      variable v_ptr : t_slv_arr_ptr;
    begin
      v_ptr := f_hamming_enc(data, extra_parity);

      return v_ptr.all;
    end function f_hamming_enc;

  -------------------------------------------------------------------------------
  --! \brief Get encoded data width
  --! \param data         Data array 
  --! \param extra_parity Add extra parity bit (default=false) 
  --! \return             Encoded data array
  --!
  --! Get encoded data with.
  --!
  --! **Example use**
  --! ~~~
  --! edata_width := f_hamming_enc_width(data);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_hamming_enc_width(data  : t_slv_arr;
                               extra_parity: boolean := False)
    return natural is
      variable v_r: natural;
      variable v_m: integer := data(data'low)'length;
  begin
    -- calculate number of parity bits
    v_r := f_calc_num_bits(data); 
    if extra_parity then
      v_r := v_r + 1;
    end if;

    return v_r + v_m;
  end function f_hamming_enc_width;


end package body nw_hamming_pkg;
