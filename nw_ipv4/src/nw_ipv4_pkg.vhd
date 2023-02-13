-------------------------------------------------------------------------------
-- Title      : Network Wizard IPv4 package
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: 
--!\file
--!\brief IPv4 library.
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

use work.ip_protocols_pkg.all;
--! @endcond

--! \page nw_ipv4 IPv4 library
--! \tableofcontents
--! \section IPv4
--! The IPv4 library provides functions for creating and manipulation IPv4 packets.
--! \subsection ipv4_subsec1 Functionality
--! \li Create IPv4 packets of any length
--! \li Create and extract IPv4 headers
--! \li Verify checksum of IPv4 packets
--!
--! Other libraries in IPv4 are: 
--! \li \subpage nw_udpv4
--! \li \subpage nw_icmpv4
--! \li \subpage nw_tcpv4
--!
--! \n More details in \ref nw_ipv4_pkg
--! \subsection ipv4_subsec2 Example use
--! Include the libraries:
--! ~~~
--! library nw_util;
--! context nw_util.nw_util_context;
--! library nw_ipv4;
--! context nw_ipv4.nw_ipv4_context;
--! ~~~
--! Assume the variable \c v_payload contains the IPv4 payload, for example an UDP packet. The variables are defined:
--! ~~~
--! variable v_header   : t_ipv4_header; -- header record
--! variable v_ipv4_pkt : t_slv_arr(0 to 1500)(7 downto 0); -- byte array
--! variable v_len      : natural;
--! ~~~
--! First setup the header, then calculate the total IPv4 packet length before creating the packet.
--! ~~~
--! v_header                   := C_DEFAULT_IPV4_HEADER; -- copy default header
--! v_header.src_ip            := x"c0a820fe"; -- change source IP
--! v_len                      := f_ipv4_create_pkt_len(v_header, v_payload); -- calculate total packet length
--! v_ipv4_pkt(0 to v_len - 1) := f_ipv4_create_pkt(v_header, v_payload); -- create the packet
--! ~~~
--! The variable \c v_ipv4_pkt is an 8-bit array. This can of course be rearranged to any word width with \c f_repack .
--! ~~~
--! v_ipv4_pkt_64 := f_repack(v_ipv4_pkt, 64, C_MSB_FIRST); -- repack to 64bit words (padded with zeros if required)
--! ~~~
--! See further examples in the test bench nw_ipv4_tb.vhd.
package nw_ipv4_pkg is

  -------------------------------------------------------------------------------
  -- IPv4 header
  -------------------------------------------------------------------------------
  type t_ipv4_options is record
    copied        : std_logic;  --! Set to 1 if the options need to be copied into all fragments of a fragmented packet. 
    option_class  : std_logic_vector(1 downto 0);  --! A general options category. 0 is for control options, and 2 is for debugging and measurement. 1 and 3 are reserved
    option_number : std_logic_vector(4 downto 0);  --! Specifies an option. 
    option_length : std_logic_vector(7 downto 0);  --! Indicates the size of the entire option (including this field). This field may not exist for simple options. 
    option_data   : t_slv_arr(0 to 37)(7 downto 0);  --! Option-specific data. This field may not exist for simple options. 
  end record t_ipv4_options;

  type t_ipv4_header is record
    version        : std_logic_vector(3 downto 0);  --! Version
    ihl            : std_logic_vector(3 downto 0);  --! Internet Header Length (IHL)
    dscp           : std_logic_vector(5 downto 0);  --! Differentiated Services Code Point (DSCP)
    ecn            : std_logic_vector(1 downto 0);  --! Explicit Congestion Notification (ECN)
    length         : std_logic_vector(15 downto 0);  --! Total length
    identification : std_logic_vector(15 downto 0);  --! Identification
    flags          : std_logic_vector(2 downto 0);  --! Flags
    fragment_offs  : std_logic_vector(12 downto 0);  --! Fragment offset
    ttl            : std_logic_vector(7 downto 0);  --! Time to live (TTL)
    protocol       : std_logic_vector(7 downto 0);  --! Protocol
    chksum         : std_logic_vector(15 downto 0);  --! Header checksum 
    src_ip         : std_logic_vector(31 downto 0);  --! Source address
    dest_ip        : std_logic_vector(31 downto 0);  --! Destination address
    options        : t_ipv4_options;    --! IPv4 options
  end record t_ipv4_header;

  -------------------------------------------------------------------------------
  -- Constants
  -- IPv4 options source: https://en.wikipedia.org/wiki/Internet_Protocol_version_4#Options
  --! @cond constants
  -------------------------------------------------------------------------------
  constant C_IPV4_EOOL   : std_logic_vector(7 downto 0) := x"00";  -- End of Option List
  constant C_IPV4_NOP    : std_logic_vector(7 downto 0) := x"01";  -- No Operation
  constant C_IPV4_SEC    : std_logic_vector(7 downto 0) := x"02";  -- Security (defunct)
  constant C_IPV4_RR     : std_logic_vector(7 downto 0) := x"07";  -- Record Route
  constant C_IPV4_ZSU    : std_logic_vector(7 downto 0) := x"0A";  -- Experimental Measurement
  constant C_IPV4_MTUP   : std_logic_vector(7 downto 0) := x"0B";  -- MTU Probe
  constant C_IPV4_MTUR   : std_logic_vector(7 downto 0) := x"0C";  -- MTU Reply
  constant C_IPV4_ENCODE : std_logic_vector(7 downto 0) := x"0F";  -- ENCODE
  constant C_IPV4_QS     : std_logic_vector(7 downto 0) := x"19";  -- Quick-Start
  constant C_IPV4_EXP    : std_logic_vector(7 downto 0) := x"1E";  -- RFC3692-style Experiment
  constant C_IPV4_TS     : std_logic_vector(7 downto 0) := x"44";  -- Time Stamp
  constant C_IPV4_TR     : std_logic_vector(7 downto 0) := x"52";  -- Traceroute
  constant C_IPV4_EXP1   : std_logic_vector(7 downto 0) := x"5E";  -- RFC3692-style Experiment
  constant C_IPV4_SEC2   : std_logic_vector(7 downto 0) := x"82";  -- Security (RIPSO)
  constant C_IPV4_LSR    : std_logic_vector(7 downto 0) := x"83";  -- Loose Source Route
  constant C_IPV4_E_SEC  : std_logic_vector(7 downto 0) := x"85";  -- Extended Security (RIPSO)
  constant C_IPV4_CIPSO  : std_logic_vector(7 downto 0) := x"86";  -- Commercial IP Security Option
  constant C_IPV4_SID    : std_logic_vector(7 downto 0) := x"88";  -- Stream ID
  constant C_IPV4_SSR    : std_logic_vector(7 downto 0) := x"89";  -- Strict Source Route
  constant C_IPV4_VISA   : std_logic_vector(7 downto 0) := x"8E";  -- Experimental Access Control
  constant C_IPV4_IMITD  : std_logic_vector(7 downto 0) := x"90";  -- IMI Traffic Descriptor
  constant C_IPV4_EIP    : std_logic_vector(7 downto 0) := x"91";  -- Extended Internet Protocol
  constant C_IPV4_ADDEXT : std_logic_vector(7 downto 0) := x"93";  -- Address Extension
  constant C_IPV4_RTRALT : std_logic_vector(7 downto 0) := x"94";  -- Router Alert
  constant C_IPV4_SDB    : std_logic_vector(7 downto 0) := x"95";  -- Selective Directed Broadcast
  constant C_IPV4_DPS    : std_logic_vector(7 downto 0) := x"97";  -- Dynamic Packet State
  constant C_IPV4_UMP    : std_logic_vector(7 downto 0) := x"98";  -- Upstream Multicast Packet
  constant C_IPV4_EXP2   : std_logic_vector(7 downto 0) := x"9E";  -- RFC3692-style Experiment
  constant C_IPV4_FINN   : std_logic_vector(7 downto 0) := x"CD";  -- Experimental Flow Control
  constant C_IPV4_EXP3   : std_logic_vector(7 downto 0) := x"DE";  -- RFC3692-style Experiment

  constant C_DEFAULT_IPV4_OPTIONS : t_ipv4_options := (copied        => '0',
                                                       option_class  => "00",
                                                       option_number => "00001",
                                                       option_length => x"00",
                                                       option_data   => (others => x"00"));

  constant C_DEFAULT_IPV4_HEADER : t_ipv4_header := (version        => x"4",
                                                     ihl            => x"5",
                                                     dscp           => "000000",
                                                     ecn            => "00",
                                                     length         => x"0000",
                                                     identification => x"0000",
                                                     flags          => "000",
                                                     fragment_offs  => "0000000000000",
                                                     ttl            => x"80",
                                                     protocol       => C_UDP,
                                                     chksum         => x"0000",
                                                     src_ip         => x"c0a80014",
                                                     dest_ip        => x"c0a80042",
                                                     options        => C_DEFAULT_IPV4_OPTIONS);
  --! @endcond

  -------------------------------------------------------------------------------
  -- Functions
  --!@cond functions
  -------------------------------------------------------------------------------
  function f_ipv4_create_pkt(header  : t_ipv4_header;
                             payload : t_slv_arr) return t_slv_arr;

  function f_ipv4_create_pkt_len(header  : t_ipv4_header;
                                 payload : t_slv_arr) return natural;

  function f_ipv4_get_header(ipv4_pkt : t_slv_arr) return t_ipv4_header;

  function f_ipv4_get_payload(ipv4_pkt : t_slv_arr) return t_slv_arr;

  function f_ipv4_get_payload_len(ipv4_pkt : t_slv_arr) return natural;

  function f_ipv4_chksum_ok(ipv4_pkt : t_slv_arr) return boolean;
  --!@endcond

end package nw_ipv4_pkg;

package body nw_ipv4_pkg is

  -------------------------------------------------------------------------------
  --! \brief Get IPv4 header
  --! \param ipv4_pkt IPv4 packet (8bit)
  --! \return         IPv4 header
  --!
  --! Extract IPv4 header from IPv4 packet. 
  --!
  --! **Example use**
  --! ~~~
  --! v_ipv4_header := f_ipv4_get_header(data_array_8bit); 
  --! ~~~
  -------------------------------------------------------------------------------
  function f_ipv4_get_header(ipv4_pkt : t_slv_arr)
    return t_ipv4_header is
    variable v_start  : natural := ipv4_pkt'left;
    variable v_header : t_ipv4_header;
  begin
    assert ipv4_pkt'ascending report "f_ipv4_get_header: IPv4 packet must be ascending" severity C_SEVERITY;
    assert ipv4_pkt'length >= 20 report "f_ipv4_get_header: IPv4 packet must be at least 20 bytes" severity C_SEVERITY;
    assert ipv4_pkt(ipv4_pkt'low)'length = 8 report "f_ipv4_get_header: packet must be 8bit" severity C_SEVERITY;

    v_header.version        := ipv4_pkt(v_start)(7 downto 4);
    v_header.ihl            := ipv4_pkt(v_start)(3 downto 0);
    v_header.dscp           := ipv4_pkt(v_start + 1)(7 downto 2);
    v_header.ecn            := ipv4_pkt(v_start + 1)(1 downto 0);
    v_header.length         := ipv4_pkt(v_start + 2)(7 downto 0) & ipv4_pkt(v_start + 3)(7 downto 0);
    v_header.identification := ipv4_pkt(v_start + 4)(7 downto 0) & ipv4_pkt(v_start + 5)(7 downto 0);
    v_header.flags          := ipv4_pkt(v_start + 6)(7 downto 5);
    v_header.fragment_offs  := ipv4_pkt(v_start + 6)(4 downto 0) & ipv4_pkt(v_start + 7)(7 downto 0);
    v_header.ttl            := ipv4_pkt(v_start + 8)(7 downto 0);
    v_header.protocol       := ipv4_pkt(v_start + 9)(7 downto 0);
    v_header.chksum         := ipv4_pkt(v_start + 10)(7 downto 0) & ipv4_pkt(v_start + 11)(7 downto 0);
    v_header.src_ip         := ipv4_pkt(v_start + 12)(7 downto 0) & ipv4_pkt(v_start + 13)(7 downto 0) & ipv4_pkt(v_start + 14)(7 downto 0) & ipv4_pkt(v_start + 15)(7 downto 0);
    v_header.dest_ip        := ipv4_pkt(v_start + 16)(7 downto 0) & ipv4_pkt(v_start + 17)(7 downto 0) & ipv4_pkt(v_start + 18)(7 downto 0) & ipv4_pkt(v_start + 19)(7 downto 0);
    if v_header.ihl > x"5" then
      v_header.options.copied         := ipv4_pkt(v_start + 20)(7);
      v_header.options.option_class   := ipv4_pkt(v_start + 20)(6 downto 5);
      v_header.options.option_number  := ipv4_pkt(v_start + 20)(4 downto 0);
      v_header.options.option_length  := ipv4_pkt(v_start + 21)(7 downto 0);
      v_header.options.option_data(0) := ipv4_pkt(v_start + 22)(7 downto 0);
      v_header.options.option_data(1) := ipv4_pkt(v_start + 23)(7 downto 0);
    end if;
    if v_header.ihl > x"6" then
      for i in 7 to to_integer(unsigned(v_header.ihl)) loop
        for j in 0 to 3 loop
          v_header.options.option_data(2 + j + (i - 7)* 4) := ipv4_pkt(v_start + 24 + j + i * 4);
        end loop;
      end loop;
    end if;
    return v_header;
  end function f_ipv4_get_header;

  -------------------------------------------------------------------------------
  -- Get IPv4 payload (internal)
  --! @cond functions
  -------------------------------------------------------------------------------
  function f_ipv4_get_payload(ipv4_pkt   : t_slv_arr;
                              get_length : boolean := false)
    return t_slv_arr is
    variable v_header : t_ipv4_header;
    variable v_idx    : natural := ipv4_pkt'low;
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
    variable v_len    : natural;
    variable v_hlen   : natural;
    variable v_data   : t_slv_arr(0 to ipv4_pkt'length - 1)(7 downto 0);
  begin
    assert ipv4_pkt'ascending report "f_ipv4_get_payload: IPv4 packet must be ascending" severity C_SEVERITY;
    assert ipv4_pkt'length > 20 report "f_ipv4_get_payload: IPv4 packet must be at least 20 bytes" severity C_SEVERITY;
    assert ipv4_pkt(ipv4_pkt'low)'length = 8 report "f_ipv4_get_payload: packet must be 8bit" severity C_SEVERITY;

    -- extract header
    v_header := f_ipv4_get_header(ipv4_pkt);
    -- calculate payload length
    v_hlen   := to_integer(unsigned(v_header.ihl)) * 4;
    v_len    := maximum(to_integer(unsigned(v_header.length)) - v_hlen, 0);
    if get_length then                  -- return length of payload only
      v_length(0) := std_logic_vector(to_unsigned(v_len, 31));
      return v_length;
    end if;
    v_data(0 to v_len - 1) := ipv4_pkt(ipv4_pkt'low + v_hlen to ipv4_pkt'low + v_hlen + v_len - 1);
    return v_data(0 to v_len - 1);
  end function f_ipv4_get_payload;
  --!@endcond

  -------------------------------------------------------------------------------
  --! \brief Get IPv4 payload
  --! \param ipv4_pkt   IPv4 packet (8bit)
  --! \return           t_slv_arr
  --!
  --! Extract IPv4 payload from IPv4 packet. 
  --!
  --! **Example use**
  --! ~~~
  --! v_len                     := f_ipv4_get_payload_len(data_array_8bit); 
  --! v_payload(0 to v_len - 1) := f_ipv4_get_payload(data_array_8bit); 
  --! ~~~
  -------------------------------------------------------------------------------
  function f_ipv4_get_payload(ipv4_pkt : t_slv_arr)
    return t_slv_arr is
  begin
    return f_ipv4_get_payload(ipv4_pkt, false);
  end function f_ipv4_get_payload;


  -------------------------------------------------------------------------------
  --! \brief Get IPv4 payload length
  --! \param ipv4_pkt   IPv4 packet (8bit)
  --! \return           IPv4 payload length
  --!
  --! Get IPv4 payload length from IPv4 packet. 
  --!
  --! **Example use**
  --! ~~~
  --! v_len := f_ipv4_get_payload_len(data_array_8bit); -- determine size of payload
  --! ~~~
  -------------------------------------------------------------------------------
  function f_ipv4_get_payload_len(ipv4_pkt : t_slv_arr)
    return natural is
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    v_length := f_ipv4_get_payload(ipv4_pkt, true);
    return to_integer(unsigned(v_length(0)));
  end function f_ipv4_get_payload_len;

  -------------------------------------------------------------------------------
  -- Create IPv4 packet (internal)
  --! @cond functions
  -------------------------------------------------------------------------------
  function f_ipv4_create_pkt(header     : t_ipv4_header;
                             payload    : t_slv_arr;
                             get_length : boolean := false)
    return t_slv_arr is
    variable v_hlen    : natural                       := to_integer(unsigned(header.ihl)) * 4;
    variable v_len     : natural                       := v_hlen + payload'length;
    variable v_data    : t_slv_arr(0 to v_len - 1)(7 downto 0);
    variable v_len_slv : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(v_len, 16));
    variable v_chksum  : std_logic_vector(15 downto 0);
    variable v_length  : t_slv_arr(0 to 0)(30 downto 0);
  begin
    assert payload'ascending report "f_ipv4_create_pkt: payload array must be ascending" severity C_SEVERITY;
    assert payload(payload'low)'length = 8 report "f_ipv4_create_pkt: payload must be 8bit" severity C_SEVERITY;

    -- insert header
    v_data(0)        := header.version & header.ihl;
    v_data(1)        := header.dscp & header.ecn;
    v_data(2)        := v_len_slv(15 downto 8);
    v_data(3)        := v_len_slv(7 downto 0);
    v_data(4)        := header.identification(15 downto 8);
    v_data(5)        := header.identification(7 downto 0);
    v_data(6)        := header.flags & header.fragment_offs(12 downto 8);
    v_data(7)        := header.fragment_offs(7 downto 0);
    v_data(8)        := header.ttl;
    v_data(9)        := header.protocol;
    v_data(10 to 11) := (others => x"00");
    for i in 0 to 3 loop
      v_data(12 + i) := header.src_ip((4 - i) * 8 - 1 downto (3 - i) * 8);
      v_data(16 + i) := header.dest_ip((4 - i) * 8 - 1 downto (3 - i) * 8);
    end loop;
    if to_integer(unsigned(header.ihl)) > 5 then
      v_data(20)       := header.options.copied & header.options.option_class & header.options.option_number;
      v_data(21)       := header.options.option_length;
      v_data(22 to 23) := header.options.option_data(0 to 1);
    end if;
    if to_integer(unsigned(header.ihl)) > 6 then
      for i in 0 to to_integer(unsigned(header.ihl)) - 6 loop
        for j in 0 to 3 loop
          v_data(24 + 4 * i + j) := header.options.option_data(2 + 4 * i + j);
        end loop;
      end loop;
    end if;
    -- add checksum
    v_chksum   := not f_gen_chksum(f_repack(v_data(0 to v_hlen - 1), 16), 16);
    v_data(10) := v_chksum(15 downto 8);
    v_data(11) := v_chksum(7 downto 0);
    -- payload
    for i in 0 to payload'length - 1 loop
      v_data(v_hlen + i) := payload(i);
    end loop;
    if get_length then
      v_length(0) := std_logic_vector(to_unsigned(v_len, 31));
      return v_length;
    else
      return v_data;
    end if;
  end function f_ipv4_create_pkt;
  --!@endcond

  -------------------------------------------------------------------------------
  --! \brief Create IPv4 packet
  --! \param header     IPv4 header
  --! \param payload    IPv4 payload
  --! \return           IPv4 packet (8bit array) or length of IPv4 packet
  --!
  --! Create IPv4 packet. Payload must be 8bit data array.
  --!
  --! **Example use**
  --! ~~~
  --! v_ipv4_header := C_DEFAULT_IPV4_HEADER;
  --! v_packet_8bit := f_ipv4_create_pkt(v_ipv4_header, payload); 
  --! ~~~
  -------------------------------------------------------------------------------
  function f_ipv4_create_pkt(header  : t_ipv4_header;
                             payload : t_slv_arr)
    return t_slv_arr is
  begin
    return f_ipv4_create_pkt(header, payload, false);
  end function f_ipv4_create_pkt;

  -------------------------------------------------------------------------------
  --! \brief Return length of IPv4 packet.
  --! \param header     IPv4 header
  --! \param payload    IPv4 payload
  --! \return           Length of IPv4 packet
  --!
  --! Return the length of the created IPv4 packet.
  --!
  --! **Example use**
  --! ~~~
  --! v_len                      := f_ipv4_create_pkt_len(v_ipv4_header, payload); 
  --! v_pkt_8bit(0 to v_len - 1) := f_ipv4_create_pkt(v_ipv4_header, payload);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_ipv4_create_pkt_len(header  : t_ipv4_header;
                                 payload : t_slv_arr)
    return natural is
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    v_length := f_ipv4_create_pkt(header, payload, true);
    return to_integer(unsigned(v_length(0)));
  end function f_ipv4_create_pkt_len;

  -------------------------------------------------------------------------------
  --! \brief Check IPv4 checksum
  --! \param ipv4_pkt  IPv4 packet (8bit)
  --! \return          Checksum is OK (True), or not (False)
  --!
  --! Check checksum of IPv4 packet. The first byte of the packet must be the first byte of the IPv4 header.
  --!
  --! **Example use**
  --! ~~~
  --! v_check := f_ipv4_chksum_ok(data_array_8bit); 
  --! ~~~
  -------------------------------------------------------------------------------
  function f_ipv4_chksum_ok(ipv4_pkt : t_slv_arr)
    return boolean is
    variable v_chksum : std_logic_vector(15 downto 0);
    variable v_header : t_ipv4_header;
    variable v_hlen   : natural;
  begin
    assert ipv4_pkt'ascending report "f_ipv4_chksum_ok: IPv4 packet must be ascending" severity C_SEVERITY;
    assert ipv4_pkt'length >= 20 report "f_ipv4_chksum_ok: IPv4 packet must be at least 20 bytes" severity C_SEVERITY;

    -- extract header
    v_header := f_ipv4_get_header(ipv4_pkt);
    v_hlen   := to_integer(unsigned(v_header.ihl)) * 4;

    v_chksum := not f_gen_chksum(f_repack(ipv4_pkt(0 to v_hlen - 1), 16), 16);
    if v_chksum = x"0000" then
      return true;
    else
      return false;
    end if;
  end function f_ipv4_chksum_ok;

end package body nw_ipv4_pkg;
