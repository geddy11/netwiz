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

--! \page nw_base Base16/32/64
--! \tableofcontents
--! \section base Base16, Base32, and Base64 data encoding/decoding
--! This library provides functions for Base16, Base32, and Base64 data encoding and decoding according to RFC 4648.  
--!
--! \subsection base_subsec1 Functionality
--! \li Perform Base16/32/64 encoding of data arrays 
--! \li Perform Base16/32/64 decoding of encoded data arrays 
--!
--! \n More details in \ref nw_base_pkg
--! \subsection base_subsec2 Example use
--! Include the libraries:
--! ~~~
--! library nw_codec;
--! context nw_codec.nw_codec_context;
--! ~~~
--! Data to be encoded must be in 8bit format.
--! ~~~
--! v_data                    := f_str_2_slv_arr("Blue shoes"); -- data array to be encoded
--! v_len                     := f_base_enc_len(v_data, BASE64); -- get length of encoded data (v_len is now 16)
--! v_encoded(0 to v_len - 1) := f_base_enc(v_data, BASE64); -- v_encoded is now "Qmx1ZSBzaG9lcw=="
--! v_len                     := f_base_enc_len(v_data, BASE32); -- get length of encoded data (v_len is now 16)
--! v_encoded(0 to v_len - 1) := f_base_enc(v_data, BASE32); -- v_encoded is now "IJWHKZJAONUG6ZLT"  
--! ~~~
--! Decode the encoded data:
--! ~~~
--! v_dlen                     := f_base_dec_len(v_encoded(0 to v_len - 1)); -- get length od decoded data (v_dlen is now 10)
--! v_decoded(0 to v_dlen - 1) := f_base_dec(v_encoded(0 to v_len - 1)); -- v_decoded is now equal to v_data
--! ~~~
--! See further examples in the test bench nw_codec_tb.vhd.
package nw_base_pkg is

  -------------------------------------------------------------------------------
  -- Types
  -------------------------------------------------------------------------------
  type t_base_alphabet is (BASE64, BASE64_SAFE, BASE32, BASE32HEX, BASE16);  --! base encoding alphabets (RFC 4648)

  -------------------------------------------------------------------------------
  -- Functions
  --! @cond functions
  -------------------------------------------------------------------------------
  function f_base_enc(data     : t_slv_arr;
                      alphabet : t_base_alphabet) return t_slv_arr;

  function f_base_enc_len(data     : t_slv_arr;
                          alphabet : t_base_alphabet) return natural;

  function f_base_dec(data     : t_slv_arr;
                      alphabet : t_base_alphabet) return t_slv_arr;

  function f_base_dec_len(data     : t_slv_arr;
                          alphabet : t_base_alphabet) return natural;
  --! @endcond

end package nw_base_pkg;

package body nw_base_pkg is

  -------------------------------------------------------------------------------
  -- Constants
  --! @cond constants
  -------------------------------------------------------------------------------
  constant C_BASE64 : t_slv_arr(0 to 64)(7 downto 0) := (x"41", x"42", x"43", x"44", x"45", x"46", x"47", x"48",
                                                         x"49", x"4a", x"4b", x"4c", x"4d", x"4e", x"4f", x"50",
                                                         x"51", x"52", x"53", x"54", x"55", x"56", x"57", x"58",
                                                         x"59", x"5a", x"61", x"62", x"63", x"64", x"65", x"66",
                                                         x"67", x"68", x"69", x"6a", x"6b", x"6c", x"6d", x"6e",
                                                         x"6f", x"70", x"71", x"72", x"73", x"74", x"75", x"76",
                                                         x"77", x"78", x"79", x"7a", x"30", x"31", x"32", x"33",
                                                         x"34", x"35", x"36", x"37", x"38", x"39", x"2b", x"2f",
                                                         x"3d");

  constant C_BASE64_SAFE : t_slv_arr(0 to 64)(7 downto 0) := (x"41", x"42", x"43", x"44", x"45", x"46", x"47", x"48",
                                                              x"49", x"4a", x"4b", x"4c", x"4d", x"4e", x"4f", x"50",
                                                              x"51", x"52", x"53", x"54", x"55", x"56", x"57", x"58",
                                                              x"59", x"5a", x"61", x"62", x"63", x"64", x"65", x"66",
                                                              x"67", x"68", x"69", x"6a", x"6b", x"6c", x"6d", x"6e",
                                                              x"6f", x"70", x"71", x"72", x"73", x"74", x"75", x"76",
                                                              x"77", x"78", x"79", x"7a", x"30", x"31", x"32", x"33",
                                                              x"34", x"35", x"36", x"37", x"38", x"39", x"2d", x"5f",
                                                              x"3d");

  constant C_BASE32 : t_slv_arr(0 to 32)(7 downto 0) := (x"41", x"42", x"43", x"44", x"45", x"46", x"47", x"48",
                                                         x"49", x"4a", x"4b", x"4c", x"4d", x"4e", x"4f", x"50",
                                                         x"51", x"52", x"53", x"54", x"55", x"56", x"57", x"58",
                                                         x"59", x"5a", x"32", x"33", x"34", x"35", x"36", x"37",
                                                         x"3d");

  constant C_BASE32_HEX : t_slv_arr(0 to 32)(7 downto 0) := (x"30", x"31", x"32", x"33", x"34", x"35", x"36", x"37",
                                                             x"38", x"39", x"41", x"42", x"43", x"44", x"45", x"46",
                                                             x"47", x"48", x"49", x"4a", x"4b", x"4c", x"4d", x"4e",
                                                             x"4f", x"50", x"51", x"52", x"53", x"54", x"55", x"56",
                                                             x"3d");

  constant C_BASE16 : t_slv_arr(0 to 15)(7 downto 0) := (x"30", x"31", x"32", x"33", x"34", x"35", x"36", x"37",
                                                         x"38", x"39", x"41", x"42", x"43", x"44", x"45", x"46");
  --! @endcond

  constant C_PAD: std_logic_vector(7 downto 0) := x"3d"; --! Pad character
  -------------------------------------------------------------------------------
  --! \brief Base encode data
  --! \param data     Data array (8bit)
  --! \param alphabet Alphabet to use
  --! \return         Encoded data
  --!
  --! Encode data according to RFC 4648 with the selected alphabet.
  --!
  --! **Example use**
  --! ~~~
  --! encoded_data := f_base_enc(data_8bit, BASE64);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_base_enc(data     : t_slv_arr;
                      alphabet : t_base_alphabet)
    return t_slv_arr is
    variable v_encoded : t_slv_arr(0 to 2 * data'length + 5)(7 downto 0);
    variable v_grps    : natural;
    variable v_dlen    : natural := data'length;
    variable v_idx     : natural := 0;
    variable v_d8      : std_logic_vector(7 downto 0);
    variable v_d24     : std_logic_vector(23 downto 0);
    variable v_d40     : std_logic_vector(39 downto 0);
    variable v_b64     : t_slv_arr(0 to 64)(7 downto 0);
    variable v_b32     : t_slv_arr(0 to 32)(7 downto 0);
  begin
    assert data'ascending report "f_base_enc: data array must be ascending" severity C_SEVERITY;
    assert data(data'low)'length = 8 report "f_base_enc: data must be 8bit" severity C_SEVERITY;

    case alphabet is
      when BASE64 | BASE64_SAFE =>
        if alphabet = BASE64 then
          v_b64 := C_BASE64;
        else
          v_b64 := C_BASE64_SAFE;
        end if;
        v_grps := v_dlen / 3;
        if v_grps > 0 then
          for i in 0 to v_grps - 1 loop
            v_d24(23 downto 16) := data(data'low + i * 3);
            v_d24(15 downto 8)  := data(data'low + i * 3 + 1);
            v_d24(7 downto 0)   := data(data'low + i * 3 + 2);
            for j in 0 to 3 loop
              v_encoded(v_idx + j) := v_b64(to_integer(unsigned(v_d24((4 - j) * 6 - 1 downto (3 - j) * 6))));
            end loop;
            v_idx := v_idx + 4;
          end loop;
        end if;
        -- remainder
        v_d24 := (others => '0');
        if v_dlen mod 3 = 1 then
          v_d24(23 downto 16) := data(data'low + v_grps * 3);
          for j in 0 to 1 loop
            v_encoded(v_idx + j) := v_b64(to_integer(unsigned(v_d24((4 - j) * 6 - 1 downto (3 - j) * 6))));
          end loop;
          v_encoded(v_idx + 2) := v_b64(64);
          v_encoded(v_idx + 3) := v_b64(64);
          v_idx                := v_idx + 4;
        elsif v_dlen mod 3 = 2 then
          v_d24(23 downto 16) := data(data'low + v_grps * 3);
          v_d24(15 downto 8)  := data(data'low + v_grps * 3 + 1);
          for j in 0 to 2 loop
            v_encoded(v_idx + j) := v_b64(to_integer(unsigned(v_d24((4 - j) * 6 - 1 downto (3 - j) * 6))));
          end loop;
          v_encoded(v_idx + 3) := v_b64(64);
          v_idx                := v_idx + 4;
        end if;
      when BASE32 | BASE32HEX =>
        if alphabet = BASE32 then
          v_b32 := C_BASE32;
        else
          v_b32 := C_BASE32_HEX;
        end if;
        v_grps := v_dlen / 5;
        if v_grps > 0 then
          for i in 0 to v_grps - 1 loop
            for j in 0 to 4 loop
              v_d40((5 - j) * 8 - 1 downto (4 - j) * 8) := data(data'low + i * 5 + j);
            end loop;
            for j in 0 to 7 loop
              v_encoded(v_idx + j) := v_b32(to_integer(unsigned(v_d40((8 - j) * 5 - 1 downto (7 - j) * 5))));
            end loop;
            v_idx := v_idx + 8;
          end loop;
        end if;
        -- remainder
        v_d40 := (others => '0');
        if v_dlen mod 5 = 1 then
          v_d40(39 downto 32) := data(data'low + v_grps * 5);
          for j in 0 to 1 loop
            v_encoded(v_idx + j) := v_b32(to_integer(unsigned(v_d40((8 - j) * 5 - 1 downto (7 - j) * 5))));
          end loop;
          for j in 2 to 7 loop
            v_encoded(v_idx + j) := v_b32(32);
          end loop;
          v_idx := v_idx + 8;
        elsif v_dlen mod 5 = 2 then
          v_d40(39 downto 32) := data(data'low + v_grps * 5);
          v_d40(31 downto 24) := data(data'low + v_grps * 5 + 1);
          for j in 0 to 3 loop
            v_encoded(v_idx + j) := v_b32(to_integer(unsigned(v_d40((8 - j) * 5 - 1 downto (7 - j) * 5))));
          end loop;
          for j in 4 to 7 loop
            v_encoded(v_idx + j) := v_b32(32);
          end loop;
          v_idx := v_idx + 8;
        elsif v_dlen mod 5 = 3 then
          v_d40(39 downto 32) := data(data'low + v_grps * 5);
          v_d40(31 downto 24) := data(data'low + v_grps * 5 + 1);
          v_d40(23 downto 16) := data(data'low + v_grps * 5 + 2);
          for j in 0 to 4 loop
            v_encoded(v_idx + j) := v_b32(to_integer(unsigned(v_d40((8 - j) * 5 - 1 downto (7 - j) * 5))));
          end loop;
          for j in 5 to 7 loop
            v_encoded(v_idx + j) := v_b32(32);
          end loop;
          v_idx := v_idx + 8;
        elsif v_dlen mod 5 = 4 then
          v_d40(39 downto 32) := data(data'low + v_grps * 5);
          v_d40(31 downto 24) := data(data'low + v_grps * 5 + 1);
          v_d40(23 downto 16) := data(data'low + v_grps * 5 + 2);
          v_d40(15 downto 8)  := data(data'low + v_grps * 5 + 3);
          for j in 0 to 6 loop
            v_encoded(v_idx + j) := v_b32(to_integer(unsigned(v_d40((8 - j) * 5 - 1 downto (7 - j) * 5))));
          end loop;
          for j in 7 to 7 loop
            v_encoded(v_idx + j) := v_b32(32);
          end loop;
          v_idx := v_idx + 8;
        end if;
      when BASE16 =>
        for i in 0 to v_dlen - 1 loop
          v_encoded(v_idx)     := C_BASE16(to_integer(unsigned(data(data'low + i)(7 downto 4))));
          v_encoded(v_idx + 1) := C_BASE16(to_integer(unsigned(data(data'low + i)(3 downto 0))));
          v_idx                := v_idx + 2;
        end loop;
    end case;
    return v_encoded(0 to v_idx - 1);
  end function f_base_enc;

  -------------------------------------------------------------------------------
  --! \brief Get base encoded data length
  --! \param data     Data array (8bit)
  --! \param alphabet Alphabet to use
  --! \return         Encoded data length
  --!
  --! Get length of encoded data after applying RFC 4648 with the selected alphabet.
  --!
  --! **Example use**
  --! ~~~
  --! v_len := f_base_enc_len(data_8bit, BASE64);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_base_enc_len(data     : t_slv_arr;
                          alphabet : t_base_alphabet)
    return natural is
    variable v_length : natural;
    variable v_alen   : natural;
    variable v_rem    : natural;
    variable v_dlen   : natural := data'length;
  begin
    assert data'ascending report "f_base_enc_len: data array must be ascending" severity C_SEVERITY;
    assert data(data'low)'length = 8 report "f_base_enc_len: data must be 8bit" severity C_SEVERITY;

    case alphabet is
      when BASE64 | BASE64_SAFE =>
        v_rem := v_dlen mod 3;
        if v_rem = 0 then
          v_length := (v_dlen / 3) * 4;
        else
          v_length := (1 + (v_dlen / 3)) * 4;
        end if;
      when BASE32 | BASE32HEX =>
        v_rem := v_dlen mod 5;
        if v_rem = 0 then
          v_length := (v_dlen / 5) * 8;
        else
          v_length := (1 + (v_dlen / 5)) * 8;
        end if;
      when BASE16 =>
        v_length := 2 * v_dlen;
    end case;
    return v_length;
  end function f_base_enc_len;

  -------------------------------------------------------------------------------
  --! \brief Base decode data
  --! \param data     Data array (8bit)
  --! \param alphabet Alphabet to use
  --! \return         Decoded data
  --!
  --! Decode data according to RFC 4648 with the selected alphabet.
  --!
  --! **Example use**
  --! ~~~
  --! decoded_data := f_base_dec(data_8bit, BASE64);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_base_dec(data     : t_slv_arr;
                      alphabet : t_base_alphabet)
    return t_slv_arr is
    variable v_b64     : t_slv_arr(0 to 64)(7 downto 0);
    variable v_b32     : t_slv_arr(0 to 32)(7 downto 0);
    variable v_decoded : t_slv_arr(0 to data'length)(7 downto 0);
    variable v_idx     : natural := 0;
    variable v_dlen    : natural := data'length;
    variable v_token   : t_slv_arr(0 to 0)(7 downto 0);
    variable v_key     : integer;
    variable v_d24     : std_logic_vector(23 downto 0);
    variable v_d40     : std_logic_vector(39 downto 0);
    variable v_grps    : natural;
    variable v_pads    : natural := 0;
  begin
    assert data'ascending report "f_base_dec: data array must be ascending" severity C_SEVERITY;
    assert data(data'low)'length = 8 report "f_base_dec: data must be 8bit" severity C_SEVERITY;

    case alphabet is
      when BASE64 | BASE64_SAFE =>
        assert v_dlen mod 4 = 0 report "f_base_dec: data length must be factor of 4 for base64 decoding" severity C_SEVERITY;
        if alphabet = BASE64 then
          v_b64 := C_BASE64;
        else
          v_b64 := C_BASE64_SAFE;
        end if;
        v_grps := v_dlen / 4;
        for i in 0 to v_grps - 1 loop
          for j in 0 to 3 loop
            v_token(0) := data(data'low + i * 4 + j);
            v_key      := f_search(v_b64, v_token);
            if v_key < 64 then
              v_d24((4 - j) * 6 - 1 downto (3 - j) * 6) := std_logic_vector(to_unsigned(v_key, 6));
            else
              v_d24((4 - j) * 6 - 1 downto (3 - j) * 6) := "000000";
              v_pads                                    := v_pads + 1;
            end if;
          end loop;
          v_decoded(v_idx)     := v_d24(23 downto 16);
          v_decoded(v_idx + 1) := v_d24(15 downto 8);
          v_decoded(v_idx + 2) := v_d24(7 downto 0);
          v_idx                := v_idx + 3;
        end loop;
        v_idx := v_idx - v_pads;
      when BASE32 | BASE32HEX =>
        assert v_dlen mod 8 = 0 report "f_base_dec: data length must be factor of 8 for base32 decoding" severity C_SEVERITY;
        if alphabet = BASE32 then
          v_b32 := C_BASE32;
        else
          v_b32 := C_BASE32_HEX;
        end if;
        v_grps := v_dlen / 8;
        for i in 0 to v_grps - 1 loop
          for j in 0 to 7 loop
            v_token(0) := data(data'low + i * 8 + j);
            v_key      := f_search(v_b32, v_token);
            if v_key < 32 then
              v_d40((8 - j) * 5 - 1 downto (7 - j) * 5) := std_logic_vector(to_unsigned(v_key, 5));
            else
              v_d40((8 - j) * 5 - 1 downto (7 - j) * 5) := "00000";
              v_pads                                    := v_pads + 1;
            end if;
          end loop;
          v_decoded(v_idx)     := v_d40(39 downto 32);
          v_decoded(v_idx + 1) := v_d40(31 downto 24);
          v_decoded(v_idx + 2) := v_d40(23 downto 16);
          v_decoded(v_idx + 3) := v_d40(15 downto 8);
          v_decoded(v_idx + 4) := v_d40(7 downto 0);
          v_idx                := v_idx + 5;
        end loop;
        if v_pads = 6 then
          v_idx := v_idx - 4;
        elsif v_pads = 4 then
          v_idx := v_idx - 3;
        elsif v_pads = 3 then
          v_idx := v_idx - 2;
        elsif v_pads = 1 then
          v_idx := v_idx - 1;
        end if;
      when BASE16 =>
        assert v_dlen mod 2 = 0 report "f_base_dec: data length must be factor of 2 for base16 decoding" severity C_SEVERITY;
        v_grps := v_dlen / 2;
        for i in 0 to v_grps - 1 loop
          for j in 0 to 1 loop
            v_token(0) := data(data'low + i * 2 + j);
            v_key      := f_search(C_BASE16, v_token);
            if v_key < 16 then
              v_decoded(v_idx + j)((2 - j) * 4 - 1 downto (1 - j) * 4) := std_logic_vector(to_unsigned(v_key, 4));
            else
              v_decoded(v_idx + j)((2 - j) * 4 - 1 downto (1 - j) * 4) := "0000";
            end if;
          end loop;
          v_idx := v_idx + 2;
        end loop;
    end case;
    return v_decoded(0 to v_idx - 1);
  end function f_base_dec;

  -------------------------------------------------------------------------------
  --! \brief Get base decoded data length
  --! \param data     Data array (8bit)
  --! \param alphabet Alphabet to use
  --! \return         Decoded data length
  --!
  --! Get length of decoded data after applying RFC 4648 with the selected alphabet.
  --!
  --! **Example use**
  --! ~~~
  --! v_len := f_base_dec_len(data_8bit, BASE32HEX);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_base_dec_len(data     : t_slv_arr;
                          alphabet : t_base_alphabet)
    return natural is
    variable v_length : natural;
    variable v_dlen   : natural := data'length;
  begin
    assert data'ascending report "f_base_dec: data array must be ascending" severity C_SEVERITY;
    assert data(data'low)'length = 8 report "f_base_dec: data must be 8bit" severity C_SEVERITY;

    case alphabet is
      when BASE64 | BASE64_SAFE =>
        assert v_dlen mod 4 = 0 report "f_base_dec: data length must be factor of 4 for base64 decoding" severity C_SEVERITY;
        v_length := (v_dlen / 4) * 3;
        if data(data'high) = C_BASE64(64) then
          v_length := v_length - 1;
        end if;
        if data(data'high - 1) = C_BASE64(64) then
          v_length := v_length - 1;
        end if;
      when BASE32 | BASE32HEX =>
        assert v_dlen mod 8 = 0 report "f_base_dec: data length must be factor of 8 for base32 decoding" severity C_SEVERITY;
        v_length := (v_dlen / 8) * 5;
        if data(data'high - 5 to data'high) = (C_PAD, C_PAD, C_PAD, C_PAD, C_PAD, C_PAD) then
          v_length := v_length - 4;
        elsif data(data'high - 3 to data'high) = (C_PAD, C_PAD, C_PAD, C_PAD) then
          v_length := v_length - 3;
        elsif data(data'high - 2 to data'high) = (C_PAD, C_PAD, C_PAD) then
          v_length := v_length - 2;
        elsif data(data'high) = C_BASE32(32) then
          v_length := v_length - 1;
        end if;
      when BASE16 =>
        assert v_dlen mod 2 = 0 report "f_base_dec: data length must be factor of 2 for base16 decoding" severity C_SEVERITY;
        v_length := v_dlen / 2;
    end case;
    return v_length;
  end function f_base_dec_len;

end package body nw_base_pkg;
