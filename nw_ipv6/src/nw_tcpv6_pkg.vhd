-------------------------------------------------------------------------------
-- Title      : Network Wizard TCP for IPv6 package
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: 
--!\file
--!\brief TCP for IPv6 library.
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
use nw_ipv4.nw_tcpv4_pkg.all;

use work.nw_ipv6_pkg.all;
--! @endcond

--! \page nw_tcpv6 TCP 
--! \tableofcontents
--! \section tcpv6 TCP for IPv6
--! The TCP for IPv6 library provides functions for creating and manipulation TCP packets. 
--! \subsection tcpv6_subsec1 Functionality
--! \li Create TCP packets of any length
--! \li Create and extract TCP headers
--! \li Verify checksum of TCP packets
--!
--! \n\n More details in \ref nw_tcpv6_pkg
--! \subsection tcpv6_subsec2 Example use
--! Include the libraries:
--! ~~~
--! library nw_util;
--! context nw_util.nw_util_context;
--! library nw_ipv6;
--! context nw_ipv6.nw_ipv6_context;
--! ~~~
--! Assume the variable \c v_payload contains the TCP payload. The variables are defined:
--! ~~~
--! variable v_header      : t_tcp_header; -- TCP header record
--! variable v_ipv6_header : t_ipv6_header; -- IPv6 header record
--! variable v_tcp_pkt     : t_slv_arr(0 to 1500)(7 downto 0); -- byte array
--! variable v_len         : natural;
--! ~~~
--! First setup the header, then calculate the total TCP packet length before creating the packet. 
--! ~~~
--! v_header                  := C_DEFAULT_TCP_HEADER; -- copy default header
--! v_header.seq_no           := x"1033010f"; -- change sequence number
--! v_ipv6_header             := C_DEFAULT_IPV6_HEADER; -- IPv6 header needed for pseudo header
--! v_ipv6_header.protocol    := C_TCP; -- set protocol
--! -- change other header fields as required...
--! v_len                     := f_tcpv6_create_pkt_len(v_ipv6_header, v_header, v_payload); -- calculate total packet length
--! v_tcp_pkt(0 to v_len - 1) := f_tcpv6_create_pkt(v_ipv6_header, v_header, v_payload); -- create the packet
--! ~~~
--! The variable \c v_tcp_pkt is an 8-bit array. This can of course be rearranged to any word width with \c f_repack .
--! ~~~
--! v_tcp_pkt_32 := f_repack(v_tcp_pkt, 32, C_MSB_FIRST); -- repack to 32bit words (padded with zeros if required)
--! ~~~
--! See further examples in the test bench nw_ipv6_tb.vhd.
package nw_tcpv6_pkg is

  -------------------------------------------------------------------------------
  -- Functions
  -- @cond functions
  -------------------------------------------------------------------------------
  function f_tcpv6_create_pkt(ipv6_header    : t_ipv6_header;
                              tcp_header     : t_tcp_header;
                              payload        : t_slv_arr;
                              routing_header : t_extension_header := C_DEFAULT_EXT_HEADER) return t_slv_arr;

  function f_tcpv6_create_pkt_len(ipv6_header    : t_ipv6_header;
                                  tcp_header     : t_tcp_header;
                                  payload        : t_slv_arr;
                                  routing_header : t_extension_header := C_DEFAULT_EXT_HEADER) return natural;

  function f_tcpv6_create_pkt(ipv6_header    : t_ipv6_header;
                              tcp_header     : t_tcp_header;
                              routing_header : t_extension_header := C_DEFAULT_EXT_HEADER) return t_slv_arr;

  function f_tcpv6_create_pkt_len(ipv6_header    : t_ipv6_header;
                                  tcp_header     : t_tcp_header;
                                  routing_header : t_extension_header := C_DEFAULT_EXT_HEADER) return natural;

  function f_tcpv6_get_header(tcp_pkt : t_slv_arr) return t_tcp_header;

  function f_tcpv6_get_payload(tcp_pkt : t_slv_arr) return t_slv_arr;

  function f_tcpv6_get_payload_len(tcp_pkt : t_slv_arr) return natural;

  function f_tcpv6_chksum_ok(ipv6_header    : t_ipv6_header;
                             tcp_pkt        : t_slv_arr;
                             routing_header : t_extension_header := C_DEFAULT_EXT_HEADER) return boolean;
  -- @endcond

  -------------------------------------------------------------------------------
  -- Records
  -------------------------------------------------------------------------------
  


end package nw_tcpv6_pkg;

package body nw_tcpv6_pkg is

  -------------------------------------------------------------------------------
  -- Create TCP for IPv6 packet (internal)
  -------------------------------------------------------------------------------
  function f_tcpv6_create_pkt(ipv6_header    : t_ipv6_header;
                              tcp_header     : t_tcp_header;
                              payload        : t_slv_arr;
                              add_payload    : boolean;
                              get_length     : boolean            := false;
                              routing_header : t_extension_header := C_DEFAULT_EXT_HEADER)
    return t_slv_arr is
    variable v_len     : natural                                         := 20;
    variable v_len_slv : std_logic_vector(15 downto 0);
    variable v_data    : t_slv_arr(0 to 60 + payload'length)(7 downto 0) := (others => x"00");
    variable v_pseudo  : t_slv_arr(0 to 39)(7 downto 0)                  := (others => x"00");
    variable v_chksum  : std_logic_vector(15 downto 0);
    variable v_length  : t_slv_arr(0 to 0)(30 downto 0);
  begin
    assert payload'ascending report "f_tcpv6_create_pkt: payload array must be ascending" severity C_SEVERITY;
    assert payload(payload'low)'length = 8 report "f_tcpv6_create_pkt: payload must be 8bit" severity C_SEVERITY;
    assert unsigned(tcp_header.data_offset) >= x"5" report "f_tcpv6_create_pkt: data_offset must be >= 5" severity C_SEVERITY;

    -- header
    v_data(0)  := tcp_header.src_port(15 downto 8);
    v_data(1)  := tcp_header.src_port(7 downto 0);
    v_data(2)  := tcp_header.dest_port(15 downto 8);
    v_data(3)  := tcp_header.dest_port(7 downto 0);
    v_data(4)  := tcp_header.sequence_no(31 downto 24);
    v_data(5)  := tcp_header.sequence_no(23 downto 16);
    v_data(6)  := tcp_header.sequence_no(15 downto 8);
    v_data(7)  := tcp_header.sequence_no(7 downto 0);
    v_data(8)  := tcp_header.ack_no(31 downto 24);
    v_data(9)  := tcp_header.ack_no(23 downto 16);
    v_data(10) := tcp_header.ack_no(15 downto 8);
    v_data(11) := tcp_header.ack_no(7 downto 0);
    v_data(12) := tcp_header.data_offset & tcp_header.reserved_3 & tcp_header.flags(8);
    v_data(13) := tcp_header.flags(7 downto 0);
    v_data(14) := tcp_header.window_size(15 downto 8);
    v_data(15) := tcp_header.window_size(7 downto 0);
    v_data(18) := tcp_header.urgent_pointer(15 downto 8);
    v_data(19) := tcp_header.urgent_pointer(7 downto 0);
    if tcp_header.data_offset /= x"5" then
      for i in 0 to (to_integer(unsigned(tcp_header.data_offset)) - 5) * 4 - 1 loop
        v_data(20 + i) := tcp_header.options(i);
        v_len          := v_len + 1;
      end loop;
    end if;
    -- payload
    if add_payload then
      for i in 0 to payload'length - 1 loop
        v_data(v_len + i) := payload(payload'low + i);
      end loop;
      v_len := v_len + payload'length;
    end if;
    -- pseudo-header
    v_pseudo(0 to 15) := ipv6_header.src_addr(0 to 15);
    if routing_header.header_type = C_IPV6_ROUTE then  -- use final destination
    -- TODO
    else
      v_pseudo(16 to 31) := ipv6_header.dest_addr(0 to 15);
    end if;
    v_len_slv    := std_logic_vector(to_unsigned(v_len, 16));
    v_pseudo(34) := v_len_slv(15 downto 8);
    v_pseudo(35) := v_len_slv(7 downto 0);
    v_pseudo(39) := C_TCP;                             -- TCP
    v_chksum     := not f_gen_chksum(f_repack(f_concat(v_pseudo, v_data(0 to v_len - 1)), 16), 16);
    v_data(16)   := v_chksum(15 downto 8);
    v_data(17)   := v_chksum(7 downto 0);
    if get_length then
      v_length(0) := std_logic_vector(to_unsigned(v_len, 31));
      return v_length;
    else
      return v_data(0 to v_len - 1);
    end if;
  end function f_tcpv6_create_pkt;

  -------------------------------------------------------------------------------
  --! \brief Create TCP for IPv6 packet
  --! \param ipv6_header    IPv6 header (required for checksum calculation)
  --! \param udp_header     TCP header
  --! \param payload        TCP payload
  --! \return               TCP packet (8bit array)
  --! \param routing_header IPv6 routing extension header (default none)
  --!
  --! Create TCPv4 packet. Payload must be 8bit data array. A pseudo-header is generated from the IPv4 header
  --! which is included in the checksum calculation.
  --!
  --! **Example use**
  --! ~~~
  --! v_ipv6_header := C_DEFAULT_ipv6_header;
  --! v_tcp_header  := C_DEFAULT_TCP_HEADER;
  --! v_packet_8bit := f_tcpv6_create_pkt(v_ipv6_header, v_tcp_header, payload); 
  --! ~~~
  -------------------------------------------------------------------------------
  function f_tcpv6_create_pkt(ipv6_header    : t_ipv6_header;
                              tcp_header     : t_tcp_header;
                              payload        : t_slv_arr;
                              routing_header : t_extension_header := C_DEFAULT_EXT_HEADER)
    return t_slv_arr is
  begin
    return f_tcpv6_create_pkt(ipv6_header, tcp_header, payload, true, false, routing_header);
  end function f_tcpv6_create_pkt;

  -------------------------------------------------------------------------------
  --! \brief Return length of TCP packet.
  --! \param ipv6_header    IPv6 header (required for checksum calculation)
  --! \param tcp_header     TCP header
  --! \param payload        TCP payload
  --! \param routing_header IPv6 routing extension header (default none)
  --! \return               Length of TCP packet
  --!
  --! Return the length of the created TCP packet.
  --!
  --! **Example use**
  --! ~~~
  --! v_len                      := f_tcpv6_create_pkt_len(v_ipv6_header, v_tcp_header, payload); 
  --! v_pkt_8bit(0 to v_len - 1) := f_tcpv6_create_pkt(v_ipv6_header, v_tcp_header, payload);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_tcpv6_create_pkt_len(ipv6_header    : t_ipv6_header;
                                  tcp_header     : t_tcp_header;
                                  payload        : t_slv_arr;
                                  routing_header : t_extension_header := C_DEFAULT_EXT_HEADER)
    return natural is
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    v_length := f_tcpv6_create_pkt(ipv6_header, tcp_header, payload, true, true, routing_header);
    return to_integer(unsigned(v_length(0)));
  end function f_tcpv6_create_pkt_len;

  -------------------------------------------------------------------------------
  --! \brief Create TCP for IPv6 packet
  --! \param ipv6_header    IPv6 header (required for checksum calculation)
  --! \param udp_header     TCP header
  --! \param routing_header IPv6 routing extension header (default none)
  --! \return               TCP packet (8bit array)
  --!
  --! Create TCP for IPv6 packet without payload.
  --!
  --! **Example use**
  --! ~~~
  --! v_ipv6_header := C_DEFAULT_ipv6_header;
  --! v_tcp_header  := C_DEFAULT_TCP_HEADER;
  --! v_packet_8bit := f_tcpv6_create_pkt(v_ipv6_header, v_tcp_header); 
  --! ~~~
  -------------------------------------------------------------------------------
  function f_tcpv6_create_pkt(ipv6_header    : t_ipv6_header;
                              tcp_header     : t_tcp_header;
                              routing_header : t_extension_header := C_DEFAULT_EXT_HEADER)
    return t_slv_arr is
    variable v_payload : t_slv_arr(0 to 0)(7 downto 0) := (others => x"00");
  begin
    return f_tcpv6_create_pkt(ipv6_header, tcp_header, v_payload, false, false, routing_header);
  end function f_tcpv6_create_pkt;

  -------------------------------------------------------------------------------
  --! \brief Return length of TCP packet.
  --! \param ipv6_header    IPv6 header (required for checksum calculation)
  --! \param tcp_header     TCP header
  --! \param routing_header IPv6 routing extension header (default none)
  --! \return               Length of TCP packet
  --! 
  --! Return the length of the created TCP packet (no payload).
  --!
  --! **Example use**
  --! ~~~
  --! v_len                      := f_tcpv6_create_pkt_len(v_ipv6_header, v_tcp_header); 
  --! v_pkt_8bit(0 to v_len - 1) := f_tcpv6_create_pkt(v_ipv6_header, v_tcp_header);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_tcpv6_create_pkt_len(ipv6_header    : t_ipv6_header;
                                  tcp_header     : t_tcp_header;
                                  routing_header : t_extension_header := C_DEFAULT_EXT_HEADER)
    return natural is
    variable v_length  : t_slv_arr(0 to 0)(30 downto 0);
    variable v_payload : t_slv_arr(0 to 0)(7 downto 0) := (others => x"00");
  begin
    v_length := f_tcpv6_create_pkt(ipv6_header, tcp_header, v_payload, false, true, routing_header);
    return to_integer(unsigned(v_length(0)));
  end function f_tcpv6_create_pkt_len;

  -------------------------------------------------------------------------------
  --! \brief Get TCP header
  --! \param tcp_pkt TCP packet (8bit)
  --! \return        TCP header
  --!
  --! Extract TCP header from TCP packet. 
  --!
  --! **Example use**
  --! ~~~
  --! v_tcp_header := f_tcpv6_get_header(data_array_8bit); 
  --! ~~~
  -------------------------------------------------------------------------------
  function f_tcpv6_get_header(tcp_pkt : t_slv_arr)
    return t_tcp_header is
    variable v_header : t_tcp_header;
  begin
    assert tcp_pkt'ascending report "f_tcpv6_get_header: packet array must be ascending" severity C_SEVERITY;
    assert tcp_pkt(tcp_pkt'low)'length = 8 report "f_tcpv6_get_header: packet array must be 8bit" severity C_SEVERITY;
    assert tcp_pkt'length >= 20 report "f_tcpv6_get_header: packet size must be >=20" severity C_SEVERITY;

    v_header.src_port(15 downto 8)       := tcp_pkt(0);
    v_header.src_port(7 downto 0)        := tcp_pkt(1);
    v_header.dest_port(15 downto 8)      := tcp_pkt(2);
    v_header.dest_port(7 downto 0)       := tcp_pkt(3);
    v_header.sequence_no(31 downto 24)   := tcp_pkt(4);
    v_header.sequence_no(23 downto 16)   := tcp_pkt(5);
    v_header.sequence_no(15 downto 8)    := tcp_pkt(6);
    v_header.sequence_no(7 downto 0)     := tcp_pkt(7);
    v_header.ack_no(31 downto 24)        := tcp_pkt(8);
    v_header.ack_no(23 downto 16)        := tcp_pkt(9);
    v_header.ack_no(15 downto 8)         := tcp_pkt(10);
    v_header.ack_no(7 downto 0)          := tcp_pkt(11);
    v_header.data_offset                 := tcp_pkt(12)(7 downto 4);
    v_header.reserved_3                  := tcp_pkt(12)(3 downto 1);
    v_header.flags(8)                    := tcp_pkt(12)(0);
    v_header.flags(7 downto 0)           := tcp_pkt(13);
    v_header.window_size(15 downto 8)    := tcp_pkt(14);
    v_header.window_size(7 downto 0)     := tcp_pkt(15);
    v_header.chksum(15 downto 8)         := tcp_pkt(16);
    v_header.chksum(7 downto 0)          := tcp_pkt(17);
    v_header.urgent_pointer(15 downto 8) := tcp_pkt(18);
    v_header.urgent_pointer(7 downto 0)  := tcp_pkt(19);
    if tcp_pkt(12)(7 downto 4) /= x"5" then
      for i in 0 to (to_integer(unsigned(tcp_pkt(12)(7 downto 4))) - 5) * 4 - 1 loop
        v_header.options(i) := tcp_pkt(20 + i);
      end loop;
    end if;

    return v_header;
  end function f_tcpv6_get_header;

  -------------------------------------------------------------------------------
  -- Get TCP payload (internal)
  -------------------------------------------------------------------------------
  function f_tcpv6_get_payload(tcp_pkt    : t_slv_arr;
                               get_length : boolean := false)
    return t_slv_arr is
    variable v_header : t_tcp_header;
    variable v_len    : natural;
    variable v_hlen   : natural;
    variable v_data   : t_slv_arr(0 to tcp_pkt'length - 1)(7 downto 0);
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    assert tcp_pkt'ascending report "f_tcpv6_get_payload: packet array must be ascending" severity C_SEVERITY;
    assert tcp_pkt(tcp_pkt'low)'length = 8 report "f_tcpv6_get_payload: packet array must be 8bit" severity C_SEVERITY;
    assert tcp_pkt'length > 20 report "f_tcpv6_get_payload: TCP packet must be at least 21 bytes" severity C_SEVERITY;

    -- extract header
    v_header := f_tcpv6_get_header(tcp_pkt);
    v_hlen   := to_integer(unsigned(v_header.data_offset)) * 4;
    -- calculate payload length
    v_len    := tcp_pkt'length - v_hlen;
    if v_len > 0 then
      v_data(0 to v_len - 1) := tcp_pkt(v_hlen to tcp_pkt'high);
    end if;
    if get_length then                  -- return length of payload only
      v_length(0) := std_logic_vector(to_unsigned(v_len, 31));
      return v_length;
    end if;
    return v_data(0 to v_len - 1);
  end function f_tcpv6_get_payload;

  -------------------------------------------------------------------------------
  --! \brief Get TCP payload
  --! \param tcp_pkt    TCP packet (8bit)
  --! \return           t_slv_arr
  --!
  --! Extract TCP payload from TCP packet. 
  --!
  --! **Example use**
  --! ~~~
  --! v_len                     := f_tcpv6_get_payload_len(data_array_8bit); 
  --! v_payload(0 to v_len - 1) := f_tcpv6_get_payload(data_array_8bit); 
  --! ~~~
  -------------------------------------------------------------------------------
  function f_tcpv6_get_payload(tcp_pkt : t_slv_arr)
    return t_slv_arr is
  begin
    return f_tcpv6_get_payload(tcp_pkt, false);
  end function f_tcpv6_get_payload;

  -------------------------------------------------------------------------------
  --! \brief Get TCP payload length
  --! \param tcp_pkt   TCP packet (8bit)
  --! \return          TCP payload length
  --!
  --! Get TCP payload length from TCP packet. 
  --!
  --! **Example use**
  --! ~~~
  --! v_len := f_tcpv6_get_payload_len(data_array_8bit); -- determine size of payload
  --! ~~~
  -------------------------------------------------------------------------------
  function f_tcpv6_get_payload_len(tcp_pkt : t_slv_arr)
    return natural is
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    v_length := f_tcpv6_get_payload(tcp_pkt, true);
    return to_integer(unsigned(v_length(0)));
  end function f_tcpv6_get_payload_len;

  -------------------------------------------------------------------------------
  --! \brief Check TCP checksum
  --! \param ipv6_header    IPv6 header
  --! \param tcp_pkt        TCP packet (8bit)
  --! \param routing_header IPv6 routing extension header (default none) 
  --! \return               Checksum is OK (True), or not (False)
  --!
  --! Check checksum of TCP packet. The IPv6 header is required for the pseudo-header fields.
  --!
  --! **Example use**
  --! ~~~
  --! v_check := f_tcpv6_chksum_ok(ipv6_header, data_array_8bit); 
  --! ~~~
  -------------------------------------------------------------------------------
  function f_tcpv6_chksum_ok(ipv6_header    : t_ipv6_header;
                             tcp_pkt        : t_slv_arr;
                             routing_header : t_extension_header := C_DEFAULT_EXT_HEADER)
    return boolean is
    variable v_chksum : std_logic_vector(15 downto 0);
    variable v_pseudo : t_slv_arr(0 to 39)(7 downto 0) := (others => x"00");
    variable v_len    : std_logic_vector(31 downto 0)  := std_logic_vector(to_unsigned(tcp_pkt'length, 32));
  begin
    assert tcp_pkt'ascending report "f_tcpv6_chksum_ok: packet array must be ascending" severity C_SEVERITY;
    assert tcp_pkt(tcp_pkt'low)'length = 8 report "f_tcpv6_chksum_ok: packet array must be 8bit" severity C_SEVERITY;

    v_pseudo(0 to 15) := ipv6_header.src_addr(0 to 15);
    if routing_header.header_type = C_IPV6_ROUTE then  -- use final destination
    -- TODO
    else
      v_pseudo(16 to 31) := ipv6_header.dest_addr(0 to 15);
    end if;
    v_pseudo(32) := v_len(31 downto 24);
    v_pseudo(33) := v_len(23 downto 16);
    v_pseudo(34) := v_len(15 downto 8);
    v_pseudo(35) := v_len(7 downto 0);
    v_pseudo(39) := C_TCP;                             -- TCP
    v_chksum     := not f_gen_chksum(f_repack(f_concat(v_pseudo, tcp_pkt), 16), 16);

    if v_chksum = x"0000" then
      return true;
    else
      return false;
    end if;
  end function f_tcpv6_chksum_ok;

end package body nw_tcpv6_pkg;
