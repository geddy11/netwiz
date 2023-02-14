-------------------------------------------------------------------------------
-- Title      : Network Wizard UDPv4 package
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: 
--!\file
--!\brief UDPv4 library.
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

use work.nw_ipv4_pkg.all;
--! @endcond

--! \page nw_udpv4 UDP 
--! \tableofcontents
--! \section udpv4 UDP for IPv4
--! The UDP library provides functions for creating and manipulation UDP packets. 
--! \subsection udpv4_subsec1 Functionality
--! \li Create UDP packets of any length
--! \li Create and extract UDP headers
--! \li Verify checksum of UDP packets
--!
--! \n\n More details in \ref nw_udpv4_pkg
--! \subsection udpv4_subsec2 Example use
--! Include the libraries:
--! ~~~
--! library nw_util;
--! context nw_util.nw_util_context;
--! library nw_ipv4;
--! context nw_ipv4.nw_ipv4_context;
--! ~~~
--! Assume the variable \c v_payload contains the UDP payload. The variables are defined:
--! ~~~
--! variable v_header  : t_udp_header; -- UDP header record
--! variable v_udp_pkt : t_slv_arr(0 to 1500)(7 downto 0); -- byte array
--! variable v_len     : natural;
--! ~~~
--! First setup the header, then calculate the total UDP packet length before creating the packet. 
--! Checksum is optional for UDP over IPv4. Here it will be set to x"0000".
--! ~~~
--! v_header                  := C_DEFAULT_UDP_HEADER; -- copy default header
--! v_header.src_port         := x"0101"; -- change source port
--! v_len                     := f_udpv4_create_pkt_len(v_header, v_payload); -- calculate total packet length
--! v_udp_pkt(0 to v_len - 1) := f_udpv4_create_pkt(v_header, v_payload); -- create the packet (no checksum)
--! ~~~
--! If checksum is desired, the IPv4 header must be supplied for the pseudo header:
--! ~~~
--! v_ipv4_header             := C_DEFAULT_IPV4_HEADER; -- copy default header
--! v_udp_pkt(0 to v_len - 1) := f_udpv4_create_pkt(v_ipv4_header, v_header, v_payload); -- create the packet
--! ~~~
--! The variable \c v_udp_pkt is an 8-bit array. This can of course be rearranged to any word width with \c f_repack .
--! ~~~
--! v_ipv4_pkt_32 := f_repack(v_udp_pkt, 32, C_MSB_FIRST); -- repack to 32bit words (padded with zeros if required)
--! ~~~
--! See further examples in the test bench nw_ipv4_tb.vhd.
package nw_udpv4_pkg is

  -------------------------------------------------------------------------------
  -- Records
  -------------------------------------------------------------------------------
  type t_udp_header is record
    src_port  : std_logic_vector(15 downto 0);  --! Source port
    dest_port : std_logic_vector(15 downto 0);  --! Destination port
    length    : std_logic_vector(15 downto 0);  --! The length in bytes of the UDP header and UDP data
    chksum    : std_logic_vector(15 downto 0);  --! Checksum
  end record t_udp_header;

  -------------------------------------------------------------------------------
  -- Constants
  --!@cond functions
  -------------------------------------------------------------------------------
  constant C_DEFAULT_UDP_HEADER : t_udp_header := (src_port => x"0007", dest_port => x"0007", length => x"0000", chksum => x"0000");
  --! @endcond

  -------------------------------------------------------------------------------
  -- Functions
  --!@cond functions
  -------------------------------------------------------------------------------
  function f_udpv4_create_pkt(ipv4_header : t_ipv4_header;
                              udp_header  : t_udp_header;
                              payload     : t_slv_arr;
                              add_chksum  : boolean := true) return t_slv_arr;

  function f_udpv4_create_pkt(udp_header : t_udp_header;
                              payload    : t_slv_arr) return t_slv_arr;

  function f_udpv4_create_pkt_len(udp_header : t_udp_header;
                                  payload    : t_slv_arr) return natural;

  function f_udpv4_create_pkt_len(ipv4_header : t_ipv4_header;
                                  udp_header  : t_udp_header;
                                  payload     : t_slv_arr;
                                  add_chksum  : boolean := true) return natural;

  function f_udpv4_get_header(udp_pkt : t_slv_arr) return t_udp_header;

  function f_udpv4_get_payload(udp_pkt : t_slv_arr) return t_slv_arr;

  function f_udpv4_get_payload_len(udp_pkt : t_slv_arr) return natural;

  function f_udpv4_chksum_ok(ipv4_header : t_ipv4_header;
                             udp_pkt     : t_slv_arr) return boolean;
  --! @endcond

end package nw_udpv4_pkg;

package body nw_udpv4_pkg is

  -------------------------------------------------------------------------------
  -- Create UDP for IPv4 packet (internal)
  --@cond functions
  -------------------------------------------------------------------------------
  function f_udpv4_create_pkt(ipv4_header : t_ipv4_header;
                              udp_header  : t_udp_header;
                              payload     : t_slv_arr;
                              add_chksum  : boolean := true;
                              get_length  : boolean := false)
    return t_slv_arr is
    variable v_len     : natural                               := 8 + payload'length;
    variable v_len_slv : std_logic_vector(15 downto 0)         := std_logic_vector(to_unsigned(v_len, 16));
    variable v_data    : t_slv_arr(0 to v_len - 1)(7 downto 0) := (others => x"00");
    variable v_pseudo  : t_slv_arr(0 to 11)(7 downto 0)        := (others => x"00");
    variable v_chksum  : std_logic_vector(15 downto 0);
    variable v_length  : t_slv_arr(0 to 0)(30 downto 0);
  begin
    assert payload'ascending report "f_udpv4_create_pkt: payload array must be ascending" severity C_SEVERITY;
    assert payload(payload'low)'length = 8 report "f_udpv4_create_pkt: payload must be 8bit" severity C_SEVERITY;

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
    if add_chksum then
      v_pseudo(0)        := ipv4_header.src_ip(31 downto 24);
      v_pseudo(1)        := ipv4_header.src_ip(23 downto 16);
      v_pseudo(2)        := ipv4_header.src_ip(15 downto 8);
      v_pseudo(3)        := ipv4_header.src_ip(7 downto 0);
      v_pseudo(4)        := ipv4_header.dest_ip(31 downto 24);
      v_pseudo(5)        := ipv4_header.dest_ip(23 downto 16);
      v_pseudo(6)        := ipv4_header.dest_ip(15 downto 8);
      v_pseudo(7)        := ipv4_header.dest_ip(7 downto 0);
      v_pseudo(9)        := x"11"; --UDP
      v_pseudo(10 to 11) := v_data(4 to 5);
      v_chksum           := not f_gen_chksum(f_repack(f_concat(v_pseudo, v_data), 16), 16);
      v_data(6)          := v_chksum(15 downto 8);
      v_data(7)          := v_chksum(7 downto 0);
    end if;
    if get_length then
      v_length(0) := std_logic_vector(to_unsigned(v_len, 31));
      return v_length;
    else
      return v_data;
    end if;
  end function f_udpv4_create_pkt;
  -- @endcond

  -------------------------------------------------------------------------------
  --! \brief Create UDP for IPv4 packet
  --! \param ipv4_header IPv4 header (required for checksum calculation)
  --! \param udp_header  UDP header
  --! \param payload     UDP payload
  --! \param add_chksum  Add checksum (default true)
  --! \return            UDP packet (8bit array) or length of UDP packet
  --!
  --! Create UDP for IPv4 packet. Payload must be 8bit data array. A pseudo-header is generated from the IPv4 header
  --! which is included in the checksum calculation.
  --!
  --! **Example use**
  --! ~~~
  --! v_ipv4_header := C_DEFAULT_IPV4_HEADER;
  --! v_udp_header  := C_DEFAULT_UDP_HEADER;
  --! v_packet_8bit := f_udpv4_create_pkt(v_ipv4_header, v_udp_header, payload); 
  --! ~~~
  -------------------------------------------------------------------------------
  function f_udpv4_create_pkt(ipv4_header : t_ipv4_header;
                              udp_header  : t_udp_header;
                              payload     : t_slv_arr;
                              add_chksum  : boolean := true)
    return t_slv_arr is
  begin
    return f_udpv4_create_pkt(ipv4_header, udp_header, payload, add_chksum, false);
  end function f_udpv4_create_pkt;

  -------------------------------------------------------------------------------
  --! \brief Create UDP for IPv4 packet (no checksum)
  --! \param udp_header UDP header
  --! \param payload    UDP payload
  --! \return           UDP packet (8bit array) or length of UDP packet
  --!
  --! Create UDP packet, set checksum field to x"0000". Payload must be 8bit data array. 
  --!
  --! **Example use**
  --! ~~~
  --! v_udp_header  := C_DEFAULT_UDP_HEADER;
  --! v_packet_8bit := f_udpv4_create_pkt(v_udp_header, payload); 
  --! ~~~
  -------------------------------------------------------------------------------
  function f_udpv4_create_pkt(udp_header : t_udp_header;
                              payload    : t_slv_arr)
    return t_slv_arr is
  begin
    return f_udpv4_create_pkt(C_DEFAULT_IPV4_HEADER, udp_header, payload, false, false);
  end function f_udpv4_create_pkt;

  -------------------------------------------------------------------------------
  --! \brief Return length of UDP packet.
  --! \param udp_header UDP header
  --! \param payload    UDP payload
  --! \return           Length of UDP packet
  --!
  --! Return the length of the created UDP packet.
  --!
  --! **Example use**
  --! ~~~
  --! v_len                      := f_udpv4_create_pkt_len(v_udp_header, payload); 
  --! v_pkt_8bit(0 to v_len - 1) := f_udpv4_create_pkt(v_udp_header, payload);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_udpv4_create_pkt_len(udp_header : t_udp_header;
                                  payload    : t_slv_arr)
    return natural is
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    v_length := f_udpv4_create_pkt(C_DEFAULT_IPV4_HEADER, udp_header, payload, false, true);
    return to_integer(unsigned(v_length(0)));
  end function f_udpv4_create_pkt_len;

  -------------------------------------------------------------------------------
  --! \brief Return length of UDP packet.
  --! \param ipv4_header IPv4 header (required for checksum calculation)
  --! \param udp_header  UDP header
  --! \param payload     UDP payload
  --! \param add_chksum  Add checksum (default true)
  --! \return            Length of UDP packet
  --!
  --! Return the length of the created UDP packet.
  --!
  --! **Example use**
  --! ~~~
  --! v_len                      := f_udpv4_create_pkt_len(v_ipv4_header, v_udp_header, payload); 
  --! v_pkt_8bit(0 to v_len - 1) := f_udpv4_create_pkt(_ipv4_header, v_udp_header, payload);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_udpv4_create_pkt_len(ipv4_header : t_ipv4_header;
                                  udp_header  : t_udp_header;
                                  payload     : t_slv_arr;
                                  add_chksum  : boolean := true)
    return natural is
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    v_length := f_udpv4_create_pkt(ipv4_header, udp_header, payload, add_chksum, true);
    return to_integer(unsigned(v_length(0)));
  end function f_udpv4_create_pkt_len;

  -------------------------------------------------------------------------------
  --! \brief Get UDP header
  --! \param udp_pkt UDP packet (8bit)
  --! \return        UDP header
  --!
  --! Extract UDP header from UDP packet. 
  --!
  --! **Example use**
  --! ~~~
  --! v_udp_header := f_udpv4_get_header(data_array_8bit); 
  --! ~~~
  -------------------------------------------------------------------------------
  function f_udpv4_get_header(udp_pkt : t_slv_arr)
    return t_udp_header is
    variable v_header : t_udp_header;
  begin
    assert udp_pkt'ascending report "f_udpv4_get_header: packet array must be ascending" severity C_SEVERITY;
    assert udp_pkt(udp_pkt'low)'length = 8 report "f_udpv4_get_header: packet array must be 8bit" severity C_SEVERITY;

    v_header.src_port(15 downto 8)  := udp_pkt(0);
    v_header.src_port(7 downto 0)   := udp_pkt(1);
    v_header.dest_port(15 downto 8) := udp_pkt(2);
    v_header.dest_port(7 downto 0)  := udp_pkt(3);
    v_header.length                 := udp_pkt(4) & udp_pkt(5);
    v_header.chksum                 := udp_pkt(6) & udp_pkt(7);

    return v_header;
  end function f_udpv4_get_header;

  -------------------------------------------------------------------------------
  -- Get UDP payload (internal)
  --@cond functions
  -------------------------------------------------------------------------------
  function f_udpv4_get_payload(udp_pkt    : t_slv_arr;
                               get_length : boolean := false)
    return t_slv_arr is
    variable v_header : t_udp_header;
    variable v_len    : natural;
    variable v_data   : t_slv_arr(0 to udp_pkt'length - 1)(7 downto 0);
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    assert udp_pkt'ascending report "f_udpv4_get_payload: packet array must be ascending" severity C_SEVERITY;
    assert udp_pkt(udp_pkt'low)'length = 8 report "f_udpv4_get_payload: packet array must be 8bit" severity C_SEVERITY;
    assert udp_pkt'length > 8 report "f_udpv4_get_payload: UDP packet must be at least 9 bytes" severity C_SEVERITY;

    -- extract header
    v_header               := f_udpv4_get_header(udp_pkt);
    -- calculate payload length
    v_len                  := to_integer(unsigned(v_header.length)) - 8;
    v_data(0 to v_len - 1) := udp_pkt(8 to 7 + v_len);
    if get_length then                  -- return length of payload only
      v_length(0) := std_logic_vector(to_unsigned(v_len, 31));
      return v_length;
    end if;
    return v_data(0 to v_len - 1);
  end function f_udpv4_get_payload;
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
  --! v_len                     := f_udpv4_get_payload_len(data_array_8bit); 
  --! v_payload(0 to v_len - 1) := f_udpv4_get_payload(data_array_8bit); 
  --! ~~~
  -------------------------------------------------------------------------------
  function f_udpv4_get_payload(udp_pkt : t_slv_arr)
    return t_slv_arr is
  begin
    return f_udpv4_get_payload(udp_pkt, false);
  end function f_udpv4_get_payload;

  -------------------------------------------------------------------------------
  --! \brief Get UDP payload length
  --! \param udp_pkt   UDP packet (8bit)
  --! \return          UDP payload length
  --!
  --! Get UDP payload length from UDP packet. 
  --!
  --! **Example use**
  --! ~~~
  --! v_len := f_udpv4_get_payload_len(data_array_8bit); -- determine size of payload
  --! ~~~
  -------------------------------------------------------------------------------
  function f_udpv4_get_payload_len(udp_pkt : t_slv_arr)
    return natural is
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    v_length := f_udpv4_get_payload(udp_pkt, true);
    return to_integer(unsigned(v_length(0)));
  end function f_udpv4_get_payload_len;


  -------------------------------------------------------------------------------
  --! \brief Check UDP checksum
  --! \param ipv4_header IPv4 header
  --! \param udp_pkt     UDP packet (8bit)
  --! \return            Checksum is OK (True), or not (False)
  --!
  --! Check checksum of UDP packet. The IPv4 header is required for the pseudo-header fields.
  --!
  --! **Example use**
  --! ~~~
  --! v_check := f_udpv4_chksum_ok(ipv4_header, data_array_8bit); 
  --! ~~~
  -------------------------------------------------------------------------------
  function f_udpv4_chksum_ok(ipv4_header : t_ipv4_header;
                             udp_pkt     : t_slv_arr)
    return boolean is
    variable v_chksum : std_logic_vector(15 downto 0);
    variable v_pseudo : t_slv_arr(0 to 11)(7 downto 0) := (others => x"00");
  begin
    assert udp_pkt'ascending report "f_udpv4_chksum_ok: packet array must be ascending" severity C_SEVERITY;
    assert udp_pkt(udp_pkt'low)'length = 8 report "f_udpv4_chksum_ok: packet array must be 8bit" severity C_SEVERITY;

    v_pseudo(0)        := ipv4_header.src_ip(31 downto 24);
    v_pseudo(1)        := ipv4_header.src_ip(23 downto 16);
    v_pseudo(2)        := ipv4_header.src_ip(15 downto 8);
    v_pseudo(3)        := ipv4_header.src_ip(7 downto 0);
    v_pseudo(4)        := ipv4_header.dest_ip(31 downto 24);
    v_pseudo(5)        := ipv4_header.dest_ip(23 downto 16);
    v_pseudo(6)        := ipv4_header.dest_ip(15 downto 8);
    v_pseudo(7)        := ipv4_header.dest_ip(7 downto 0);
    v_pseudo(9)        := x"11"; -- UDP
    v_pseudo(10 to 11) := udp_pkt(4 to 5);
    v_chksum           := not f_gen_chksum(f_repack(f_concat(v_pseudo, udp_pkt), 16), 16);

    if v_chksum = x"0000" then
      return true;
    else
      return false;
    end if;
  end function f_udpv4_chksum_ok;

end package body nw_udpv4_pkg;
