-------------------------------------------------------------------------------
-- Title      : Network Wizard Stateless Codec
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: 
--!\file
--!\brief Stateless generic codec functions
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

--! \page nw_sl_codec Codec library
--! \tableofcontents
--! \section codec Stateless codec
--! This library provides functions for a generic stateless codec.  
--!
--! \subsection sl_codec_subsec1 Functionality
--! \li Perform data word stuffing (replace specific words with an escape sequence)
--! \li Encode data words from lookup table
--!
--! Other libraries in Codec are: 
--! \li \subpage nw_cobs
--! \li \subpage nw_base
--! \li \subpage nw_bstuff
--! \li \subpage nw_hamming
--!
--! \n More details in \ref nw_sl_codec_pkg
--! \subsection sl_codec_subsec2 Example use
--! Include the libraries:
--! ~~~
--! library nw_codec;
--! context nw_codec.nw_codec_context;
--! ~~~
--! Example 1: Bytestuffing of PPP frame - replace 0x7e and 0x7d with escape sequences. First, define the codec:
--! ~~~
--! constant C_PPP_CODEC : t_codec(0 to 1)(word(7 downto 0), code(0 to 1)(7 downto 0)) := ((word => x"7e", code => (x"7d", x"5e")),
--!                                                                                        (word => x"7d", code => (x"7d", x"5d")));
--! ~~~
--! Then encode a data array:
--! ~~~
--! v_data                    := (x"19", x"7e", x"fa", x"91", x"7d", x"80", x"00"); -- data array to be encoded
--! v_len                     := f_sl_enc_len(v_data, C_PPP_CODEC); -- get length of encoded data (v_len is now 9)
--! v_encoded(0 to v_len - 1) := f_sl_enc(v_data, C_PPP_CODEC); -- v_encoded is now (x"19", x"7d", x"5e", x"fa", x"91", x"7d", x"5d", x"80", x"00")
--! ~~~
--! Decode the encoded data:
--! ~~~
--! v_dlen                     := f_sl_dec_len(v_encoded(0 to v_len - 1), C_PPP_CODEC); -- get length od decoded data
--! v_decoded(0 to v_dlen - 1) := f_sl_dec(v_encoded(0 to v_len - 1), C_PPP_CODEC); -- v_decoded is now equal to v_data
--! ~~~
--! Example 2: Encode data with lookup table - here we will apply Hamming(7,4) coding to a data vector (not an elegant way to perform Hamming coding, but nonetheless).\n
--! First, define the codec (the loopup table must be complete):
--! ~~~
--! constant C_HAMMING_7_4: t_codec(0 to 15)(word(3 downto 0), code(0 to 0)(6 downto 0)) := ((word => x"0", code => (others => "0000000")),
--!                                                                                          (word => x"1", code => (others => "1101001")),
--!                                                                                          (word => x"2", code => (others => "0101010")),
--!                                                                                          (word => x"3", code => (others => "1000011")),
--!                                                                                          (word => x"4", code => (others => "1001100")),
--!                                                                                          (word => x"5", code => (others => "0100101")),
--!                                                                                          (word => x"6", code => (others => "1100110")),
--!                                                                                          (word => x"7", code => (others => "0001111")),
--!                                                                                          (word => x"8", code => (others => "1110000")),
--!                                                                                          (word => x"9", code => (others => "0011001")),
--!                                                                                          (word => x"a", code => (others => "1011010")),
--!                                                                                          (word => x"b", code => (others => "0110011")),
--!                                                                                          (word => x"c", code => (others => "0111100")),
--!                                                                                          (word => x"d", code => (others => "1010101")),
--!                                                                                          (word => x"e", code => (others => "0010110")),
--!                                                                                          (word => x"f", code => (others => "1111111")));
--! ~~~
--! The the codec is applied to a data vector:
--! ~~~ 
--! v_data                := (x"7", x"0", x"e", x"a"); -- data array to be encoded
--! v_len                 := f_sl_enc_len(v_data, C_HAMMING_7_4); -- get length of encoded data (in this case will be equal to v_data length)
--! v_ham(0 to v_len - 1) := f_sl_enc(v_data, C_HAMMING_7_4); -- v_ham is now ("0001111", "0000000", "0010110", "1011010")
--! ~~~
--! See further examples in the test bench nw_codec_tb.vhd.
package nw_sl_codec_pkg is

  -------------------------------------------------------------------------------
  -- Types
  -------------------------------------------------------------------------------
  type t_code_word is record
    word : std_logic_vector;            --! data word
    code : t_slv_arr;                   --! code word array
  end record t_code_word;

  type t_codec is array(natural range <>) of t_code_word;  --! Codec (array of data & code words)

  -------------------------------------------------------------------------------
  -- Functions
  -------------------------------------------------------------------------------
  function f_sl_enc(data  : t_slv_arr;
                    codec : t_codec) return t_slv_arr;

  function f_sl_enc_len (data  : t_slv_arr;
                         codec : t_codec) return natural;

  function f_sl_dec(data  : t_slv_arr;
                    codec : t_codec) return t_slv_arr;

  function f_sl_dec_len (data  : t_slv_arr;
                         codec : t_codec) return natural;

end package nw_sl_codec_pkg;

package body nw_sl_codec_pkg is

  -------------------------------------------------------------------------------
  -- Encode data (internal)
  -------------------------------------------------------------------------------
  function f_sl_enc(data       : t_slv_arr;
                    codec      : t_codec;
                    get_length : boolean := false)
    return t_slv_arr is
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
    variable v_len    : natural;
    variable v_clen   : natural := codec(0).code'length;
    variable v_data   : t_slv_arr(0 to data'length * v_clen)(codec(0).code(0)'high downto 0);
    variable v_idx    : natural := 0;
    variable v_found  : boolean;
    variable v_cidx   : natural;
  begin
    assert codec(0).word'length = data(data'low)'length report "f_sl_enc: codec words must have same width as data words" severity C_SEVERITY;

    for i in data'low to data'high loop
      v_found := false;
      v_cidx  := 0;
      while v_cidx < codec'length and not v_found loop
        if data(i) = codec(v_cidx).word then
          for j in 0 to v_clen - 1 loop
            v_data(v_idx) := codec(v_cidx).code(j);
            v_idx         := v_idx + 1;
          end loop;
          v_found := true;
        end if;
        v_cidx := v_cidx + 1;
      end loop;
      if not v_found then
        v_data(v_idx) := data(i);
        v_idx         := v_idx + 1;
      end if;
    end loop;
    if get_length then
      v_length(0) := std_logic_vector(to_unsigned(v_idx, 31));
      return v_length;
    else
      return v_data(0 to v_idx - 1);
    end if;
  end function f_sl_enc;

  -------------------------------------------------------------------------------
  --! \brief Encode data
  --! \param data  Data array 
  --! \param codec Codec to use
  --! \return      Encoded data
  --!
  --! Encode data with a custom codec.
  --!
  --! **Example use**
  --! ~~~
  --! encoded_data := f_sl_enc(data_8bit, codec);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_sl_enc(data  : t_slv_arr;
                    codec : t_codec)
    return t_slv_arr is
  begin
    return f_sl_enc(data, codec, false);
  end function f_sl_enc;

  -------------------------------------------------------------------------------
  --! \brief Get encoded data length
  --! \param data  Data array 
  --! \param codec Codec to use
  --! \return      Encoded data length
  --!
  --! Get length of encoded data with a custom codec.
  --!
  --! **Example use**
  --! ~~~
  --! v_len := f_sl_enc_len(data_8bit, codec);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_sl_enc_len(data  : t_slv_arr;
                        codec : t_codec)
    return natural is
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    v_length := f_sl_enc(data, codec, true);
    return to_integer(unsigned(v_length(0)));
  end function f_sl_enc_len;

  -------------------------------------------------------------------------------
  -- Decode data (internal)
  -------------------------------------------------------------------------------
  function f_sl_dec(data       : t_slv_arr;
                    codec      : t_codec;
                    get_length : boolean := false)
    return t_slv_arr is
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
    variable v_len    : natural;
    variable v_clen   : natural := codec(0).code'length;
    variable v_data   : t_slv_arr(0 to data'length * v_clen)(codec(0).word'high downto 0);
    variable v_idx    : natural := 0;
    variable v_found  : boolean;
    variable v_cidx   : natural;
    variable v_i      : natural := data'low;
  begin
    assert codec(0).code(0)'length = data(data'low)'length report "f_sl_dec: codec words must have same width as data words" severity C_SEVERITY;

    --for i in data'low to data'high loop
    while v_i <= data'high loop
      v_found := false;
      v_cidx  := 0;
      while v_cidx < codec'length and not v_found loop
        if v_i <= data'high + 1 - v_clen then
          if data(v_i to v_i + v_clen - 1) = codec(v_cidx).code(0 to v_clen - 1) then
            v_data(v_idx) := codec(v_cidx).word;
            v_idx         := v_idx + 1;
            v_i           := v_i + v_clen;
            v_found       := true;
          end if;
        end if;
        v_cidx := v_cidx + 1;
      end loop;
      if not v_found then
        if v_data(0)'length /= data(v_i)'length then
          assert false report "f_sl_dec: did not find code word in codec" severity C_SEVERITY;
          v_data(v_idx) := (others => '0');
        else
          v_data(v_idx) := data(v_i);
        end if;
        v_idx := v_idx + 1;
        v_i   := v_i + 1;
      end if;
    end loop;
    if get_length then
      v_length(0) := std_logic_vector(to_unsigned(v_idx, 31));
      return v_length;
    else
      return v_data(0 to v_idx - 1);
    end if;
  end function f_sl_dec;

  -------------------------------------------------------------------------------
  --! \brief Decode data
  --! \param data  Data array 
  --! \param codec Codec to use
  --! \return      Encoded data
  --!
  --! Decode data with a custom codec.
  --!
  --! **Example use**
  --! ~~~
  --! decoded_data := f_sl_dec(encoded_data, codec);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_sl_dec(data  : t_slv_arr;
                    codec : t_codec)
    return t_slv_arr is
  begin
    return f_sl_dec(data, codec, false);
  end function f_sl_dec;

  -------------------------------------------------------------------------------
  --! \brief Get decoded data length
  --! \param data  Data array 
  --! \param codec Codec to use
  --! \return      Decoded data length
  --!
  --! Get length of decoded data with a custom codec.
  --!
  --! **Example use**
  --! ~~~
  --! v_len := f_sl_dec_len(encoded_data, codec);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_sl_dec_len(data  : t_slv_arr;
                        codec : t_codec)
    return natural is
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    v_length := f_sl_dec(data, codec, true);
    return to_integer(unsigned(v_length(0)));
  end function f_sl_dec_len;

end package body nw_sl_codec_pkg;
