-------------------------------------------------------------------------------
-- Title      : Network Wizard RTP package
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: 
--!\file
--!\brief RTP library.
-------------------------------------------------------------------------------
-- MIT License
--
-- Copyright (c) 2026 Geir Drange
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
library nw_util;
context nw_util.nw_util_context;
--! @endcond

--! \page nw_rtp RTP library
--! \tableofcontents
--! \section rtp RTP (Real-Time Transfer Protocol)
--! The RTP library provides functions for creating and manipulation RTP packets. 
--! \subsection rtp_subsec1 Functionality
--! \li Create RTP packets of any length
--! \li Create and extract RTP headers
--!
--! \n\n More details in \ref nw_rtp_pkg
--! \subsection rtp_subsec2 Example use
--! Include the libraries:
--! ```vhdl
--! library nw_util;
--! context nw_util.nw_util_context;
--! library nw_rtp;
--! ```
--! Assume the variable \c v_payload contains the RTP payload. The variables are defined:
--! ```vhdl
--! variable v_header  : t_rtp_header; -- RTP header record
--! variable v_rtp_pkt : t_slv_arr(0 to 1500)(7 downto 0); -- byte array
--! variable v_len     : natural;
--! ```
--! First setup the header, then calculate the total RTP packet length before creating the packet. 
--! ```vhdl
--! v_header                  := C_DEFAULT_RTP_HEADER; -- copy default header
--! v_header.cc               := x"0010"; -- two CSRC identifiers
--! v_header.csrc(0)          := x"10005678"; -- CSRC #1
--! v_header.csrc(1)          := x"1000abcd"; -- CSRC #2
--! v_header.payload_type     := "0100011"; -- payload type
--! v_len                     := f_rtp_create_pkt_len(v_header, v_payload); -- calculate total packet length
--! v_rtp_pkt(0 to v_len - 1) := f_rtp_create_pkt(v_header, v_payload); -- create the packet
--! ```
--! The variable \c v_rtp_pkt is an 8-bit array. This can of course be rearranged to any word width with \c f_repack .
--! ```vhdl
--! v_rtp_pkt_64 := f_repack(v_rtp_pkt, 64, C_MSB_FIRST); -- repack to 64bit words (padded with zeros if required)
--! ```
--! See further examples in the test bench nw_rtp_tb.vhd.
package nw_rtp_pkg is

  -------------------------------------------------------------------------------
  -- Records
  -------------------------------------------------------------------------------
  type t_rtp_header is record
    version      : std_logic_vector(1 downto 0);  --! RTP version (always 2)
    padding      : std_logic;  --! Padding bit
    extension    : std_logic;  --! Extension bit
    cc           : std_logic_vector(3 downto 0);  --! Number of CSRC identifiers
    marker       : std_logic;  --! Marker bit
    payload_type : std_logic_vector(6 downto 0);  --! Payload type
    sequence_id  : std_logic_vector(15 downto 0);  --! Sequence number
    timestamp    : std_logic_vector(31 downto 0);  --! Timestamp
    ssrc         : std_logic_vector(31 downto 0);  --! Synchronization source
    csrc         : t_slv_arr(0 to 14)(31 downto 0);  --! Contributing sources
  end record t_rtp_header;

  -------------------------------------------------------------------------------
  -- Constants
  --!@cond functions
  -------------------------------------------------------------------------------
  constant C_DEFAULT_RTP_HEADER : t_rtp_header := (version      => "10",
                                                   padding      => '0',
                                                   extension    => '0',
                                                   cc           => "0000",
                                                   marker       => '0',
                                                   payload_type => "0001010",
                                                   sequence_id  => x"1234",
                                                   timestamp    => x"4ec8abcd",
                                                   ssrc         => x"f3c2c8ed",
                                                   csrc         => (x"70e06199", x"c3be38fe", x"ce875c15", x"0f558702", x"bf75a086",
                                                                    x"10b210d7", x"d10fb8d6", x"dcd65f72", x"ced0cd51", x"f5ff7670",
                                                                    x"9048f33b", x"62c385cf", x"7958e223", x"d6a18ea9", x"9ad89114"));
  --! @endcond

  -------------------------------------------------------------------------------
  -- Functions
  --!@cond functions
  -------------------------------------------------------------------------------
  function f_rtp_create_pkt(rtp_header : t_rtp_header;
                            payload    : t_slv_arr) return t_slv_arr;

  function f_rtp_create_pkt_len(rtp_header : t_rtp_header;
                                payload    : t_slv_arr) return natural;

  function f_rtp_get_header(rtp_pkt : t_slv_arr) return t_rtp_header;

  function f_rtp_get_payload(rtp_pkt : t_slv_arr) return t_slv_arr;

  function f_rtp_get_payload_len(rtp_pkt : t_slv_arr) return natural;
  --! @endcond

end package nw_rtp_pkg;

package body nw_rtp_pkg is

  -------------------------------------------------------------------------------
  -- Create RTP packet (internal)
  --@cond functions
  -------------------------------------------------------------------------------
  function f_rtp_create_pkt(rtp_header : t_rtp_header;
                            payload    : t_slv_arr;
                            get_length : boolean := false)
    return t_slv_arr is
    variable v_len     : natural                               := 72 + payload'length;
    variable v_len_slv : std_logic_vector(15 downto 0)         := std_logic_vector(to_unsigned(v_len, 16));
    variable v_data    : t_slv_arr(0 to v_len - 1)(7 downto 0) := (others => x"00");
    variable v_length  : t_slv_arr(0 to 0)(30 downto 0);
  begin
    assert payload'ascending report "f_rtp_create_pkt: payload array must be ascending" severity C_SEVERITY;
    assert payload(payload'low)'length = 8 report "f_rtp_create_pkt: payload must be 8bit" severity C_SEVERITY;

    -- header
    v_data(0) := rtp_header.version & rtp_header.padding & rtp_header.extension & rtp_header.cc;
    v_data(1) := rtp_header.marker & rtp_header.payload_type;
    v_data(2) := rtp_header.sequence_id(15 downto 8);
    v_data(3) := rtp_header.sequence_id(7 downto 0);
    v_data(4) := rtp_header.timestamp(31 downto 24);
    v_data(5) := rtp_header.timestamp(23 downto 16);
    v_data(6) := rtp_header.timestamp(15 downto 8);
    v_data(7) := rtp_header.timestamp(7 downto 0);
    v_data(8) := rtp_header.ssrc(31 downto 24);
    v_data(9) := rtp_header.ssrc(23 downto 16);
    v_data(10) := rtp_header.ssrc(15 downto 8);
    v_data(11) := rtp_header.ssrc(7 downto 0);
    for i in 0 to to_integer(unsigned(rtp_header.cc)) loop
      v_data(12 + i * 4) := rtp_header.csrc(i)(31 downto 24);
      v_data(13 + i* 4)  := rtp_header.csrc(i)(23 downto 16);
      v_data(14 + i * 4) := rtp_header.csrc(i)(15 downto 8);
      v_data(15 + i * 4) := rtp_header.csrc(i)(7 downto 0);
    end loop;
    -- payload
    for i in 0 to payload'length - 1 loop
      v_data(12 + 4 * to_integer(unsigned(rtp_header.cc)) + i) := payload(payload'low + i);
    end loop;
    v_len := 4 * to_integer(unsigned(rtp_header.cc)) + 12 + payload'length;
    if get_length then
      v_length(0) := std_logic_vector(to_unsigned(v_len, 31));
      return v_length;
    else
      return v_data(0 to v_len - 1);
    end if;
  end function f_rtp_create_pkt;
  -- @endcond

  -------------------------------------------------------------------------------
  --! \brief Create RTP packet
  --! \param rtp_header RTP header
  --! \param payload    RTP payload
  --! \return           RTP packet (8bit array) or length of RTP packet
  --!
  --! Create RTP packet. Payload must be 8bit data array. 
  --!
  --! **Example use**
  --! ```vhdl
  --! v_rtp_header  := C_DEFAULT_RTP_HEADER;
  --! v_packet_8bit := f_rtp_create_pkt(v_rtp_header, payload); 
  --! ```
  -------------------------------------------------------------------------------
  function f_rtp_create_pkt(rtp_header : t_rtp_header;
                            payload    : t_slv_arr)
    return t_slv_arr is
  begin
    return f_rtp_create_pkt(rtp_header, payload, false);
  end function f_rtp_create_pkt;

  -------------------------------------------------------------------------------
  --! \brief Return length of RTP packet.
  --! \param rtp_header RTP header
  --! \param payload    RTP payload
  --! \return           Length of RTP packet
  --!
  --! Return the length of the created RTP packet.
  --!
  --! **Example use**
  --! ```vhdl
  --! v_len                      := f_rtp_create_pkt_len(v_rtp_header, payload); 
  --! v_pkt_8bit(0 to v_len - 1) := f_rtp_create_pkt(v_rtp_header, payload);
  --! ```
  -------------------------------------------------------------------------------
  function f_rtp_create_pkt_len(rtp_header : t_rtp_header;
                                payload    : t_slv_arr)
    return natural is
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    v_length := f_rtp_create_pkt(rtp_header, payload, true);
    return to_integer(unsigned(v_length(0)));
  end function f_rtp_create_pkt_len;

  -------------------------------------------------------------------------------
  --! \brief Get RTP header
  --! \param rtp_pkt RTP packet (8bit)
  --! \return        RTP header
  --!
  --! Extract RTP header from RTP packet. 
  --!
  --! **Example use**
  --! ```vhdl
  --! v_rtp_header := f_rtp_get_header(data_array_8bit); 
  --! ```
  -------------------------------------------------------------------------------
  function f_rtp_get_header(rtp_pkt : t_slv_arr)
    return t_rtp_header is
    variable v_header : t_rtp_header;
  begin
    assert rtp_pkt'ascending report "f_rtp_get_header: packet array must be ascending" severity C_SEVERITY;
    assert rtp_pkt(rtp_pkt'low)'length = 8 report "f_rtp_get_header: packet array must be 8bit" severity C_SEVERITY;
    assert rtp_pkt'length >= 12 report "f_rtp_get_header: packet array must be at least 12 byte" severity C_SEVERITY;

    v_header.cc           := rtp_pkt(0)(3 downto 0);
    v_header.extension    := rtp_pkt(0)(4);
    v_header.padding      := rtp_pkt(0)(5);
    v_header.version      := rtp_pkt(0)(7 downto 6);
    v_header.payload_type := rtp_pkt(1)(6 downto 0);
    v_header.marker       := rtp_pkt(1)(7);
    v_header.sequence_id  := rtp_pkt(2) & rtp_pkt(3);
    v_header.timestamp    := rtp_pkt(4) & rtp_pkt(5) & rtp_pkt(6) & rtp_pkt(7);
    v_header.ssrc         := rtp_pkt(8) & rtp_pkt(9) & rtp_pkt(10) & rtp_pkt(11);
    if v_header.cc /= "0000" then
      for i in 0 to to_integer(unsigned(v_header.cc)) - 1 loop
        v_header.csrc(i) := rtp_pkt(12 + 4 * i) & rtp_pkt(13 + 4 * i) & rtp_pkt(14 + 4 * i) & rtp_pkt(15 + 4 * i);
      end loop;
    else
      for i in 0 to 14 loop
        v_header.csrc(i) := x"00000000";
      end loop;
    end if;
    return v_header;
  end function f_rtp_get_header;

  -------------------------------------------------------------------------------
  -- Get RTP payload (internal)
  --@cond functions
  -------------------------------------------------------------------------------
  function f_rtp_get_payload(rtp_pkt    : t_slv_arr;
                             get_length : boolean := false)
    return t_slv_arr is
    variable v_header : t_rtp_header;
    variable v_len    : natural;
    variable v_hlen   : natural;
    variable v_data   : t_slv_arr(0 to rtp_pkt'length - 1)(7 downto 0);
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    assert rtp_pkt'ascending report "f_rtp_get_payload: packet array must be ascending" severity C_SEVERITY;
    assert rtp_pkt(rtp_pkt'low)'length = 8 report "f_rtp_get_payload: packet array must be 8bit" severity C_SEVERITY;
    assert rtp_pkt'length >= 12 report "f_rtp_get_payload: rtp packet must be at least 12 bytes" severity C_SEVERITY;

    -- extract header
    v_header               := f_rtp_get_header(rtp_pkt);
    -- calculate payload length
    v_hlen                 := 12 + 4 * to_integer(unsigned(v_header.cc));
    v_len                  := rtp_pkt'length - v_hlen;
    v_data(0 to v_len - 1) := rtp_pkt(v_hlen to v_hlen + v_len - 1);
    if get_length then                  -- return length of payload only
      v_length(0) := std_logic_vector(to_unsigned(v_len, 31));
      return v_length;
    end if;
    return v_data(0 to v_len - 1);
  end function f_rtp_get_payload;
  -- @endcond

  -------------------------------------------------------------------------------
  --! \brief Get RTP payload
  --! \param rtp_pkt    RTP packet (8bit)
  --! \return           t_slv_arr
  --!
  --! Extract RTP payload from RTP packet (including extension header and padding if present). 
  --!
  --! **Example use**
  --! ```vhdl
  --! v_len                     := f_rtp_get_payload_len(data_array_8bit); 
  --! v_payload(0 to v_len - 1) := f_rtp_get_payload(data_array_8bit); 
  --! ```
  -------------------------------------------------------------------------------
  function f_rtp_get_payload(rtp_pkt : t_slv_arr)
    return t_slv_arr is
  begin
    return f_rtp_get_payload(rtp_pkt, false);
  end function f_rtp_get_payload;

  -------------------------------------------------------------------------------
  --! \brief Get RTP payload length
  --! \param rtp_pkt   RTP packet (8bit)
  --! \return          RTP payload length
  --!
  --! Get RTP payload length from RTP packet (including extension header and padding if present). 
  --!
  --! **Example use**
  --! ```vhdl
  --! v_len := f_rtp_get_payload_len(data_array_8bit); -- determine size of payload
  --! ```
  -------------------------------------------------------------------------------
  function f_rtp_get_payload_len(rtp_pkt : t_slv_arr)
    return natural is
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    v_length := f_rtp_get_payload(rtp_pkt, true);
    return to_integer(unsigned(v_length(0)));
  end function f_rtp_get_payload_len;

end package body nw_rtp_pkg;
