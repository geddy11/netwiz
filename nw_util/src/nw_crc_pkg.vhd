-------------------------------------------------------------------------------
-- Title      : Network Wizard Checksum and CRC package
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: 
--!\file
--!\brief Checksum and CRC functions
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

--! \page nw_crc Checksum and CRC
--! \tableofcontents
--! \section crc CRC & Checksum
--! This library provides functions for calculation of checksums and CRC. 
--!
--! \subsection crc_subsec1 Functionality
--! \li Checksum of any data width, with or without carry
--! \li CRC from any polynomial
--!
--! \n More details in \ref nw_crc_pkg
--! \subsection crc_subsec2 Example use
--! Include the libraries:
--! ~~~
--! library nw_util;
--! context nw_util.nw_util_context;
--! ~~~
--! Calculation of internet checksum (IPv4 header checksum):
--! ~~~
--! v_chksum16 := not f_gen_chksum(array_16bit, 16); 
--! ~~~
--! Calculation of 8bit checksum (no carry):
--! ~~~
--! v_chksum8 := not f_gen_chksum(array_8bit, 8, False); 
--! ~~~
--! Calculation of ethernet CRC - here we need to postprocess the CRC by bit-reversing, swap endianess and inverting:
--! ~~~
--! v_crc_32   := not f_swap_endian(f_bitflip(f_gen_crc(C_ETH_CRC32, array_8bit, x"ffffffff", C_LSB_FIRST)));
--! ~~~
--! See further examples in the test bench nw_util_tb.vhd.
package nw_crc_pkg is

  -------------------------------------------------------------------------------
  -- Functions
  -- @cond functions
  -------------------------------------------------------------------------------
  function f_gen_crc(poly      : std_logic_vector;
                     data      : t_slv_arr;
                     init      : std_logic_vector;
                     msb_first : boolean := C_MSB_FIRST) return std_logic_vector;

  function f_gen_chksum(data: t_slv_arr;
                        chksum_width: positive;
                        use_carry: boolean := True) return std_logic_vector;
  -- @endcond

end package nw_crc_pkg;

package body nw_crc_pkg is

  -------------------------------------------------------------------------------
  --! \brief Calculate CRC
  --! \param poly        CRC polynomial to use (3-bit or longer)
  --! \param data        Data array 
  --! \param init        CRC init value (same width as poly)
  --! \param msb_first   Extract most significant bits first if True (default), least significant bits if False
  --! \return            CRC
  --!
  --! Calculate CRC checksum of data array. 
  --!
  --! **Example use**
  --! ~~~
  --! array_8bit := (x"11", x"22", x"33", x"44", x"55", x"66", x"77");
  --! v_crc_32   := f_gen_crc(C_ETH_CRC32, array_8bit, x"ffffffff"); -- v_crc_32 is now x"97aee1d3"
  --! ~~~
  -------------------------------------------------------------------------------
  function f_gen_crc(poly      : std_logic_vector;
                     data      : t_slv_arr;
                     init      : std_logic_vector;
                     msb_first : boolean := C_MSB_FIRST)
    return std_logic_vector is
    constant C_MSB      : natural                               := poly'length - 1;
    constant C_TAPS     : std_logic_vector(C_MSB downto 0)      := poly;
    constant C_INIT_MSB : natural                               := init'length - 1;
    constant C_INIT     : std_logic_vector(C_INIT_MSB downto 0) := init;
    constant C_DW       : natural                               := data(data'low)'length;

    variable v_crca : t_slv_arr(1 to C_DW)(C_MSB downto 0);
    variable v_da   : t_slv_arr(1 to C_DW)(C_MSB downto 0);
    variable v_ma   : t_slv_arr(1 to C_DW)(C_MSB downto 0);

    variable v_crc, v_fb : std_logic_vector(C_MSB downto 0);

    variable v_din, v_crc_msb : std_logic_vector(C_MSB downto 1);
    variable v_data_1bit      : t_slv_arr(0 to C_DW * data'length - 1)(0 downto 0);
  begin
    assert poly'length > 2 report "f_gen_crc: polynomial must be at least three-bit" severity C_SEVERITY;
    assert poly'length = init'length report "f_gen_crc: init value must be same width as polynomial" severity C_SEVERITY;

    v_crc       := C_INIT;
    v_data_1bit := f_repack(data, 1, msb_first);
    for d in 0 to v_data_1bit'high loop
      for i in 1 to C_MSB loop
        v_din(i)     := v_data_1bit(d)(0);
        v_crc_msb(i) := v_crc(C_MSB);
      end loop;
      v_fb(0)              := v_data_1bit(d)(0) xor v_crc(C_MSB);
      v_fb(C_MSB downto 1) := v_crc(C_MSB - 1 downto 0) xor ((v_din xor v_crc_msb) and C_TAPS(C_MSB downto 1));
      v_crc                := v_fb;
    end loop;
    return v_crc;
  end function f_gen_crc;

  -------------------------------------------------------------------------------
  --! \brief Calculate sum-of-words checksum
  --! \param data         Data array 
  --! \param chksum_width Checksum width
  --! \param use_carry    Add carry to checksum (default True)
  --! \return             Checksum
  --!
  --! Calculate sum-of-words checksum of data array. The data array should have the same width as the checksum, 
  --! which is accomplished with e.g. f_repack().
  --!
  --! **Example use**
  --! ~~~
  --! array_16bit := (x"4500", x"0073", x"0000", x"4000", x"4011", x"0000", x"c0a8", x"0001", x"c0a8", x"00c7"); -- IPv4 Header
  --! v_chksum    := not f_gen_chksum(array_16bit, 16); -- v_chksum is now x"b861", which is the IPv4 header checksum
  --! ~~~
  -------------------------------------------------------------------------------
  function f_gen_chksum(data: t_slv_arr;
                        chksum_width: positive;
                        use_carry: boolean := True) 
    return std_logic_vector is
      variable v_chksum : unsigned(2 * chksum_width - 1 downto 0) := (others => '0');
      variable v_tmp : unsigned(2 * chksum_width - 1 downto 0) := (others => '0');
  begin
    assert data(data'low)'length = chksum_width report "f_gen_chksum: data array word width must equal chksum_width" severity C_SEVERITY;
    assert data'ascending report "f_gen_chksum: data array must be ascending" severity C_SEVERITY;

    for i in data'low to data'high loop
      v_tmp(chksum_width - 1 downto 0) := unsigned(data(i));
      v_chksum := v_chksum + v_tmp;
      if use_carry then
        v_chksum(chksum_width - 1 downto 0) := v_chksum(chksum_width - 1 downto 0) + v_chksum(2 * chksum_width - 1 downto chksum_width);
        v_chksum(2 * chksum_width - 1 downto chksum_width) := (others => '0');
      else
        v_chksum(2 * chksum_width - 1 downto chksum_width) := (others => '0');
      end if;
    end loop;

    return std_logic_vector(v_chksum(chksum_width - 1 downto 0));
  end function f_gen_chksum;

end package body nw_crc_pkg;
