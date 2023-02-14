-------------------------------------------------------------------------------
-- Title      : Network Wizard UDPv6 package
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: 
--!\file
--!\brief UDPv6 library.
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
context nw_ipv4.nw_ipv4_context;

use work.nw_ipv6_pkg.all;
--! @endcond

--! \page nw_udpv6 UDP 
--! \tableofcontents
--! \section udpv6 UDP for IPv6
--! The UDP library provides functions for creating and manipulation UDP(v6) packets. 
--! \subsection udpv6_subsec1 Functionality
--! \li Create UDP packets of any length
--! \li Create and extract UDP headers
--! \li Verify checksum of UDP packets
--!
--! \n\n More details in \ref nw_udpv6_pkg
--! \subsection udpv6_subsec2 Example use
--! Include the libraries:
--! ~~~
--! library nw_util;
--! context nw_util.nw_util_context;
--! library nw_ipv6;
--! context nw_ipv6.nw_ipv6_context;
--! ~~~
--! Assume the variable \c v_payload contains the UDP payload. The variables are defined:
--! ~~~
--! variable v_header  : t_udp_header; -- UDP header record
--! variable v_udp_pkt : t_slv_arr(0 to 1500)(7 downto 0); -- byte array
--! variable v_len     : natural;
--! ~~~
--! First setup the header, then calculate the total UDP packet length before creating the packet. 
--! Checksum is not optional for UDP over IPv6. 
--! ~~~
--! v_header                  := C_DEFAULT_UDP_HEADER; -- copy default header
--! v_header.src_port         := x"0101"; -- change source port
--! v_len                     := f_udpv6_create_pkt_len(v_header, v_payload); -- calculate total packet length
--! v_udp_pkt(0 to v_len - 1) := f_udpv6_create_pkt(v_header, v_payload); -- create the packet (no checksum)
--! ~~~
--! The IPv6 header must be supplied for the pseudo header:
--! ~~~
--! v_ipv6_header             := C_DEFAULT_IPV6_HEADER; -- copy default header
--! v_ipv6_header.dest_addr   := f_ipv6_addr_2_slv_arr("2102:ec7::2ce"); -- change destination address
--! v_udp_pkt(0 to v_len - 1) := f_udpv6_create_pkt(v_ipv6_header, v_header, v_payload); -- create the packet
--! ~~~
--! The variable \c v_udp_pkt is an 8-bit array. This can of course be rearranged to any word width with \c f_repack() .
--! ~~~
--! v_upd_pkt_32 := f_repack(v_udp_pkt, 32, C_MSB_FIRST); -- repack to 32bit words (padded with zeros if required)
--! ~~~
--! See further examples in the test bench \c nw_ipv6_tb.vhd.
package nw_udpv6_pkg is

  -------------------------------------------------------------------------------
  -- Functions
  --@cond functions
  -------------------------------------------------------------------------------
  function f_udpv6_create_pkt(ipv6_header    : t_ipv6_header;
                              udp_header     : t_udp_header;
                              payload        : t_slv_arr;
                              routing_header : t_extension_header := C_DEFAULT_EXT_HEADER) return t_slv_arr;

  function f_udpv6_create_pkt_len(ipv6_header    : t_ipv6_header;
                                  udp_header     : t_udp_header;
                                  payload        : t_slv_arr;
                                  routing_header : t_extension_header := C_DEFAULT_EXT_HEADER) return natural;

  function f_udpv6_get_header(udp_pkt : t_slv_arr) return t_udp_header;

  function f_udpv6_get_payload(udp_pkt : t_slv_arr) return t_slv_arr;

  function f_udpv6_get_payload_len(udp_pkt : t_slv_arr) return natural;

  function f_udpv6_chksum_ok(ipv6_header    : t_ipv6_header;
                             udp_pkt        : t_slv_arr;
                             routing_header : t_extension_header := C_DEFAULT_EXT_HEADER) return boolean;
  -- @endcond

end package nw_udpv6_pkg;

package body nw_udpv6_pkg is

  -------------------------------------------------------------------------------
  -- Create UDP for IPv6 packet (internal)
  --@cond functions
  -------------------------------------------------------------------------------
  function f_udpv6_create_pkt(ipv6_header    : t_ipv6_header;
                              udp_header     : t_udp_header;
                              payload        : t_slv_arr;
                              routing_header : t_extension_header := C_DEFAULT_EXT_HEADER;
                              get_length     : boolean            := false)
    return t_slv_arr is
    variable v_len     : natural                               := 8 + payload'length;
    variable v_len_slv : std_logic_vector(15 downto 0)         := std_logic_vector(to_unsigned(v_len, 16));
    variable v_data    : t_slv_arr(0 to v_len - 1)(7 downto 0) := (others => x"00");
    variable v_pseudo  : t_slv_arr(0 to 39)(7 downto 0)        := (others => x"00");
    variable v_chksum  : std_logic_vector(15 downto 0);
    variable v_length  : t_slv_arr(0 to 0)(30 downto 0);
  begin
    assert payload'ascending report "f_udpv6_create_pkt: payload array must be ascending" severity C_SEVERITY;
    assert payload(payload'low)'length = 8 report "f_udpv6_create_pkt: payload must be 8bit" severity C_SEVERITY;

    -- header
    v_data(0) := udp_header.src_port(15 downto 8);
    v_data(1) := udp_header.src_port(7 downto 0);
    v_data(2) := udp_header.dest_port(15 downto 8);
    v_data(3) := udp_header.dest_port(7 downto 0);
    v_data(4) := v_len_slv(15 downto 8);
    v_data(5) := v_len_slv(7 downto 0);
    -- payload
    for i in 0 to payload'length - 1 loop
      v_data(8 + i) := payload(payload'low + i);
    end loop;
    -- pseudo-header
    v_pseudo(0 to 15) := ipv6_header.src_addr(0 to 15);
    if routing_header.header_type = C_IPV6_ROUTE then  -- use final destination
    -- TODO
    else
      v_pseudo(16 to 31) := ipv6_header.dest_addr(0 to 15);
    end if;
    v_pseudo(34) := v_len_slv(15 downto 8);
    v_pseudo(35) := v_len_slv(7 downto 0);
    v_pseudo(39) := C_UDP;
    -- calculate and insert checksum
    v_chksum     := not f_gen_chksum(f_repack(f_concat(v_pseudo, v_data), 16), 16);
    v_data(6)    := v_chksum(15 downto 8);
    v_data(7)    := v_chksum(7 downto 0);

    if get_length then
      v_length(0) := std_logic_vector(to_unsigned(v_len, 31));
      return v_length;
    else
      return v_data;
    end if;
  end function f_udpv6_create_pkt;
  -- @endcond

  -------------------------------------------------------------------------------
  --! \brief Create UDP for IPv6 packet
  --! \param ipv6_header    IPv6 header (required for checksum calculation)
  --! \param udp_header     UDP header
  --! \param payload        UDP payload
  --! \param routing_header IPv6 routing extension header (default none)
  --! \return               UDP packet (8bit array) or length of UDP packet
  --!
  --! Create UDP for IPv6 packet. Payload must be 8bit data array. A pseudo-header is generated from the IPv6 header
  --! which is included in the checksum calculation. If the IPv6 packet contains a routing extension header, 
  --! it must be included here as the pseudo header destination address is the final destination.
  --!
  --! **Example use**
  --! ~~~
  --! v_ipv6_header := C_DEFAULT_IPV6_HEADER;
  --! v_udp_header  := C_DEFAULT_UDP_HEADER;
  --! v_packet_8bit := f_udpv6_create_pkt(v_ipv6_header, v_udp_header, payload); 
  --! ~~~
  -------------------------------------------------------------------------------
  function f_udpv6_create_pkt(ipv6_header    : t_ipv6_header;
                              udp_header     : t_udp_header;
                              payload        : t_slv_arr;
                              routing_header : t_extension_header := C_DEFAULT_EXT_HEADER)
    return t_slv_arr is
  begin
    return f_udpv6_create_pkt(ipv6_header, udp_header, payload, routing_header, false);
  end function f_udpv6_create_pkt;

  -------------------------------------------------------------------------------
  --! \brief Return length of UDP packet.
  --! \param ipv6_header    IPv6 header (required for checksum calculation)
  --! \param udp_header     UDP header
  --! \param payload        UDP payload
  --! \param routing_header IPv6 routing extension header (default none)
  --! \return               Length of UDP packet
  --!
  --! Return the length of the created UDP packet.
  --!
  --! **Example use**
  --! ~~~
  --! v_len                      := f_udpv6_create_pkt_len(C_DEFAULT_IPV6_HEADER, v_udp_header, payload); 
  --! v_pkt_8bit(0 to v_len - 1) := f_udpv6_create_pkt(C_DEFAULT_IPV6_HEADER, v_udp_header, payload);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_udpv6_create_pkt_len(ipv6_header    : t_ipv6_header;
                                  udp_header     : t_udp_header;
                                  payload        : t_slv_arr;
                                  routing_header : t_extension_header := C_DEFAULT_EXT_HEADER)
    return natural is
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    v_length := f_udpv6_create_pkt(ipv6_header, udp_header, payload, routing_header, true);
    return to_integer(unsigned(v_length(0)));
  end function f_udpv6_create_pkt_len;

  -------------------------------------------------------------------------------
  --! \brief Get UDP header
  --! \param udp_pkt UDP packet (8bit)
  --! \return        UDP header
  --!
  --! Extract UDP header from UDP packet. 
  --!
  --! **Example use**
  --! ~~~
  --! v_udp_header := f_udpv6_get_header(data_array_8bit); 
  --! ~~~
  -------------------------------------------------------------------------------
  function f_udpv6_get_header(udp_pkt : t_slv_arr)
    return t_udp_header is
    variable v_header : t_udp_header;
  begin
    assert udp_pkt'ascending report "f_udpv6_get_header: packet array must be ascending" severity C_SEVERITY;
    assert udp_pkt(udp_pkt'low)'length = 8 report "f_udpv6_get_header: packet array must be 8bit" severity C_SEVERITY;

    v_header.src_port(15 downto 8)  := udp_pkt(0);
    v_header.src_port(7 downto 0)   := udp_pkt(1);
    v_header.dest_port(15 downto 8) := udp_pkt(2);
    v_header.dest_port(7 downto 0)  := udp_pkt(3);
    v_header.length                 := udp_pkt(4) & udp_pkt(5);
    v_header.chksum                 := udp_pkt(6) & udp_pkt(7);

    return v_header;
  end function f_udpv6_get_header;

  -------------------------------------------------------------------------------
  -- Get UDP payload (internal)
  --@cond functions
  -------------------------------------------------------------------------------
  function f_udpv6_get_payload(udp_pkt    : t_slv_arr;
                               get_length : boolean := false)
    return t_slv_arr is
    variable v_header : t_udp_header;
    variable v_len    : natural;
    variable v_data   : t_slv_arr(0 to udp_pkt'length - 1)(7 downto 0);
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    assert udp_pkt'ascending report "f_udpv6_get_payload: packet array must be ascending" severity C_SEVERITY;
    assert udp_pkt(udp_pkt'low)'length = 8 report "f_udpv6_get_payload: packet array must be 8bit" severity C_SEVERITY;
    assert udp_pkt'length > 8 report "f_udpv6_get_payload: UDP packet must be at least 9 bytes" severity C_SEVERITY;

    -- extract header
    v_header               := f_udpv6_get_header(udp_pkt);
    -- calculate payload length
    v_len                  := to_integer(unsigned(v_header.length)) - 8;
    v_data(0 to v_len - 1) := udp_pkt(8 to 7 + v_len);
    if get_length then                  -- return length of payload only
      v_length(0) := std_logic_vector(to_unsigned(v_len, 31));
      return v_length;
    end if;
    return v_data(0 to v_len - 1);
  end function f_udpv6_get_payload;
  -- @endcond

  -------------------------------------------------------------------------------
  --! \brief Get UDP payload
  --! \param udp_pkt    UDP packet (8bit)
  --! \return           t_slv_arr
  --!
  --! Extract UDP payload from UDP packet. 
  --!
  --! **Example use**
  --! ~~~
  --! v_len                     := f_udpv6_get_payload_len(data_array_8bit); 
  --! v_payload(0 to v_len - 1) := f_udpv6_get_payload(data_array_8bit); 
  --! ~~~
  -------------------------------------------------------------------------------
  function f_udpv6_get_payload(udp_pkt : t_slv_arr)
    return t_slv_arr is
  begin
    return f_udpv6_get_payload(udp_pkt, false);
  end function f_udpv6_get_payload;

  -------------------------------------------------------------------------------
  --! \brief Get UDP payload length
  --! \param udp_pkt   UDP packet (8bit)
  --! \return          UDP payload length
  --!
  --! Get UDP payload length from UDP packet. 
  --!
  --! **Example use**
  --! ~~~
  --! v_len := f_udpv6_get_payload_len(data_array_8bit); -- determine size of payload
  --! ~~~
  -------------------------------------------------------------------------------
  function f_udpv6_get_payload_len(udp_pkt : t_slv_arr)
    return natural is
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    v_length := f_udpv6_get_payload(udp_pkt, true);
    return to_integer(unsigned(v_length(0)));
  end function f_udpv6_get_payload_len;


  -------------------------------------------------------------------------------
  --! \brief Check UDP checksum
  --! \param ipv6_header    IPv6 header
  --! \param udp_pkt        UDP packet (8bit)
  --! \param routing_header IPv6 routing extension header (default none)
  --! \return               Checksum is OK (True), or not (False)
  --!
  --! Check checksum of UDP packet. The IPv6 header is required for the pseudo-header fields.
  --! If the IPv6 packet contains a routing extension header, 
  --! it must be included here as the pseudo header destination address is the final destination.
  --!
  --! **Example use**
  --! ~~~
  --! v_check := f_udpv6_chksum_ok(ipv6_header, data_array_8bit); 
  --! ~~~
  -------------------------------------------------------------------------------
  function f_udpv6_chksum_ok(ipv6_header    : t_ipv6_header;
                             udp_pkt        : t_slv_arr;
                             routing_header : t_extension_header := C_DEFAULT_EXT_HEADER)
    return boolean is
    variable v_chksum : std_logic_vector(15 downto 0);
    variable v_pseudo : t_slv_arr(0 to 39)(7 downto 0) := (others => x"00");
  begin
    assert udp_pkt'ascending report "f_udpv6_chksum_ok: packet array must be ascending" severity C_SEVERITY;
    assert udp_pkt(udp_pkt'low)'length = 8 report "f_udpv6_chksum_ok: packet array must be 8bit" severity C_SEVERITY;

    -- pseudo-header
    v_pseudo(0 to 15) := ipv6_header.src_addr(0 to 15);
    if routing_header.header_type = C_IPV6_ROUTE then  -- use final detisnation
    -- TODO
    else
      v_pseudo(16 to 31) := ipv6_header.dest_addr(0 to 15);
    end if;
    v_pseudo(34 to 35) := udp_pkt(4 to 5);
    v_pseudo(39)       := C_UDP;
    v_chksum           := not f_gen_chksum(f_repack(f_concat(v_pseudo, udp_pkt), 16), 16);

    if v_chksum = x"0000" then
      return true;
    else
      return false;
    end if;
  end function f_udpv6_chksum_ok;

end package body nw_udpv6_pkg;
