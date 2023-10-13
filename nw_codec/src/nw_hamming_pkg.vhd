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

--! \page nw_hamming Hamming codec
--! \tableofcontents
--! \section hamming Hamming codec
--! This library provides functions for Hamming encoding and decoding of data arrays of any width/size.  
--! Supports single error correction/double error detection (SECDED).
--!
--! \subsection hamming__subsec1 Functionality
--! \li Perform Hamming encoding
--! \li Perform Hamming decoding
--! \li Perform parity calculation (odd/even)
--! 
--! The number of parity bits (r) for a data word of length n is given by the equation: 2^r &ge; r + n + 1.
--! The output of the encoder is non-systematic: Position of the parity bits are given by 2^p, p &isin; [0, r).
--! The decoder expects the parity bits of the encoded data to be positioned as above.
--!
--! \n More details in \ref nw_hamming_pkg
--! \subsection hamming_subsec2 Example use
--! Include the libraries:
--! ~~~
--! library nw_codec;
--! context nw_codec.nw_codec_context;
--! ~~~
--! Example 1: Encode/decode 32bit data array without extra parity bit. 
--! ~~~
--! v_ewidth   := f_hamming_enc_width(data_array_32bit, false); -- determine word width of encoded array
--! v_enc_data := new t_slv_arr(0 to data_array_32bit'length - 1)(v_ewidth - 1 downto 0); -- allocate array
--! v_enc_data := f_hamming_enc(data_array_32bit, false); -- encode data
--! ...
--! v_dwidth   := f_hamming_dec_width(v_enc_data, false); -- determine width of decoded data (32bit + 1 status bit)
--! v_dec_data := new t_slv_arr(0 to data_array_32bit'length - 1)(v_dwidth - 1 downto 0); -- allocate array
--! v_dec_data := f_hamming_dec(v_enc_data, false); -- decode data (MSB holds error status)
--! ~~~
--! Example 2: Encode/decode 128bit data array with extra parity bit (SECDED). 
--! ~~~
--! v_ewidth   := f_hamming_enc_width(data_array_128bit, true); -- determine word width of encoded array
--! v_enc_data := new t_slv_arr(0 to data_array_128bit'length - 1)(v_ewidth - 1 downto 0); -- allocate array
--! v_enc_data := f_hamming_enc(data_array_128bit, true); -- encode data
--! ...
--! v_dwidth   := f_hamming_dec_width(v_enc_data, true); -- determine width of decoded data (128bit + 2 status bits)
--! v_dec_data := new t_slv_arr(0 to data_array_128bit'length - 1)(v_dwidth - 1 downto 0); -- allocate array
--! v_dec_data := f_hamming_dec(v_enc_data, true); -- decode data (two MSBs hold error status)
--! ~~~
--! See further examples in the test bench nw_codec_tb.vhd.
package nw_hamming_pkg is

  -------------------------------------------------------------------------------
  -- Functions
  -------------------------------------------------------------------------------
  function f_calc_parity(data        : std_logic_vector;
                         even_parity : boolean := true) return std_logic;

  function f_calc_parity(data        : t_slv_arr;
                         even_parity : boolean := true) return t_slv_arr;

  impure function f_hamming_enc(data         : t_slv_arr;
                                extra_parity : boolean := false) return t_slv_arr;

  impure function f_hamming_enc(data         : t_slv_arr;
                                extra_parity : boolean := false) return t_slv_arr_ptr;

  function f_hamming_enc_width(data         : t_slv_arr;
                               extra_parity : boolean := false) return natural;

  impure function f_hamming_dec(data         : t_slv_arr;
                                extra_parity : boolean := false) return t_slv_arr;

  impure function f_hamming_dec(data         : t_slv_arr;
                                extra_parity : boolean := false) return t_slv_arr_ptr;

  function f_hamming_dec_width(data         : t_slv_arr;
                               extra_parity : boolean := false) return natural;

end package nw_hamming_pkg;

package body nw_hamming_pkg is

  -------------------------------------------------------------------------------
  -- Calculate number of parity bits during encoding (internal)
  -------------------------------------------------------------------------------
  function f_calc_num_bits(data : t_slv_arr)
    return integer is
    variable v_r : integer := 0;
    variable v_m : integer;
  begin
    v_m := data(data'low)'length;
    while 2**v_r < v_m + v_r + 1 loop
      v_r := v_r + 1;
    end loop;

    return v_r;
  end function f_calc_num_bits;

  -------------------------------------------------------------------------------
  -- Calculate number of parity bits for decoding (internal)
  -------------------------------------------------------------------------------
  function f_calc_num_bits_dec(data_len : integer)
    return integer is
    variable v_r : integer := 0;
    variable v_m : integer := 0;
  begin
    while v_r + v_m /= data_len loop
      v_m := v_m + 1;
      while 2**v_r < v_m + v_r + 1 loop
        v_r := v_r + 1;
      end loop;
    end loop;

    return v_r;
  end function f_calc_num_bits_dec;

  -------------------------------------------------------------------------------
  -- Calculate hamming parity bits, data word is non-systematic (internal)
  -------------------------------------------------------------------------------
  function f_calc_hamming_bits(data         : std_logic_vector;
                               parity_bits  : integer;
                               extra_parity : boolean := false)
    return std_logic_vector is
    variable v_par    : std_logic_vector(parity_bits - 1 downto 0) := (others => '0');
    variable v_parity : integer;
    variable v_dwidth : integer                                    := data'length;
    variable v_2pj    : unsigned(30 downto 0);
  begin
    if extra_parity then
      v_dwidth := v_dwidth - 1;
    end if;
    -- calculate hamming parity bits
    for j in 0 to parity_bits - 1 loop
      v_parity := 0;
      for k in 2**j - 1 to v_dwidth - 1 loop
        v_2pj := to_unsigned(2**j, 31);
        if (to_unsigned(k+1, 31) and v_2pj) = v_2pj then
          if data(k) = '1' then
            v_parity := v_parity + 1;
          end if;
        end if;
      end loop;
      if v_parity mod 2 = 1 then
        v_par(j) := '1';
      end if;
    end loop;

    return v_par;
  end function f_calc_hamming_bits;

  -------------------------------------------------------------------------------
  --! \brief Calculate parity
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
  function f_calc_parity(data        : std_logic_vector;
                         even_parity : boolean := true)
    return std_logic is
  begin
    if even_parity then
      return xor data;
    else
      return xnor data;
    end if;
  end function f_calc_parity;

  -------------------------------------------------------------------------------
  --! \brief Calculate parity
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
  function f_calc_parity(data        : t_slv_arr;
                         even_parity : boolean := true)
    return t_slv_arr is
    variable v_ret : t_slv_arr(0 to data'length - 1)(0 downto 0);
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
  --! \brief Encode data array
  --! \param data         Data array 
  --! \param extra_parity Add extra parity bit (default=false)
  --! \return             Encoded data array pointer
  --!
  --! Encode data with a Hamming encoder. The returned pointer should be deallocated after use to avoid memory leaks.
  --! The encoded data is non-systematic (data and parity bits mixed).
  --!
  --! **Example use**
  --! ~~~
  --! encoded_data_ptr := f_hamming_enc(data);
  --! ~~~
  -------------------------------------------------------------------------------
  impure function f_hamming_enc(data         : t_slv_arr;
                                extra_parity : boolean := false)
    return t_slv_arr_ptr is
    variable v_r      : integer;
    variable v_m      : integer := data(data'low)'length;
    variable v_rtot   : integer;
    variable v_res    : t_slv_arr_ptr;
    variable v_par    : std_logic_vector(data(data'low)'length downto 0);
    variable v_didx   : integer;
    variable v_pidx   : integer;
    variable v_parity : integer;
    variable v_2pj    : unsigned(30 downto 0);
  begin
    assert data'ascending report "f_hamming_enc: data array must be ascending" severity C_SEVERITY;
    assert data(data'low)'ascending = false report "f_hamming_enc: input data bits must be descending" severity C_SEVERITY;
    -- calculate number of parity bits
    v_r    := f_calc_num_bits(data);
    -- allocate output array 
    v_rtot := v_m + v_r;
    if extra_parity then
      v_rtot := v_rtot + 1;
    end if;
    v_res := new t_slv_arr(data'low to data'high)(v_rtot - 1 downto 0);
    -- encode data
    for i in data'range loop
      -- put data in right positions
      v_didx := 0;
      v_pidx := 0;
      for j in 0 to v_m + v_r - 1 loop
        if j + 1 = 2**v_pidx then       -- parity bit position
          v_res(i)(j) := '0';
          v_pidx      := v_pidx + 1;
        else
          v_res(i)(j) := data(i)(v_didx);
          v_didx      := v_didx + 1;
        end if;
      end loop;
      -- calculate parity bits
      v_par(v_r - 1 downto 0) := f_calc_hamming_bits(v_res(i), v_r, extra_parity);
      for j in 0 to v_r - 1 loop
        v_res(i)(2**j - 1) := v_par(j);
      end loop;
      -- extra parity bit
      if extra_parity then
        v_res(i)(v_rtot - 1) := f_calc_parity(v_res(i)(v_rtot - 2 downto 0), true);
      end if;
    end loop;

    return v_res;
  end function f_hamming_enc;

  -------------------------------------------------------------------------------
  --! \brief Encode data array
  --! \param data         Data array 
  --! \param extra_parity Add extra parity bit (default=false)
  --! \return             Encoded data array
  --!
  --! Encode data with a Hamming encoder. Same as above, but returns a data array instead of pointer.
  --!
  --! **Example use**
  --! ~~~
  --! encoded_data := f_hamming_enc(data, true);
  --! ~~~
  -------------------------------------------------------------------------------
  impure function f_hamming_enc(data         : t_slv_arr;
                                extra_parity : boolean := false)
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
  --! \return             Encoded data array width
  --!
  --! Get encoded data width. The encoded data width is the sum of data bits in input data and the number of parity bits required.
  --!
  --! **Example use**
  --! ~~~
  --! edata_width := f_hamming_enc_width(data);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_hamming_enc_width(data         : t_slv_arr;
                               extra_parity : boolean := false)
    return natural is
    variable v_r : natural;
    variable v_m : integer := data(data'low)'length;
  begin
    -- calculate number of parity bits
    v_r := f_calc_num_bits(data);
    if extra_parity then
      v_r := v_r + 1;
    end if;

    return v_r + v_m;
  end function f_hamming_enc_width;

  -------------------------------------------------------------------------------
  --! \brief Decode data array
  --! \param data         Encoded data array 
  --! \param extra_parity Has extra parity bit (default=false)
  --! \return             Pointer to decoded data array with status
  --!
  --! Decode data with a Hamming decoder. The returned pointer should be deallocated after use to avoid memory leaks.
  --! If input data does not have extra parity bit, single errors will be corrected, and one extra status bit is added 
  --! to decoded data to indicate positions where correction has been made.
  --! If input data have extra parity bit, two errors can be detected and one error corrected. This is indicated with two status bits,
  --! the first indicates single error correction, and the last double error detection.
  --!
  --! **Example use**
  --! ~~~
  --! decoded_data_ptr := f_hamming_dec(data, true);
  --! decoded_data     := decoded_data_ptr.all;
  --! v_statpos        := decoded_data(0)'high;
  --! for i in decoded_data'range loop
  --!   if decoded_data(i)(v_statpos) = '1' then -- double error detected
  --!     ...
  --!   elsif decoded_data(i)(v_statpos - 1) = '1' then -- sigle error corrected
  --!     ...
  --!   end if;  
  --! end loop;
  --! -- deallocate the array when finished
  --! deallocate(decoded_data_ptr);
  --! ~~~
  -------------------------------------------------------------------------------
  impure function f_hamming_dec(data         : t_slv_arr;
                                extra_parity : boolean := false)
    return t_slv_arr_ptr is
    variable v_r       : integer;
    variable v_n       : integer;
    variable v_rs      : integer;
    variable v_m       : integer := data(data'low)'length;
    variable v_par     : std_logic_vector(v_m downto 0);
    variable v_dec     : t_slv_arr_ptr;
    variable v_didx    : integer;
    variable v_pidx    : integer;
    variable v_syn     : integer;
    variable v_data    : std_logic_vector(v_m - 1 downto 0);
    variable v_eparity : std_logic;
    variable v_end     : integer := 1;
  begin
    assert data'ascending report "f_hamming_dec: data array must be ascending" severity C_SEVERITY;
    assert data(data'low)'ascending = false report "f_hamming_dec: input data bits must be descending" severity C_SEVERITY;

    -- determine the width of the decoded data array with status bits
    v_rs := f_hamming_dec_width(data, extra_parity);
    -- determin how many hamming parity bits were used
    v_r  := f_calc_num_bits_dec(v_m);
    -- determine original data width
    v_n  := v_m - f_calc_num_bits_dec(v_m);
    if extra_parity then
      v_n := v_n - 1;
    end if;
    -- allocate data array for decoded data
    v_dec := new t_slv_arr(data'low to data'high)(v_rs - 1 downto 0);
    -- decode data
    for i in data'range loop
      v_data                  := data(i);
      -- calculate hamming parity bits
      v_par(v_r - 1 downto 0) := f_calc_hamming_bits(v_data, v_r, extra_parity);
      -- check parity and correct if possible
      v_dec(i)(v_rs - 1)      := '0';
      v_syn                   := to_integer(unsigned(v_par(v_r - 1 downto 0)));  -- syndrome

      if extra_parity then
        v_end              := 2;
        v_dec(i)(v_rs - 2) := '0';
        v_eparity          := f_calc_parity(v_data);
        if v_syn > 0 then
          if v_eparity = '0' then         -- double error detected
            v_dec(i)(v_rs - 1) := '1';
          elsif v_syn <= v_m - 1 then     -- single bit error can be corrected
            v_dec(i)(v_rs - 2) := '1';
            v_data(v_syn - 1)  := not v_data(v_syn - 1);
          end if;
        end if;
      else
        if v_syn > 0 then                 -- error detected
          v_dec(i)(v_rs - 1) := '1';
          if v_syn           <= v_m then  -- single bit error can be corrected
            v_data(v_syn - 1) := not v_data(v_syn - 1);
          end if;
        end if;
      end if;
      -- extract data vector
      v_didx := 0;
      v_pidx := 0;
      for j in 0 to v_m - v_end loop
        if j + 1 = 2**v_pidx then         -- parity bit position
          v_pidx := v_pidx + 1;
        else
          v_dec(i)(v_didx) := v_data(j);
          v_didx           := v_didx + 1;
        end if;
      end loop;
    end loop;

    return v_dec;
  end function f_hamming_dec;

  -------------------------------------------------------------------------------
  --! \brief Decode data array
  --! \param data         Encoded data array 
  --! \param extra_parity Has extra parity bit (default=false)
  --! \return             Decoded data array with status
  --!
  --! Decode data with a Hamming decoder. Same as above, but returns a data array instead of pointer.
  --!
  --! **Example use**
  --! ~~~
  --! decoded_data := f_hamming_dec(data, true);
  --! ~~~
  -------------------------------------------------------------------------------
  impure function f_hamming_dec(data         : t_slv_arr;
                                extra_parity : boolean := false)
    return t_slv_arr is
    variable v_ptr : t_slv_arr_ptr;
  begin
    v_ptr := f_hamming_dec(data, extra_parity);

    return v_ptr.all;
  end function f_hamming_dec;

  -------------------------------------------------------------------------------
  --! \brief Get decoded data width
  --! \param data         Encoded data array 
  --! \param extra_parity Use extra parity bit (default=false) 
  --! \return             Width of decoded data including status bits
  --!
  --! Get decoded data width, which is the original data width plus one or two status bits.
  --!
  --! **Example use**
  --! ~~~
  --! data_width := f_hamming_dec_width(data, true);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_hamming_dec_width(data         : t_slv_arr;
                               extra_parity : boolean := false)
    return natural is
    variable v_r   : natural;
    variable v_m   : integer;
    variable v_org : integer := data(data'low)'length;
  begin
    -- calculate number of parity bits that was used to encode data
    if extra_parity then
      v_r := f_calc_num_bits_dec(v_org - 1);
    else
      v_r := f_calc_num_bits_dec(v_org);
    end if;
    -- calculate size of decoded array (including extra status bit(s))
    v_m := v_org - v_r + 1;

    return v_m;
  end function f_hamming_dec_width;


end package body nw_hamming_pkg;
