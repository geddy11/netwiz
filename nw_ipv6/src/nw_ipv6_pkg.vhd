-------------------------------------------------------------------------------
-- Title      : Network Wizard IPv6 package
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: 
--!\file
--!\brief IPv6 library.
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
library nw_util;
context nw_util.nw_util_context;
library nw_ipv4;
use nw_ipv4.ip_protocols_pkg.all;

--use work.ip_protocols_pkg.all;
--! @endcond

--! \page nw_ipv6 IPv6 library
--! \tableofcontents
--! \section IPv6
--! The IPv6 library provides functions for creating and manipulation IPv6 packets.
--! \subsection ipv6_subsec1 Functionality
--! \li Create IPv6 packets of any length
--! \li Create and extract IPv6 headers including extension headers
--! \li Verify checksum of IPv6 packets
--!
--! Other libraries in IPv6 are: 
--! \li \subpage nw_udpv6
--! \li \subpage nw_icmpv6
--! \li \subpage nw_tcpv6
--!
--! \n More details in \ref nw_ipv6_pkg
--! \subsection ipv6_subsec2 Example use
--! Include the libraries:
--! ~~~
--! library nw_util;
--! context nw_util.nw_util_context;
--! library nw_ipv6;
--! context nw_ipv6.nw_ipv6_context;
--! ~~~
--! Assume the variable \c v_payload contains the IPv6 payload, for example an UDP packet. The variables are defined:
--! ~~~
--! variable v_header   : t_ipv6_header; -- header record
--! variable v_ipv6_pkt : t_slv_arr(0 to 1500)(7 downto 0); -- byte array
--! variable v_len      : natural;
--! ~~~
--! First setup the header, then calculate the total IPv6 packet length before creating the packet.
--! ~~~
--! v_header                   := C_DEFAULT_IPV6_HEADER; -- copy default header
--! v_header.src_addr          := f_ipv6_addr_2_slv_arr("2102:ec7::2"); -- change source address
--! v_len                      := f_ipv6_create_pkt_len(v_header, v_payload); -- calculate total packet length
--! v_ipv6_pkt(0 to v_len - 1) := f_ipv6_create_pkt(v_header, v_payload); -- create the packet
--! ~~~
--! Extension headers are used by first defining a variable holding a list of extension headers, then adding individual extension
--! headers to this list.
--! ~~~
--! v_ext_header_list : t_ext_header_list := C_DEFAULT_EXT_HEADER_LIST; -- init the extension header list to empty
--! v_ext_header      : t_extension_header; -- extension header to be added to list
--! ~~~
--! Extension headers can added to the list in any order (note that RFC 2460 recommends a specific order).\n 
--! Add Hop-by-Hop Options Header:
--! ~~~
--! v_ext_header              := C_DEFAULT_EXT_HEADER; -- start with a default header
--! v_ext_header.header_type  := C_HOPOPT; -- Hop-by-Hop Options
--! v_ext_header.hdr_ext_len  := 1; -- 16byte total length
--! v_ext_header.data(0 to 1) := (x"01", x"0c"); -- PadN option
--! v_ext_header_list         := f_ipv6_add_ext_header(v_ext_header_list, v_ext_header); -- add header to list. Note that v_ext_header.next_header is updated here.
--! ~~~
--! Add Routing Header:
--! ~~~
--! v_ext_header               := C_DEFAULT_EXT_HEADER; -- start with a default header
--! v_ext_header.header_type   := C_IPV6_ROUTE; -- Routing Header
--! v_ext_header.routing_type  := x"00";  -- routing type 0
--! v_ext_header.segments_left := x"01";
--! v_ext_header.hdr_ext_len   := 1; -- 16byte total length
--! v_ext_header.data(0 to 7)  := f_ipv6_addr_2_slv_arr("4200:8a::44");
--! v_ext_header_list          := f_ipv6_add_ext_header(v_ext_header_list, v_ext_header); -- add header to list. 
--! ~~~
--! Add Fragment Header:
--! ~~~
--! v_ext_header                  := C_DEFAULT_EXT_HEADER; -- start with a default header
--! v_ext_header.header_type      := C_IPV6_FRAG; -- Fragment header
--! v_ext_header.framgment_offset := "0011001000000"; -- 13bit offset
--! v_ext_header.m_flag           := '0'; -- last fragment
--! v_ext_header.identification   := x"00000042"; 
--! v_ext_header.hdr_ext_len      := 0; -- 8byte total length
--! v_ext_header_list             := f_ipv6_add_ext_header(v_ext_header_list, v_ext_header); -- add header to list.
--! ~~~
--! Add Destination Options Header:
--! ~~~
--! v_ext_header              := C_DEFAULT_EXT_HEADER; -- start with a default header
--! v_ext_header.header_type  := C_IPV6_OPTS; -- Destination Options
--! v_ext_header.hdr_ext_len  := 0; -- 8byte total length
--! v_ext_header.data(0 to 3) := (x"01", x"02"); -- PadN option
--! v_ext_header_list         := f_ipv6_add_ext_header(v_ext_header_list, v_ext_header); -- add header to list.
--! ~~~
--! Add Authentication Header (RFC 2402):
--! ~~~
--! v_ext_header               := C_DEFAULT_EXT_HEADER; -- start with a default header
--! v_ext_header.header_type   := C_AH; -- Authentication Header
--! v_ext_header.hdr_ext_len   := 4; -- Note! Number of 4byte words minus 2
--! v_ext_header.spi           := x"12345678"; -- Security Parameters Index
--! v_ext_header.seq_no        := x"000000f4"; -- sequence number
--! v_ext_header.data(0 to 11) := f_gen_prbs(C_POLY_X16_X15_X13_X4_1, 8, 12); -- random payload
--! v_ext_header_list          := f_ipv6_add_ext_header(v_ext_header_list, v_ext_header); -- add header to list.
--! ~~~
--! Finally create the IPv6 packet with extension headers:
--! ~~~
--! v_len                      := f_ipv6_create_pkt_len(v_header, v_payload, v_ext_header_list); -- calculate total packet length
--! v_ipv6_pkt(0 to v_len - 1) := f_ipv6_create_pkt(v_header, v_payload, v_ext_header_list); -- create the packet
--! ~~~
--! See further examples in the test bench nw_ipv6_tb.vhd.
package nw_ipv6_pkg is

  -------------------------------------------------------------------------------
  -- IPv6 header (RFC-2460)
  -------------------------------------------------------------------------------
  type t_ipv6_header is record
    version        : std_logic_vector(3 downto 0);  --! Version
    traffic_class  : std_logic_vector(7 downto 0);  --! Traffic class
    flow_label     : std_logic_vector(19 downto 0);   --! Flow label
    payload_length : std_logic_vector(15 downto 0);   --! Payload length
    next_header    : std_logic_vector(7 downto 0);  --! Next header. Uses the same values as the IPv4 Protocol field
    hop_limit      : std_logic_vector(7 downto 0);  --! Hop limit
    src_addr       : t_slv_arr(0 to 15)(7 downto 0);  --! Source address
    dest_addr      : t_slv_arr(0 to 15)(7 downto 0);  --! Destination address
  end record t_ipv6_header;

  type t_extension_header is record
    header_type     : std_logic_vector(7 downto 0);  --! Extension header type
    next_header     : std_logic_vector(7 downto 0);  --! Next header. Uses the same values as the IPv4 Protocol field
    hdr_ext_len     : std_logic_vector(7 downto 0);  --! Length of the Hop-by-Hop Options header in 8-octet units, not including the first 8 octets.
    -- routing header fields
    routing_type    : std_logic_vector(7 downto 0);  --! 8-bit identifier of a particular Routing header variant.
    segments_left   : std_logic_vector(7 downto 0);  --! Number of route segments remaining
    r_reserved      : std_logic_vector(31 downto 0);  --! Reserved
    -- fragment header fields
    f_reserved      : std_logic_vector(7 downto 0);  --! Reserved
    fragment_offset : std_logic_vector(12 downto 0);  --! The offset, in 8-octet units, of the data following this header
    res             : std_logic_vector(1 downto 0);  --! Reserved field
    m_flag          : std_logic;  --! 1 = more fragments; 0 = last fragment.
    identification  : std_logic_vector(31 downto 0);  --! Identification
    -- authentication header field (RFC-2402)
    a_reserved      : std_logic_vector(15 downto 0);  --! Reserved
    spi             : std_logic_vector(31 downto 0);  --! Security Parameters Index
    seq_no          : std_logic_vector(31 downto 0);  --! Sequence number
    -- variable data field
    data            : t_slv_arr(0 to C_IPV6_MAX_EXT_HEADER_SIZE - 1)(7 downto 0);  --! Variable-length field, of format determined by the header type
    -- header total length (internal use)
    total_len       : natural;          -- total header length in bytes
  end record t_extension_header;

  type t_ext_header_arr is array(0 to C_IPV6_MAX_EXT_HEADERS - 1) of t_extension_header;

  type t_ext_header_list is record
    header_cnt : natural range 0 to C_IPV6_MAX_EXT_HEADERS;  --! Number of extension headers in record
    headers    : t_ext_header_arr;      --! Header array
  end record t_ext_header_list;

  -------------------------------------------------------------------------------
  -- Constants
  --! @cond constants
  -------------------------------------------------------------------------------
  constant C_DEFAULT_IPV6_HEADER : t_ipv6_header := (version        => x"6", traffic_class => x"00", flow_label => x"00000",
                                                     payload_length => x"0000", next_header => C_UDP, hop_limit => x"ff",
                                                     src_addr       => (others => x"00"), dest_addr => (others => x"00"));

  constant C_DEFAULT_EXT_HEADER : t_extension_header := (header_type  => x"ff", next_header => C_IPV6_NONXT, hdr_ext_len => x"00",
                                                         routing_type => x"00", segments_left => x"00", r_reserved => x"00000000",
                                                         f_reserved   => x"00", fragment_offset => (others => '0'), res => "00", m_flag => '0', identification => x"00000000",
                                                         a_reserved   => x"0000", spi => x"00000000", seq_no => x"00000000",
                                                         data         => (others => x"00"), total_len => 0);

  constant C_DEFAULT_EXT_HEADER_LIST : t_ext_header_list := (header_cnt => 0,
                                                             headers    => (others => C_DEFAULT_EXT_HEADER));
  --! @endcond

  -------------------------------------------------------------------------------
  -- Functions
  --!@cond functions
  -------------------------------------------------------------------------------
  function f_ipv6_create_pkt(header          : t_ipv6_header;
                             payload         : t_slv_arr;
                             ext_header_list : t_ext_header_list := C_DEFAULT_EXT_HEADER_LIST) return t_slv_arr;

  function f_ipv6_create_pkt_len(header          : t_ipv6_header;
                                 payload         : t_slv_arr;
                                 ext_header_list : t_ext_header_list := C_DEFAULT_EXT_HEADER_LIST) return natural;

  function f_ipv6_add_ext_header(ext_header_list : t_ext_header_list;
                                 ext_header      : t_extension_header) return t_ext_header_list;

  function f_ipv6_get_header(ipv6_pkt : t_slv_arr) return t_ipv6_header;

  function f_ipv6_get_ext_headers(ipv6_pkt : t_slv_arr) return t_ext_header_list;

  function f_ipv6_get_payload(ipv6_pkt : t_slv_arr) return t_slv_arr;

  function f_ipv6_get_payload_len(ipv6_pkt : t_slv_arr) return natural;

  function f_ipv6_addr_2_slv_arr(addr : string) return t_slv_arr;
  --!@endcond

end package nw_ipv6_pkg;

package body nw_ipv6_pkg is

  -------------------------------------------------------------------------------
  -- Create IPv6 packet (internal)
  --!@cond functions
  -------------------------------------------------------------------------------
  function f_ipv6_create_pkt(header          : t_ipv6_header;
                             payload         : t_slv_arr;
                             ext_header_list : t_ext_header_list := C_DEFAULT_EXT_HEADER_LIST;
                             get_length      : boolean           := false)
    return t_slv_arr is
    variable v_hlen        : natural := 40;
    variable v_ext_len_max : natural := C_IPV6_MAX_EXT_HEADERS * C_IPV6_MAX_EXT_HEADER_SIZE;
    variable v_maxlen      : natural := v_hlen + v_ext_len_max + payload'length;
    variable v_data        : t_slv_arr(0 to v_maxlen - 1)(7 downto 0);
    variable v_length      : t_slv_arr(0 to 0)(30 downto 0);
    variable v_len         : natural;
    variable v_last_header : std_logic_vector(7 downto 0);
    variable v_next_header : std_logic_vector(7 downto 0);
    variable v_extlen      : natural;
  begin
    assert payload'ascending report "f_ipv6_create_pkt: payload array must be ascending" severity C_SEVERITY;
    assert payload(payload'low)'length = 8 report "f_ipv6_create_pkt: payload must be 8bit" severity C_SEVERITY;

    -- insert header
    v_len         := 40;
    v_data(0)     := header.version & header.traffic_class(7 downto 4);
    v_data(1)     := header.traffic_class(3 downto 0) & header.flow_label(19 downto 16);
    v_data(2)     := header.flow_label(15 downto 8);
    v_data(3)     := header.flow_label(7 downto 0);
    v_data(4)     := header.payload_length(15 downto 8);
    v_data(5)     := header.payload_length(7 downto 0);
    v_data(6)     := header.next_header;
    v_last_header := header.next_header;
    v_data(7)     := header.hop_limit;
    for i in 0 to 15 loop
      v_data(8 + i)  := header.src_addr(i);
      v_data(24 + i) := header.dest_addr(i);
    end loop;
    -- add extension headers
    if ext_header_list.header_cnt > 0 then
      for i in 0 to ext_header_list.header_cnt - 1 loop
        -- next header
        if i = ext_header_list.header_cnt - 1 then
          v_next_header := v_last_header;
        else
          v_next_header := ext_header_list.headers(i).next_header;
        end if;
        -- header data
        case ext_header_list.headers(i).header_type is
          when C_HOPOPT | C_IPV6_OPTS =>  -- Hop-by-Hop Options | Destination Options 
            v_data(v_len)                  := v_next_header;
            v_data(v_len + 1)              := ext_header_list.headers(i).hdr_ext_len;
            v_data(v_len + 2 to v_len + 7) := ext_header_list.headers(i).data(0 to 5);
            v_extlen                       := to_integer(unsigned(ext_header_list.headers(i).hdr_ext_len));
            if v_extlen > 0 then
              for j in 0 to v_extlen * 8 - 1 loop
                v_data(v_len + 8 + j) := ext_header_list.headers(i).data(5 + j);
              end loop;
            end if;
            v_len := v_len + 8 * (v_extlen + 1);
          when C_IPV6_ROUTE =>          -- Routing Header
            v_data(v_len)     := v_next_header;
            v_data(v_len + 1) := ext_header_list.headers(i).hdr_ext_len;
            v_data(v_len + 2) := ext_header_list.headers(i).routing_type;
            v_data(v_len + 3) := ext_header_list.headers(i).segments_left;
            v_extlen          := to_integer(unsigned(ext_header_list.headers(i).hdr_ext_len));
            if v_extlen > 0 then
              for j in 0 to v_extlen * 8 - 1 loop
                v_data(v_len + 8 + j) := ext_header_list.headers(i).data(j);
              end loop;
            end if;
            v_len := v_len + 8 * (v_extlen + 1);
          when C_IPV6_FRAG =>           -- Fragment Header
            v_data(v_len)     := v_next_header;
            v_data(v_len + 1) := ext_header_list.headers(i).f_reserved;
            v_data(v_len + 2) := ext_header_list.headers(i).fragment_offset(12 downto 5);
            v_data(v_len + 3) := ext_header_list.headers(i).fragment_offset(4 downto 0) & ext_header_list.headers(i).res & ext_header_list.headers(i).m_flag;
            v_data(v_len + 4) := ext_header_list.headers(i).identification(31 downto 24);
            v_data(v_len + 5) := ext_header_list.headers(i).identification(23 downto 16);
            v_data(v_len + 6) := ext_header_list.headers(i).identification(15 downto 8);
            v_data(v_len + 7) := ext_header_list.headers(i).identification(7 downto 0);
            v_len             := v_len + 8;
          when C_AH =>                  -- Authentication header
            v_data(v_len)      := v_next_header;
            v_data(v_len + 1)  := ext_header_list.headers(i).hdr_ext_len;  -- note! 4-byte units
            v_data(v_len + 2)  := ext_header_list.headers(i).a_reserved(15 downto 8);
            v_data(v_len + 3)  := ext_header_list.headers(i).a_reserved(7 downto 0);
            v_data(v_len + 4)  := ext_header_list.headers(i).spi(31 downto 24);
            v_data(v_len + 5)  := ext_header_list.headers(i).spi(23 downto 16);
            v_data(v_len + 6)  := ext_header_list.headers(i).spi(15 downto 8);
            v_data(v_len + 7)  := ext_header_list.headers(i).spi(7 downto 0);
            v_data(v_len + 8)  := ext_header_list.headers(i).seq_no(31 downto 24);
            v_data(v_len + 9)  := ext_header_list.headers(i).seq_no(23 downto 16);
            v_data(v_len + 10) := ext_header_list.headers(i).seq_no(15 downto 8);
            v_data(v_len + 11) := ext_header_list.headers(i).seq_no(7 downto 0);
            v_extlen           := to_integer(unsigned(ext_header_list.headers(i).hdr_ext_len));
            assert v_extlen >= 2 report "f_ipv6_create_pkt: Authentication header must have length >= 2" severity C_SEVERITY;
            for j in 0 to (v_extlen - 1) * 4 - 1 loop
              v_data(v_len + 12 + j) := ext_header_list.headers(i).data(j);
            end loop;
            v_len := v_len + 8 + v_extlen * 4;
          when others =>
            assert true report "f_ipv6_create_pkt: Extended header #" & to_string(ext_header_list.headers(i).header_type) & " is not supported" severity C_SEVERITY;
        end case;
        if i = 0 then                   -- set next_header in IPv6 header
          v_data(6) := ext_header_list.headers(i).header_type;
        end if;
      end loop;
    end if;
    -- payload
    for i in 0 to payload'length - 1 loop
      v_data(v_len + i) := payload(payload'low + i);
    end loop;
    v_len := v_len + payload'length;
    if get_length then
      v_length(0) := std_logic_vector(to_unsigned(v_len, 31));
      return v_length;
    else
      return v_data(0 to v_len - 1);
    end if;
  end function f_ipv6_create_pkt;
  --!@endcond

  -------------------------------------------------------------------------------
  --! \brief Create IPv6 packet
  --! \param header          IPv6 header
  --! \param payload         IPv6 payload
  --! \param ext_header_list IPv6 extension header list (default none)
  --! \return                IPv6 packet (8bit array) or length of IPv6 packet
  --!
  --! Create IPv6 packet. Payload must be 8bit data array.
  --!
  --! **Example use**
  --! ~~~
  --! v_ipv6_header              := C_DEFAULt_IPV66_HEADER;
  --! v_len                      := f_ipv6_create_pkt_len(v_ipv6_header, payload); -- get total packet length
  --! v_ipv6_pkt(0 to v_len - 1) := f_ipv6_create_pkt(v_ipv6_header, payload); 
  --! ~~~
  -------------------------------------------------------------------------------
  function f_ipv6_create_pkt(header          : t_ipv6_header;
                             payload         : t_slv_arr;
                             ext_header_list : t_ext_header_list := C_DEFAULT_EXT_HEADER_LIST)
    return t_slv_arr is
  begin
    return f_ipv6_create_pkt(header, payload, ext_header_list, false);
  end function f_ipv6_create_pkt;

  -------------------------------------------------------------------------------
  --! \brief Return length of IPv6 packet.
  --! \param header          IPv6 header
  --! \param payload         IPv6 payload
  --! \param ext_header_list IPv6 extension header list (default none)
  --! \return                Length of IPv6 packet
  --!
  --! Return the length of the created IPv6 packet.
  --!
  --! **Example use**
  --! ~~~
  --! v_len                      := f_ipv6_create_pkt_len(v_ipv6_header, payload); 
  --! ~~~
  -------------------------------------------------------------------------------
  function f_ipv6_create_pkt_len(header          : t_ipv6_header;
                                 payload         : t_slv_arr;
                                 ext_header_list : t_ext_header_list := C_DEFAULT_EXT_HEADER_LIST)
    return natural is
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    v_length := f_ipv6_create_pkt(header, payload, ext_header_list, true);
    return to_integer(unsigned(v_length(0)));
  end function f_ipv6_create_pkt_len;

  -------------------------------------------------------------------------------
  --! \brief Create IPv6 extension header list
  --! \param ext_header_list List of IPv6 extension headers
  --! \param ext_header      Extension header to be added to list
  --! \return                List of IPv6 extension headers
  --!
  --! Add an extension header to a extension header list.
  --!
  --! **Example use**
  --! ~~~
  --! v_ext_header_list := C_DEFAULT_EXT_HEADER_LIST; -- start with empty list
  --! v_ext_header_list := f_ipv6_add_ext_header(ext_header_list, ext_header1); -- add first header
  --! v_ext_header_list := f_ipv6_add_ext_header(ext_header_list, ext_header2); -- add second header
  --! ~~~
  -------------------------------------------------------------------------------
  function f_ipv6_add_ext_header(ext_header_list : t_ext_header_list;
                                 ext_header      : t_extension_header)
    return t_ext_header_list is
    variable v_ext_header_list : t_ext_header_list := ext_header_list;
    variable v_idx             : natural;
  begin
    assert ext_header_list.header_cnt < C_IPV6_MAX_EXT_HEADERS report "f_ipv6_add_ext_header: Extended header list is full" severity C_SEVERITY;

    v_idx                            := v_ext_header_list.header_cnt;
    v_ext_header_list.headers(v_idx) := ext_header;
    v_ext_header_list.header_cnt     := v_ext_header_list.header_cnt + 1;
    return v_ext_header_list;
  end function f_ipv6_add_ext_header;

  -------------------------------------------------------------------------------
  --! \brief Get IPv6 header
  --! \param ipv6_pkt IPv6 packet (8bit)
  --! \return         IPv6 header
  --!
  --! Extract IPv6 header from IPv6 packet. 
  --!
  --! **Example use**
  --! ~~~
  --! v_ipv6_header := f_ipv6_get_header(ipv6_pkt); 
  --! ~~~
  -------------------------------------------------------------------------------
  function f_ipv6_get_header(ipv6_pkt : t_slv_arr)
    return t_ipv6_header is
    variable v_start  : natural := ipv6_pkt'left;
    variable v_header : t_ipv6_header;
  begin
    assert ipv6_pkt'ascending report "f_ipv6_get_header: IPv6 packet must be ascending" severity C_SEVERITY;
    assert ipv6_pkt'length >= 40 report "f_ipv6_get_header: IPv6 packet must be at least 40 bytes" severity C_SEVERITY;
    assert ipv6_pkt(ipv6_pkt'low)'length = 8 report "f_ipv6_get_header: packet must be 8bit" severity C_SEVERITY;

    v_header.version        := ipv6_pkt(v_start)(7 downto 4);
    v_header.traffic_class  := ipv6_pkt(v_start)(3 downto 0) & ipv6_pkt(v_start + 1)(7 downto 4);
    v_header.flow_label     := ipv6_pkt(v_start + 1)(3 downto 0) & ipv6_pkt(v_start + 2)(7 downto 0) & ipv6_pkt(v_start + 3)(7 downto 0);
    v_header.payload_length := ipv6_pkt(v_start + 4)(7 downto 0) & ipv6_pkt(v_start + 5)(7 downto 0);
    v_header.next_header    := ipv6_pkt(v_start + 6)(7 downto 0);
    v_header.hop_limit      := ipv6_pkt(v_start + 7)(7 downto 0);
    for i in 0 to 15 loop
      v_header.src_addr(i)  := ipv6_pkt(v_start + 8 + i)(7 downto 0);
      v_header.dest_addr(i) := ipv6_pkt(v_start + 24 + i)(7 downto 0);
    end loop;
    return v_header;
  end function f_ipv6_get_header;

  -------------------------------------------------------------------------------
  --! \brief Get IPv6 extension header list
  --! \param ipv6_pkt IPv6 packet (8bit)
  --! \return         IPv6 extension header list
  --!
  --! Extract IPv6 extension headers from IPv6 packet. The number of extension headers found in the packet is indicated by the "header_cnt" field in returned record.
  --!
  --! **Example use**
  --! ~~~
  --! v_ext_headers := f_ipv6_get_ext_headers(ipv6_pkt); -- v_ext_headers.header_cnt now has the # of ext headers found in the packet
  --! ~~~
  -------------------------------------------------------------------------------
  function f_ipv6_get_ext_headers(ipv6_pkt : t_slv_arr)
    return t_ext_header_list is
    variable v_idx         : natural           := ipv6_pkt'left;
    variable v_header_list : t_ext_header_list := C_DEFAULT_EXT_HEADER_LIST;
    variable v_header      : t_ipv6_header;
    variable v_next_header : std_logic_vector(7 downto 0);
    variable v_last        : boolean           := false;
    variable v_hcnt        : natural           := 0;
    variable v_opt_len     : natural;
    variable v_didx        : natural           := 0;
  begin
    assert ipv6_pkt'ascending report "f_ipv6_get_header: IPv6 packet must be ascending" severity C_SEVERITY;
    assert ipv6_pkt'length >= 48 report "f_ipv6_get_header: IPv6 packet must be at least 48 bytes" severity C_SEVERITY;
    assert ipv6_pkt(ipv6_pkt'low)'length = 8 report "f_ipv6_get_header: packet must be 8bit" severity C_SEVERITY;

    -- get IPv6 header
    v_header      := f_ipv6_get_header(ipv6_pkt);
    v_next_header := v_header.next_header;
    v_idx         := v_idx + 40;
    -- loop through extended headers
    while v_hcnt < C_IPV6_MAX_EXT_HEADERS and not v_last loop
      if v_next_header = C_HOPOPT or v_next_header = C_IPV6_ROUTE or v_next_header = C_IPV6_FRAG or v_next_header = C_IPV6_OPTS or
        v_next_header = C_AH then
        v_header_list.headers(v_hcnt).header_type := v_next_header;
        v_header_list.headers(v_hcnt).hdr_ext_len := ipv6_pkt(v_idx + 1);
        v_opt_len                                 := to_integer(unsigned(ipv6_pkt(v_idx + 1))) * 8;
        case v_next_header is
          when C_HOPOPT =>              -- Hop-by-Hop Options
            v_header_list.headers(v_hcnt).data(0 to 5) := ipv6_pkt(v_idx + 2 to v_idx + 7);
            v_didx                                     := 6;
          when C_IPV6_ROUTE =>          -- Routing Header
            v_header_list.headers(v_hcnt).routing_type  := ipv6_pkt(v_idx + 2);
            v_header_list.headers(v_hcnt).segments_left := ipv6_pkt(v_idx + 3);
            v_header_list.headers(v_hcnt).r_reserved    := ipv6_pkt(v_idx + 4) & ipv6_pkt(v_idx + 5) & ipv6_pkt(v_idx + 6) & ipv6_pkt(v_idx + 7);
            v_didx                                      := 0;
          when C_IPV6_FRAG =>           -- Fragment Header
            v_header_list.headers(v_hcnt).f_reserved      := ipv6_pkt(v_idx + 1);
            v_header_list.headers(v_hcnt).fragment_offset := ipv6_pkt(v_idx + 2) & ipv6_pkt(v_idx + 3)(7 downto 3);
            v_header_list.headers(v_hcnt).res             := ipv6_pkt(v_idx + 3)(2 downto 1);
            v_header_list.headers(v_hcnt).m_flag          := ipv6_pkt(v_idx + 3)(0);
            v_header_list.headers(v_hcnt).identification  := ipv6_pkt(v_idx + 4) & ipv6_pkt(v_idx + 5) & ipv6_pkt(v_idx + 6) & ipv6_pkt(v_idx + 7);
            v_opt_len                                     := 0;  -- no options here
          when C_IPV6_OPTS =>           -- Destination Options 
            v_header_list.headers(v_hcnt).data(0 to 5) := ipv6_pkt(v_idx + 2 to v_idx + 7);
            v_didx                                     := 6;
          when C_AH =>                  -- Authentication header
            v_header_list.headers(v_hcnt).a_reserved := ipv6_pkt(v_idx + 2) & ipv6_pkt(v_idx + 3);
            v_header_list.headers(v_hcnt).spi        := ipv6_pkt(v_idx + 4) & ipv6_pkt(v_idx + 5) & ipv6_pkt(v_idx + 6) & ipv6_pkt(v_idx + 7);
            v_header_list.headers(v_hcnt).seq_no     := ipv6_pkt(v_idx + 8) & ipv6_pkt(v_idx + 9) & ipv6_pkt(v_idx + 10) & ipv6_pkt(v_idx + 11);
            v_opt_len                                := (to_integer(unsigned(ipv6_pkt(v_idx + 1))) + 2) * 4 - 12;
            v_didx                                   := 12;
          when others =>
            v_last := true;
        end case;
        -- add options data if ext_hdr_len > 0
        if v_opt_len > 0 then
          for i in 0 to v_opt_len - 1 loop
            v_header_list.headers(v_hcnt).data(i) := ipv6_pkt(v_idx + v_didx + i);
          end loop;
        end if;
        if v_next_header = C_AH then
          v_header_list.headers(v_hcnt).total_len := 12 + v_opt_len;
        else
          v_header_list.headers(v_hcnt).total_len := 8 + v_opt_len;
        end if;
        v_next_header                             := ipv6_pkt(v_idx);
        v_header_list.headers(v_hcnt).next_header := v_next_header;
        v_hcnt                                    := v_hcnt + 1;
        if v_next_header = C_AH then
          v_idx := v_idx + 12 + v_opt_len;
        else
          v_idx := v_idx + 8 + v_opt_len;
        end if;
      else
        v_last := true;
      end if;
    end loop;
    v_header_list.header_cnt := v_hcnt;
    return v_header_list;
  end function f_ipv6_get_ext_headers;

  -------------------------------------------------------------------------------
  -- Get payload length (internal)
  --!@cond functions
  -------------------------------------------------------------------------------
  function f_ipv6_get_payload(ipv6_pkt   : t_slv_arr;
                              get_length : boolean := false)
    return t_slv_arr is
    variable v_header      : t_ipv6_header;
    variable v_header_list : t_ext_header_list;
    variable v_idx         : natural := 0;
    variable v_length      : t_slv_arr(0 to 0)(30 downto 0);
    variable v_len         : natural;
    variable v_data        : t_slv_arr(0 to ipv6_pkt'length - 1)(7 downto 0);
  begin
    assert ipv6_pkt'ascending report "f_ipv6_get_payload: IPv6 packet must be ascending" severity C_SEVERITY;
    assert ipv6_pkt'length > 40 report "f_ipv6_get_payload: IPv6 packet must be at least 40 bytes" severity C_SEVERITY;
    assert ipv6_pkt(ipv6_pkt'low)'length = 8 report "f_ipv6_get_payload: packet must be 8bit" severity C_SEVERITY;

    -- extract header
    v_header      := f_ipv6_get_header(ipv6_pkt);
    v_idx         := v_idx + 40;
    -- extract extended header list
    v_header_list := f_ipv6_get_ext_headers(ipv6_pkt);
    if v_header_list.header_cnt > 0 then
      for i in 0 to v_header_list.header_cnt loop
        v_idx := v_idx + v_header_list.headers(i).total_len;
      end loop;
    end if;
    -- calculate payload length
    v_len := maximum(0, ipv6_pkt'length - v_idx);
    if get_length then                  -- return length of payload only
      v_length(0) := std_logic_vector(to_unsigned(v_len, 31));
      return v_length;
    end if;
    v_data(0 to v_len - 1) := ipv6_pkt(ipv6_pkt'low + v_idx to ipv6_pkt'high);
    return v_data(0 to v_len - 1);
  end function f_ipv6_get_payload;
  --!@endcond

  -------------------------------------------------------------------------------
  --! \brief Get IPv6 payload
  --! \param ipv6_pkt   IPv6 packet (8bit)
  --! \param get_length Get length of payload, default False
  --! \return           t_slv_arr
  --!
  --! Extract IPv6 payload from IPv6 packet. Extension headers are not part of the payload retunred.
  --!
  --! **Example use**
  --! ~~~
  --! v_len                     := f_ipv6_get_payload_len(ipv6_pkt); 
  --! v_payload(0 to v_len - 1) := f_ipv6_get_payload(ipv6_pkt); 
  --! ~~~
  -------------------------------------------------------------------------------
  function f_ipv6_get_payload(ipv6_pkt : t_slv_arr)
    return t_slv_arr is
  begin
    return f_ipv6_get_payload(ipv6_pkt, false);
  end function f_ipv6_get_payload;

  -------------------------------------------------------------------------------
  --! \brief Get IPv6 payload length
  --! \param ipv6_pkt   IPv6 packet (8bit)
  --! \return           IPv6 payload length
  --!
  --! Get IPv6 payload length from IPv6 packet. 
  --!
  --! **Example use**
  --! ~~~
  --! v_len := f_ipv6_get_payload_len(ipv6_pkt); -- determine size of payload
  --! ~~~
  -------------------------------------------------------------------------------
  function f_ipv6_get_payload_len(ipv6_pkt : t_slv_arr)
    return natural is
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    v_length := f_ipv6_get_payload(ipv6_pkt, true);
    return to_integer(unsigned(v_length(0)));
  end function f_ipv6_get_payload_len;

  -------------------------------------------------------------------------------
  --! \brief Convert IPv6 address string to slv_array
  --! \param addr  IPv6 address in string format
  --! \return      IPv6 address as 16 byte array
  --!
  --! Convert IPv6 address in string format to byte array. The string is assumed to follow RFC 5952 recommendation.
  --!
  --! **Example use**
  --! ~~~
  --! v_addr := f_ipv6_addr_2_slv_arr("2102:ec7::2"); -- v_addr is now (x"21", x"02", x"0e", x"c7", x"00", x"00", ..., x"00", x"02")
  --! v_addr := f_ipv6_addr_2_slv_arr("a2-34-56-f1-30-00"); -- v_addr is now (x"a2", x"34", x"56", x"f1", x"30", x"00")
  --! ~~~
  -------------------------------------------------------------------------------
  function f_ipv6_addr_2_slv_arr(addr : string)
    return t_slv_arr is
    variable v_addr      : t_slv_arr(0 to 15)(7 downto 0) := (others => x"00");
    variable v_first     : t_slv_arr(0 to 15)(7 downto 0) := (others => x"00");
    variable v_last      : t_slv_arr(0 to 15)(7 downto 0) := (others => x"00");
    variable v_first_len : natural                        := 0;
    variable v_last_len  : natural                        := 0;
    variable v_char      : natural;
    variable v_col       : boolean                        := false;
    variable v_tmp       : natural;
    variable v_wcnt      : natural                        := 0;
    variable v_nidx      : natural                        := 0;
    variable v_lastpart  : boolean                        := false;
    variable v_word      : std_logic_vector(15 downto 0)  := x"0000";
    variable v_addr2     : string(1 to addr'length + 1)   := addr & ':';
  begin
    assert addr'length >= 2 report "f_ipv6_addr_2_slv_arr: Address string length must be at least 2" severity C_SEVERITY;
    assert addr'length < 40 report "f_ipv6_addr_2_slv_arr: Address string length must be < 40" severity C_SEVERITY;
    --assert addr(addr'low) = ':' and addr(addr'low + 1) /= ':' report "f_ipv6_addr_2_slv_arr: Address string cannot start with single :" severity C_SEVERITY;
    --assert addr(addr'high) = ':' and addr(addr'high - 1) /= ':' report "f_ipv6_addr_2_slv_arr: Address string cannot end with single :" severity C_SEVERITY;

    for c in v_addr2'low to v_addr2'high loop
      v_char := character'pos(v_addr2(c));
      if v_char = 58 then
        if v_col then                   -- double colon
          v_lastpart := true;
        else
          v_word := std_logic_vector(shift_right(unsigned(v_word), (4 - v_nidx) * 4));
          if v_lastpart then
            v_last(v_last_len)     := v_word(15 downto 8);
            v_last(v_last_len + 1) := v_word(7 downto 0);
            v_last_len             := v_last_len + 2;
          else
            v_first(v_first_len)     := v_word(15 downto 8);
            v_first(v_first_len + 1) := v_word(7 downto 0);
            v_first_len              := v_first_len + 2;
          end if;
        end if;
        v_word := x"0000";
        v_col  := true;
        v_nidx := 0;
      elsif v_nidx > 3 then
        assert false report "f_ipv6_addr_2_slv_arr: too many digits between colons" severity C_SEVERITY;
      else
        case v_char is
          when 48 to 57 =>
            v_tmp                                                := v_char - 48;
            v_word((4 - v_nidx) * 4 - 1 downto (3 - v_nidx) * 4) := std_logic_vector(to_unsigned(v_tmp, 4));
            v_nidx                                               := v_nidx + 1;
            v_col                                                := false;
          when 65 to 70 =>
            v_tmp                                                := v_char - 55;
            v_word((4 - v_nidx) * 4 - 1 downto (3 - v_nidx) * 4) := std_logic_vector(to_unsigned(v_tmp, 4));
            v_nidx                                               := v_nidx + 1;
            v_col                                                := false;
          when 97 to 102 =>
            v_tmp                                                := v_char - 87;
            v_word((4 - v_nidx) * 4 - 1 downto (3 - v_nidx) * 4) := std_logic_vector(to_unsigned(v_tmp, 4));
            v_nidx                                               := v_nidx + 1;
            v_col                                                := false;
          when others =>
            assert false report "f_ipv6_addr_2_slv_arr: invalid char: " & v_addr2(c) severity C_SEVERITY;
        end case;
      end if;
    end loop;
    -- assemble address
    if v_first_len > 0 then
      v_addr(0 to v_first_len - 1) := v_first(0 to v_first_len - 1);
    end if;
    if v_last_len > 0 then
      v_addr(16 - v_last_len to 15) := v_last(0 to v_last_len - 1);
    end if;
    return v_addr;
  end function f_ipv6_addr_2_slv_arr;


end package body nw_ipv6_pkg;
