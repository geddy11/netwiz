-------------------------------------------------------------------------------
-- Title      : Network Wizard ICMPv6 package
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: 
--!\file
--!\brief ICMPv6 library.
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

--! \page nw_icmpv6 ICMP
--! \tableofcontents
--! \section icmpv6 ICMP for IPv6
--! The ICMPv6 library provides functions for creating and manipulation ICMP packets according to RFC 4443. 
--! \subsection icmpv6_subsec1 Functionality
--! \li Create ICMP packets of any length
--! \li Create and extract ICMP headers
--! \li Verify checksum of ICMP packets
--!
--! \n\n More details in \ref nw_icmpv6_pkg
--! \subsection icmpv6_subsec2 Example use
--! Include the libraries:
--! ~~~
--! library nw_util;
--! context nw_util.nw_util_context;
--! library nw_ipv6;
--! context nw_ipv6.nw_ipv6_context;
--! ~~~
--! Assume the variable \c v_payload contains the ICMP payload. The variables are defined:
--! ~~~
--! variable v_header      : t_icmpv6_header; -- ICMP header record
--! variable v_ipv6_header : t_ipv6_header := C_DEFAULT_IPV6_HEADER; -- Needed for pseudo header checksum calculation
--! variable v_payload     : t_slv_arr(0 to 3)(7 downto 0);
--! variable v_icmp_pkt    : t_slv_arr(0 to 39)(7 downto 0); -- byte array
--! variable v_len         : natural;
--! ~~~
--! First setup the header, then calculate the total ICMP packet length before creating the packet. 
--! ~~~
--! v_header                   := C_DEFAULT_ICMP6_HEADER; -- copy default header (ping request)
--! v_payload                  := f_gen_nrs(x"80", 4); -- payload contents
--! v_len                      := f_icmpv6_create_pkt_len(v_ipv6_header, v_header, v_payload); -- calculate total packet length
--! v_icmp_pkt(0 to v_len - 1) := f_icmpv6_create_pkt(v_ipv6_header, v_header, v_payload); -- create the packet
--! ~~~
--! The variable \c v_icmp_pkt is an 8-bit array. This can of course be rearranged to any word width with \c f_repack().
--! ~~~
--! v_icmpv6_pkt_32 := f_repack(v_icmp_pkt, 32, C_MSB_FIRST); -- repack to 32bit words (padded with zeros if required)
--! ~~~
--! See further examples in the test bench nw_ipv6_tb.vhd.
package nw_icmpv6_pkg is

  -------------------------------------------------------------------------------
  -- Records
  -------------------------------------------------------------------------------
  type t_icmpv6_header is record
    icmp_type : std_logic_vector(7 downto 0);   --! ICMP type
    icmp_code : std_logic_vector(7 downto 0);   --! ICMP subtype
    chksum    : std_logic_vector(15 downto 0);  --! Checksum
  end record t_icmpv6_header;

  -------------------------------------------------------------------------------
  -- Constants
  --!@cond constants
  -------------------------------------------------------------------------------
  constant C_ICMPV6_RESERVED                                     : std_logic_vector(7 downto 0) := x"00";
  constant C_ICMPV6_DESTINATION_UNREACHABLE                      : std_logic_vector(7 downto 0) := x"01";
  constant C_ICMPV6_PACKET_TOO_BIG                               : std_logic_vector(7 downto 0) := x"02";
  constant C_ICMPV6_TIME_EXCEEDED                                : std_logic_vector(7 downto 0) := x"03";
  constant C_ICMPV6_PARAMETER_PROBLEM                            : std_logic_vector(7 downto 0) := x"04";
  constant C_ICMPV6_ECHO_REQUEST                                 : std_logic_vector(7 downto 0) := x"80";
  constant C_ICMPV6_ECHO_REPLY                                   : std_logic_vector(7 downto 0) := x"81";
  constant C_ICMPV6_MULTICAST_LISTENER_QUERY                     : std_logic_vector(7 downto 0) := x"82";
  constant C_ICMPV6_MULTICAST_LISTENER_REPORT                    : std_logic_vector(7 downto 0) := x"83";
  constant C_ICMPV6_MULTICAST_LISTENER_DONE                      : std_logic_vector(7 downto 0) := x"84";
  constant C_ICMPV6_ROUTER_SOLICITATION                          : std_logic_vector(7 downto 0) := x"85";
  constant C_ICMPV6_ROUTER_ADVERTISEMENT                         : std_logic_vector(7 downto 0) := x"86";
  constant C_ICMPV6_NEIGHBOR_SOLICITATION                        : std_logic_vector(7 downto 0) := x"87";
  constant C_ICMPV6_NEIGHBOR_ADVERTISEMENT                       : std_logic_vector(7 downto 0) := x"88";
  constant C_ICMPV6_REDIRECT_MESSAGE                             : std_logic_vector(7 downto 0) := x"89";
  constant C_ICMPV6_ROUTER_RENUMBERING                           : std_logic_vector(7 downto 0) := x"8A";
  constant C_ICMPV6_ICMP_NODE_INFORMATION_QUERY                  : std_logic_vector(7 downto 0) := x"8B";
  constant C_ICMPV6_ICMP_NODE_INFORMATION_RESPONSE               : std_logic_vector(7 downto 0) := x"8C";
  constant C_ICMPV6_INVERSE_NEIGHBOR_DISCOVERY_SOLICITATION_MSG  : std_logic_vector(7 downto 0) := x"8D";
  constant C_ICMPV6_INVERSE_NEIGHBOR_DISCOVERY_ADVERTISEMENT_MSG : std_logic_vector(7 downto 0) := x"8E";
  constant C_ICMPV6_VERSION_2_MULTICAST_LISTENER_REPORT          : std_logic_vector(7 downto 0) := x"8F";
  constant C_ICMPV6_HOME_AGENT_ADDRESS_DISCOVERY_REQUEST_MSG     : std_logic_vector(7 downto 0) := x"90";
  constant C_ICMPV6_HOME_AGENT_ADDRESS_DISCOVERY_REPLY_MSG       : std_logic_vector(7 downto 0) := x"91";
  constant C_ICMPV6_MOBILE_PREFIX_SOLICITATION                   : std_logic_vector(7 downto 0) := x"92";
  constant C_ICMPV6_MOBILE_PREFIX_ADVERTISEMENT                  : std_logic_vector(7 downto 0) := x"93";
  constant C_ICMPV6_CERTIFICATION_PATH_SOLICITATION_MSG          : std_logic_vector(7 downto 0) := x"94";
  constant C_ICMPV6_CERTIFICATION_PATH_ADVERTISEMENT_MSG         : std_logic_vector(7 downto 0) := x"95";
  constant C_ICMPV6_MULTICAST_ROUTER_ADVERTISEMENT               : std_logic_vector(7 downto 0) := x"97";
  constant C_ICMPV6_MULTICAST_ROUTER_SOLICITATION                : std_logic_vector(7 downto 0) := x"98";
  constant C_ICMPV6_MULTICAST_ROUTER_TERMINATION                 : std_logic_vector(7 downto 0) := x"99";
  constant C_ICMPV6_FMIPV6_MESSAGES                              : std_logic_vector(7 downto 0) := x"9A";
  constant C_ICMPV6_RPL_CONTROL_MESSAGE                          : std_logic_vector(7 downto 0) := x"9B";
  constant C_ICMPV6_ILNPV6_LOCATOR_UPDATE_MSG                    : std_logic_vector(7 downto 0) := x"9C";
  constant C_ICMPV6_DUPLICATE_ADDRESS_REQUEST                    : std_logic_vector(7 downto 0) := x"9D";
  constant C_ICMPV6_DUPLICATE_ADDRESS_CONFIRMATION               : std_logic_vector(7 downto 0) := x"9E";
  constant C_ICMPV6_MPL_CONTROL_MESSAGE                          : std_logic_vector(7 downto 0) := x"9F";
  constant C_ICMPV6_EXTENDED_ECHO_REQUEST                        : std_logic_vector(7 downto 0) := x"A0";
  constant C_ICMPV6_EXTENDED_ECHO_REPLY                          : std_logic_vector(7 downto 0) := x"A1";

  constant C_DEFAULT_ICMPV6_HEADER : t_icmpv6_header := (icmp_type => C_ICMPV6_ECHO_REQUEST, icmp_code => x"00", chksum => x"0000");
  --! @endcond

  -------------------------------------------------------------------------------
  -- Functions
  --!@cond functions
  -------------------------------------------------------------------------------
  function f_icmpv6_create_pkt(ipv6_header    : t_ipv6_header;
                               icmp_header    : t_icmpv6_header;
                               payload        : t_slv_arr;
                               routing_header : t_extension_header := C_DEFAULT_EXT_HEADER) return t_slv_arr;

  function f_icmpv6_create_pkt_len(ipv6_header    : t_ipv6_header;
                                   icmp_header    : t_icmpv6_header;
                                   payload        : t_slv_arr;
                                   routing_header : t_extension_header := C_DEFAULT_EXT_HEADER) return natural;

  function f_icmpv6_get_header(icmp_pkt : t_slv_arr) return t_icmpv6_header;

  function f_icmpv6_get_payload(icmp_pkt : t_slv_arr) return t_slv_arr;

  function f_icmpv6_get_payload_len(icmp_pkt : t_slv_arr) return natural;

  function f_icmpv6_chksum_ok(ipv6_header    : t_ipv6_header;
                              icmp_pkt       : t_slv_arr;
                              routing_header : t_extension_header := C_DEFAULT_EXT_HEADER) return boolean;
  --! @endcond

end package nw_icmpv6_pkg;

package body nw_icmpv6_pkg is

  -------------------------------------------------------------------------------
  -- Create ICMPv6 packet (internal)
  -------------------------------------------------------------------------------
  function f_icmpv6_create_pkt(ipv6_header    : t_ipv6_header;
                               icmp_header    : t_icmpv6_header;
                               payload        : t_slv_arr;
                               routing_header : t_extension_header := C_DEFAULT_EXT_HEADER;
                               get_length     : boolean)
    return t_slv_arr is
    variable v_len     : natural                               := 4 + payload'length;
    variable v_len_slv : std_logic_vector(15 downto 0)         := std_logic_vector(to_unsigned(v_len, 16));
    variable v_data    : t_slv_arr(0 to v_len - 1)(7 downto 0) := (others => x"00");
    variable v_chksum  : std_logic_vector(15 downto 0);
    variable v_length  : t_slv_arr(0 to 0)(30 downto 0);
    variable v_pseudo  : t_slv_arr(0 to 39)(7 downto 0)        := (others => x"00");
  begin
    assert payload'ascending report "f_icmpv6_create_pkt: payload array must be ascending" severity C_SEVERITY;
    assert payload(payload'low)'length = 8 report "f_icmpv6_create_pkt: payload must be 8bit" severity C_SEVERITY;
    assert payload'length >= 4 report "f_icmpv6_create_pkt: payload length must be >= 4" severity C_SEVERITY;

    -- header
    v_len          := 4;
    v_data(0)      := icmp_header.icmp_type(7 downto 0);
    v_data(1)      := icmp_header.icmp_code(7 downto 0);
    v_data(2 to 3) := (others => x"00");
    -- payload
    for i in 0 to payload'length - 1 loop
      v_data(4 + i) := payload(payload'low + i);
    end loop;
    v_len             := v_len + payload'length;
    -- pseudo-header
    v_pseudo(0 to 15) := ipv6_header.src_addr(0 to 15);
    if routing_header.header_type = C_IPV6_ROUTE then  -- use final destination
    -- TODO
    else
      v_pseudo(16 to 31) := ipv6_header.dest_addr(0 to 15);
    end if;
    v_pseudo(34) := v_len_slv(15 downto 8);
    v_pseudo(35) := v_len_slv(7 downto 0);
    v_pseudo(39) := C_IPV6_ICMP;
    -- checksum
    v_chksum     := not f_gen_chksum(f_repack(f_concat(v_pseudo, v_data), 16), 16);
    v_data(2)    := v_chksum(15 downto 8);
    v_data(3)    := v_chksum(7 downto 0);
    -- result
    if get_length then
      v_length(0) := std_logic_vector(to_unsigned(v_len, 31));
      return v_length;
    else
      return v_data(0 to v_len - 1);
    end if;
  end function f_icmpv6_create_pkt;

  -------------------------------------------------------------------------------
  --! \brief Create ICMPv4 packet
  --! \param ipv6_header    IPv6 header (required for checksum calculation)
  --! \param icmp_header    ICMP header
  --! \param payload        ICMP payload
  --! \param routing_header IPv6 routing extension header (default none)
  --! \return               ICMP packet (8bit array) or length of ICMP packet
  --!
  --! Create ICMPv6 packet. Payload must be 8bit data array.  A pseudo-header is generated from the IPv6 header
  --! which is included in the checksum calculation. If the IPv6 packet contains a routing extension header, 
  --! it must be included here as the pseudo header destination address is the final destination.
  --!
  --! **Example use**
  --! ~~~
  --! v_packet_8bit  := f_icmpv6_create_pkt(v_ipv6_header, C_DEFAULT_ICMPV6_HEADER, payload); -- echo request
  --! ~~~
  -------------------------------------------------------------------------------
  function f_icmpv6_create_pkt(ipv6_header    : t_ipv6_header;
                               icmp_header    : t_icmpv6_header;
                               payload        : t_slv_arr;
                               routing_header : t_extension_header := C_DEFAULT_EXT_HEADER)
    return t_slv_arr is
  begin
    return f_icmpv6_create_pkt(ipv6_header, icmp_header, payload, routing_header, false);
  end function f_icmpv6_create_pkt;

  -------------------------------------------------------------------------------
  --! \brief Return length of ICMP packet.
  --! \param ipv6_header    IPv6 header (required for checksum calculation)
  --! \param icmp_header    ICMP header
  --! \param payload        ICMP payload
  --! \param routing_header IPv6 routing extension header (default none)
  --! \return            Length of ICMP packet
  --!
  --! Return the length of the created ICMP packet.
  --!
  --! **Example use**
  --! ~~~
  --! v_len                      := f_icmpv6_create_pkt_len(v_ipv6_header, v_icmp_header, payload); 
  --! v_pkt_8bit(0 to v_len - 1) := f_icmpv6_create_pkt(v_ipv6_header, v_icmp_header, payload);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_icmpv6_create_pkt_len(ipv6_header    : t_ipv6_header;
                                   icmp_header    : t_icmpv6_header;
                                   payload        : t_slv_arr;
                                   routing_header : t_extension_header := C_DEFAULT_EXT_HEADER)
    return natural is
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    v_length := f_icmpv6_create_pkt(ipv6_header, icmp_header, payload, routing_header, true);
    return to_integer(unsigned(v_length(0)));
  end function f_icmpv6_create_pkt_len;

  -------------------------------------------------------------------------------
  --! \brief Get ICMP header
  --! \param icmp_pkt ICMP packet (8bit)
  --! \return         ICMP header
  --!
  --! Extract ICMP header from ICMP packet. 
  --!
  --! **Example use**
  --! ~~~
  --! v_icmp_header := f_icmpv6_get_header(data_array_8bit); 
  --! ~~~
  -------------------------------------------------------------------------------
  function f_icmpv6_get_header(icmp_pkt : t_slv_arr)
    return t_icmpv6_header is
    variable v_header : t_icmpv6_header;
  begin
    assert icmp_pkt'ascending report "f_icmpv6_get_header: packet array must be ascending" severity C_SEVERITY;
    assert icmp_pkt(ICMP_pkt'low)'length = 8 report "f_icmpv6_get_header: packet array must be 8bit" severity C_SEVERITY;

    v_header.icmp_type := icmp_pkt(0);
    v_header.icmp_code := icmp_pkt(1);
    v_header.chksum    := icmp_pkt(2) & icmp_pkt(3);
    return v_header;
  end function f_icmpv6_get_header;

  -------------------------------------------------------------------------------
  -- Get ICMP payload (internal)
  --@cond functions
  -------------------------------------------------------------------------------
  function f_icmpv6_get_payload(icmp_pkt   : t_slv_arr;
                                get_length : boolean := false)
    return t_slv_arr is
    variable v_header : t_icmpv6_header;
    variable v_len    : natural;
    variable v_data   : t_slv_arr(0 to icmp_pkt'length - 1)(7 downto 0);
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    assert icmp_pkt'ascending report "f_icmpv6_get_payload: packet array must be ascending" severity C_SEVERITY;
    assert icmp_pkt(icmp_pkt'low)'length = 8 report "f_icmpv6_get_payload: packet array must be 8bit" severity C_SEVERITY;
    assert icmp_pkt'length >= 8 report "f_icmpv6_get_payload: ICMP packet must be at least 8 bytes" severity C_SEVERITY;

    -- extract header
    v_header               := f_icmpv6_get_header(icmp_pkt);
    -- calculate payload length
    v_len                  := icmp_pkt'length - 4;
    v_data(0 to v_len - 1) := icmp_pkt(4 to 4 + v_len - 1);
    if get_length then                  -- return length of payload only
      v_length(0) := std_logic_vector(to_unsigned(v_len, 31));
      return v_length;
    end if;
    return v_data(0 to v_len - 1);
  end function f_icmpv6_get_payload;
  -- @endcond

  -------------------------------------------------------------------------------
  --! \brief Get ICMP payload
  --! \param icmp_pkt   ICMP packet (8bit)
  --! \return           t_slv_arr
  --!
  --! Extract ICMP payload from ICMP packet. 
  --!
  --! **Example use**
  --! ~~~
  --! v_len                     := f_icmpv6_get_payload_len(data_array_8bit); 
  --! v_payload(0 to v_len - 1) := f_icmpv6_get_payload(data_array_8bit); 
  --! ~~~
  -------------------------------------------------------------------------------
  function f_icmpv6_get_payload(icmp_pkt : t_slv_arr)
    return t_slv_arr is
  begin
    return f_icmpv6_get_payload(icmp_pkt, false);
  end function f_icmpv6_get_payload;

  -------------------------------------------------------------------------------
  --! \brief Get ICMP payload length
  --! \param icmp_pkt  ICMP packet (8bit)
  --! \return          ICMP payload length
  --!
  --! Get ICMP payload length from ICMP packet. 
  --!
  --! **Example use**
  --! ~~~
  --! v_len := f_icmpv6_get_payload_len(data_array_8bit); -- determine size of payload
  --! ~~~
  -------------------------------------------------------------------------------
  function f_icmpv6_get_payload_len(icmp_pkt : t_slv_arr)
    return natural is
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    if icmp_pkt'length <= 4 then
      return 0;
    end if;
    v_length := f_icmpv6_get_payload(icmp_pkt, true);
    return to_integer(unsigned(v_length(0)));
  end function f_icmpv6_get_payload_len;

  -------------------------------------------------------------------------------
  --! \brief Check ICMP checksum
  --! \param ipv6_header    IPv6 header (required for checksum calculation)
  --! \param icmp_pkt       ICMP packet (8bit)
  --! \param routing_header IPv6 routing extension header (default none)
  --! \return               Checksum is OK (True), or not (False)
  --!
  --! Check checksum of ICMP packet. 
  --!
  --! **Example use**
  --! ~~~
  --! v_check := f_icmpv6_chksum_ok(v_ipv6_header, icmp_pkt); 
  --! ~~~
  -------------------------------------------------------------------------------
  function f_icmpv6_chksum_ok(ipv6_header    : t_ipv6_header;
                              icmp_pkt       : t_slv_arr;
                              routing_header : t_extension_header := C_DEFAULT_EXT_HEADER)
    return boolean is
    variable v_chksum  : std_logic_vector(15 downto 0);
    variable v_pseudo  : t_slv_arr(0 to 39)(7 downto 0) := (others => x"00");
    variable v_len_slv : std_logic_vector(15 downto 0)  := std_logic_vector(to_unsigned(icmp_pkt'length, 16));
  begin
    assert icmp_pkt'ascending report "f_icmpv6_chksum_ok: packet array must be ascending" severity C_SEVERITY;
    assert icmp_pkt(icmp_pkt'low)'length = 8 report "f_icmpv6_chksum_ok: packet array must be 8bit" severity C_SEVERITY;

    -- pseudo-header
    v_pseudo(0 to 15) := ipv6_header.src_addr(0 to 15);
    if routing_header.header_type = C_IPV6_ROUTE then  -- use final destination
    -- TODO
    else
      v_pseudo(16 to 31) := ipv6_header.dest_addr(0 to 15);
    end if;
    v_pseudo(34) := v_len_slv(15 downto 8);
    v_pseudo(35) := v_len_slv(7 downto 0);
    v_pseudo(39) := C_IPV6_ICMP;
    -- checksum
    v_chksum     := not f_gen_chksum(f_repack(f_concat(v_pseudo, icmp_pkt), 16), 16);
    if v_chksum = x"0000" then
      return true;
    else
      return false;
    end if;
  end function f_icmpv6_chksum_ok;

end package body nw_icmpv6_pkg;
