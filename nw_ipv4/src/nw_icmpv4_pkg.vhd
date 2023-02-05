-------------------------------------------------------------------------------
-- Title      : Network Wizard ICMPv4 package
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: 
--!\file
--!\brief ICMPv4 library.
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
--! @endcond

--! \page nw_icmpv4 ICMP
--! \tableofcontents
--! \section icmpv4 ICMP for IPv4
--! The ICMPv4 library provides functions for creating and manipulation ICMP packets. 
--! \subsection icmpv4_subsec1 Functionality
--! \li Create ICMP packets of any length
--! \li Create and extract ICMP headers
--! \li Verify checksum of ICMP packets
--!
--! \n\n More details in \ref nw_icmpv4_pkg
--! \subsection icmpv4_subsec2 Example use
--! Include the libraries:
--! ~~~
--! library nw_util;
--! context nw_util.nw_util_context;
--! library nw_ipv4;
--! context nw_ipv4.nw_ipv4_context;
--! ~~~
--! Assume the variable \c v_payload contains the ICMP payload. The variables are defined:
--! ~~~
--! variable v_header   : t_icmpv4_header; -- ICMP header record
--! variable v_payload  : t_slv_arr(0 to 31)(7 downto 0);
--! variable v_icmp_pkt : t_slv_arr(0 to 39)(7 downto 0); -- byte array
--! variable v_len      : natural;
--! ~~~
--! First setup the header, then calculate the total ICMP packet length before creating the packet. 
--! ~~~
--! v_header                   := C_DEFAULT_ICMPV4_HEADER; -- copy default header (ping request)
--! v_payload                  := f_gen_nrs(x"80", 32); -- payload contents
--! v_len                      := f_icmpv4_create_pkt_len(v_header, v_payload); -- calculate total packet length
--! v_icmp_pkt(0 to v_len - 1) := f_icmpv4_create_pkt(v_header, v_payload); -- create the packet (no checksum)
--! ~~~
--! The variable \c v_icmp_pkt is an 8-bit array. This can of course be rearranged to any word width with \c f_repack().
--! ~~~
--! v_icmpv4_pkt_32 := f_repack(v_icmp_pkt, 32, C_MSB_FIRST); -- repack to 32bit words (padded with zeros if required)
--! ~~~
--! See further examples in the test bench nw_ipv4_tb.vhd.
package nw_icmpv4_pkg is

  -------------------------------------------------------------------------------
  -- Records
  -------------------------------------------------------------------------------
  type t_icmpv4_header is record
    icmp_type  : std_logic_vector(7 downto 0);   --! ICMP type
    icmp_code  : std_logic_vector(7 downto 0);   --! ICMP subtype
    chksum     : std_logic_vector(15 downto 0);  --! Checksum
    ext_header : std_logic_vector(31 downto 0);  -- ! Extended header
  end record t_icmpv4_header;

  -------------------------------------------------------------------------------
  -- Constants
  --!@cond constants
  -------------------------------------------------------------------------------
  constant C_ICMPV4_ECHO_REPLY      : std_logic_vector(7 downto 0) := x"00";  -- Echo reply
  constant C_ICMPV4_DEST_UNREACH    : std_logic_vector(7 downto 0) := x"03";  -- Destination unreachable
  constant C_ICMPV4_REDIRECT        : std_logic_vector(7 downto 0) := x"05";  -- Redirect message
  constant C_ICMPV4_ECHO_REQUEST    : std_logic_vector(7 downto 0) := x"08";  -- Echo request
  constant C_ICMPV4_ROUTER_ADV      : std_logic_vector(7 downto 0) := x"09";  -- Router advertisment
  constant C_ICMPV4_ROUTER_SOLIC    : std_logic_vector(7 downto 0) := x"0a";  -- Router Solicitation
  constant C_ICMPV4_TIME_EXCEEDED   : std_logic_vector(7 downto 0) := x"0b";  -- Time exceeded
  constant C_ICMPV4_PARAM_PROB      : std_logic_vector(7 downto 0) := x"0c";  -- Parameter Problem: Bad IP header
  constant C_ICMPV4_TIMESTAMP       : std_logic_vector(7 downto 0) := x"0d";  -- Timestamp
  constant C_ICMPV4_TIMESTAMP_REPLY : std_logic_vector(7 downto 0) := x"0e";  -- Timestamp reply
  constant C_ICMPV4_TIMESTAMP_REQ   : std_logic_vector(7 downto 0) := x"0f";  -- Timestamp request
  constant C_ICMPV4_EXT_ECHO_REQ    : std_logic_vector(7 downto 0) := x"2a";  --  Extended Echo Request
  constant C_ICMPV4_EXT_ECHO_REPLY  : std_logic_vector(7 downto 0) := x"2b";  --  Extended Echo Reply

  constant C_DEFAULT_ICMPV4_HEADER : t_icmpv4_header := (icmp_type => C_ICMPV4_ECHO_REQUEST, icmp_code => x"00", chksum => x"0000", ext_header => x"00000000");

  constant C_ICMPV4_EMPTY : t_slv_arr(0 to 0)(7 downto 0) := (others => x"00");  -- empty payload 
  --! @endcond

  -------------------------------------------------------------------------------
  -- Functions
  --!@cond functions
  -------------------------------------------------------------------------------
  function f_icmpv4_create_pkt(icmp_header : t_icmpv4_header;
                               payload     : t_slv_arr) return t_slv_arr;

  function f_icmpv4_create_pkt(icmp_header : t_icmpv4_header) return t_slv_arr;

  function f_icmpv4_create_pkt_len(icmp_header : t_icmpv4_header) return natural;

  function f_icmpv4_create_pkt_len(icmp_header : t_icmpv4_header;
                                   payload     : t_slv_arr) return natural;

  function f_icmpv4_get_header(icmp_pkt : t_slv_arr) return t_icmpv4_header;

  function f_icmpv4_get_payload(icmp_pkt : t_slv_arr) return t_slv_arr;

  function f_icmpv4_get_payload_len(icmp_pkt : t_slv_arr) return natural;

  function f_icmpv4_chksum_ok(icmp_pkt : t_slv_arr) return boolean;
  --! @endcond

end package nw_icmpv4_pkg;

package body nw_icmpv4_pkg is

  -------------------------------------------------------------------------------
  -- Create ICMPv4 packet (internal)
  --@cond functions
  -------------------------------------------------------------------------------
  function f_icmpv4_create_pkt(icmp_header : t_icmpv4_header;
                               add_payload : boolean;
                               payload     : t_slv_arr;
                               get_length  : boolean)
    return t_slv_arr is
    variable v_len    : natural                               := 8 + payload'length;
    variable v_data   : t_slv_arr(0 to v_len - 1)(7 downto 0) := (others => x"00");
    variable v_chksum : std_logic_vector(15 downto 0);
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    assert payload'ascending report "f_icmpv4_create_pkt: payload array must be ascending" severity C_SEVERITY;
    assert payload(payload'low)'length = 8 report "f_icmpv4_create_pkt: payload must be 8bit" severity C_SEVERITY;

    -- header
    v_len          := 8;
    v_data(0)      := icmp_header.icmp_type(7 downto 0);
    v_data(1)      := icmp_header.icmp_code(7 downto 0);
    v_data(2 to 3) := (others => x"00");
    v_data(4)      := icmp_header.ext_header(31 downto 24);
    v_data(5)      := icmp_header.ext_header(23 downto 16);
    v_data(6)      := icmp_header.ext_header(15 downto 8);
    v_data(7)      := icmp_header.ext_header(7 downto 0);
    -- payload
    if add_payload then
      for i in 0 to payload'length - 1 loop
        v_data(8 + i) := payload(payload'low + i);
      end loop;
      v_len := v_len + payload'length;
    end if;
    -- checksum
    v_chksum  := not f_gen_chksum(f_repack(v_data(0 to v_len - 1), 16), 16);
    v_data(2) := v_chksum(15 downto 8);
    v_data(3) := v_chksum(7 downto 0);
    -- result
    if get_length then
      v_length(0) := std_logic_vector(to_unsigned(v_len, 31));
      return v_length;
    else
      return v_data(0 to v_len - 1);
    end if;
  end function f_icmpv4_create_pkt;
  -- @endcond

  -------------------------------------------------------------------------------
  --! \brief Create ICMPv4 packet
  --! \param icmp_header ICMP header
  --! \param payload     ICMP payload
  --! \return            ICMP packet (8bit array) or length of ICMP packet
  --!
  --! Create ICMPv4 packet. Payload must be 8bit data array. 
  --!
  --! **Example use**
  --! ~~~
  --! v_packet_8bit  := f_icmpv4_create_pkt(C_DEFAULT_ICMPV4_HEADER); -- echo request
  --! v_packet2_8bit := f_icmpv4_create_pkt(C_DEFAULT_ICMPV4_HEADER, payload); -- with payload
  --! ~~~
  -------------------------------------------------------------------------------
  function f_icmpv4_create_pkt(icmp_header : t_icmpv4_header;
                               payload     : t_slv_arr)
    return t_slv_arr is
  begin
    return f_icmpv4_create_pkt(icmp_header, true, payload, false);
  end function f_icmpv4_create_pkt;

  -------------------------------------------------------------------------------
  --! \brief Create ICMPv4 packet (no payload)
  --! \param icmp_header ICMP header
  --! \return            ICMP packet (8bit array) or length of ICMP packet
  --!
  --! Create ICMPv4 packet. Payload must be 8bit data array. 
  --!
  --! **Example use**
  --! ~~~
  --! v_packet_8bit  := f_icmpv4_create_pkt(C_DEFAULT_ICMPV4_HEADER); -- echo request
  --! ~~~
  -------------------------------------------------------------------------------
  function f_icmpv4_create_pkt(icmp_header : t_icmpv4_header)
    return t_slv_arr is
  begin
    return f_icmpv4_create_pkt(icmp_header, false, C_ICMPV4_EMPTY, false);
  end function f_icmpv4_create_pkt;

  -------------------------------------------------------------------------------
  --! \brief Return length of ICMP packet.
  --! \param icmp_header ICMP header
  --! \param payload    ICMP payload
  --! \return           Length of ICMP packet
  --!
  --! Return the length of the created ICMP packet.
  --!
  --! **Example use**
  --! ~~~
  --! v_len                      := f_icmpv4_create_pkt_len(v_icmp_header, payload); 
  --! v_pkt_8bit(0 to v_len - 1) := f_icmpv4_create_pkt(v_icmp_header, payload);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_icmpv4_create_pkt_len(icmp_header : t_icmpv4_header;
                                   payload     : t_slv_arr)
    return natural is
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    v_length := f_icmpv4_create_pkt(icmp_header, true, payload, true);
    return to_integer(unsigned(v_length(0)));
  end function f_icmpv4_create_pkt_len;

  -------------------------------------------------------------------------------
  --! \brief Return length of ICMP packet (no payload)
  --! \param icmp_header ICMP header
  --! \return           Length of ICMP packet
  --!
  --! Return the length of the created ICMP packet.
  --!
  --! **Example use**
  --! ~~~
  --! v_len                      := f_icmpv4_create_pkt_len(v_icmp_header); 
  --! v_pkt_8bit(0 to v_len - 1) := f_icmpv4_create_pkt(v_icmp_header);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_icmpv4_create_pkt_len(icmp_header : t_icmpv4_header)
    return natural is
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    v_length := f_icmpv4_create_pkt(icmp_header, false, C_ICMPV4_EMPTY, true);
    return to_integer(unsigned(v_length(0)));
  end function f_icmpv4_create_pkt_len;

  -------------------------------------------------------------------------------
  --! \brief Get ICMP header
  --! \param icmp_pkt ICMP packet (8bit)
  --! \return         ICMP header
  --!
  --! Extract ICMP header from ICMP packet. 
  --!
  --! **Example use**
  --! ~~~
  --! v_icmp_header := f_icmpv4_get_header(data_array_8bit); 
  --! ~~~
  -------------------------------------------------------------------------------
  function f_icmpv4_get_header(icmp_pkt : t_slv_arr)
    return t_icmpv4_header is
    variable v_header : t_icmpv4_header;
  begin
    assert icmp_pkt'ascending report "f_icmpv4_get_header: packet array must be ascending" severity C_SEVERITY;
    assert icmp_pkt(ICMP_pkt'low)'length = 8 report "f_icmpv4_get_header: packet array must be 8bit" severity C_SEVERITY;

    v_header.icmp_type  := icmp_pkt(0);
    v_header.icmp_code  := icmp_pkt(1);
    v_header.chksum     := icmp_pkt(2) & icmp_pkt(3);
    v_header.ext_header := icmp_pkt(4) & icmp_pkt(5) & icmp_pkt(6) & icmp_pkt(7);
    return v_header;
  end function f_icmpv4_get_header;

  -------------------------------------------------------------------------------
  -- Get ICMP payload (internal)
  --@cond functions
  -------------------------------------------------------------------------------
  function f_icmpv4_get_payload(icmp_pkt   : t_slv_arr;
                                get_length : boolean := false)
    return t_slv_arr is
    variable v_header : t_icmpv4_header;
    variable v_len    : natural;
    variable v_data   : t_slv_arr(0 to icmp_pkt'length - 1)(7 downto 0);
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    assert icmp_pkt'ascending report "f_icmpv4_get_payload: packet array must be ascending" severity C_SEVERITY;
    assert icmp_pkt(icmp_pkt'low)'length = 8 report "f_icmpv4_get_payload: packet array must be 8bit" severity C_SEVERITY;
    assert icmp_pkt'length > 8 report "f_icmpv4_get_payload: ICMP packet must be at least 9 bytes" severity C_SEVERITY;

    -- extract header
    v_header               := f_icmpv4_get_header(icmp_pkt);
    -- calculate payload length
    v_len                  := icmp_pkt'length - 8;
    v_data(0 to v_len - 1) := icmp_pkt(8 to 7 + v_len);
    if get_length then                  -- return length of payload only
      v_length(0) := std_logic_vector(to_unsigned(v_len, 31));
      return v_length;
    end if;
    return v_data(0 to v_len - 1);
  end function f_icmpv4_get_payload;
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
  --! v_len                     := f_icmpv4_get_payload_len(data_array_8bit); 
  --! v_payload(0 to v_len - 1) := f_icmpv4_get_payload(data_array_8bit); 
  --! ~~~
  -------------------------------------------------------------------------------
  function f_icmpv4_get_payload(icmp_pkt : t_slv_arr)
    return t_slv_arr is
  begin
    return f_icmpv4_get_payload(icmp_pkt, false);
  end function f_icmpv4_get_payload;

  -------------------------------------------------------------------------------
  --! \brief Get ICMP payload length
  --! \param icmp_pkt  ICMP packet (8bit)
  --! \return          ICMP payload length
  --!
  --! Get ICMP payload length from ICMP packet. 
  --!
  --! **Example use**
  --! ~~~
  --! v_len := f_icmpv4_get_payload_len(data_array_8bit); -- determine size of payload
  --! ~~~
  -------------------------------------------------------------------------------
  function f_icmpv4_get_payload_len(icmp_pkt : t_slv_arr)
    return natural is
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    if icmp_pkt'length < 9 then
      return 0;
    end if;
    v_length := f_icmpv4_get_payload(icmp_pkt, true);
    return to_integer(unsigned(v_length(0)));
  end function f_icmpv4_get_payload_len;

  -------------------------------------------------------------------------------
  --! \brief Check ICMP checksum
  --! \param icmp_pkt    ICMP packet (8bit)
  --! \return            Checksum is OK (True), or not (False)
  --!
  --! Check checksum of ICMP packet. 
  --!
  --! **Example use**
  --! ~~~
  --! v_check := f_icmpv4_chksum_ok(data_array_8bit); 
  --! ~~~
  -------------------------------------------------------------------------------
  function f_icmpv4_chksum_ok(icmp_pkt : t_slv_arr)
    return boolean is
    variable v_chksum : std_logic_vector(15 downto 0);
    variable v_pseudo : t_slv_arr(0 to 11)(7 downto 0) := (others => x"00");
  begin
    assert ICMP_pkt'ascending report "f_icmpv4_chksum_ok: packet array must be ascending" severity C_SEVERITY;
    assert ICMP_pkt(ICMP_pkt'low)'length = 8 report "f_icmpv4_chksum_ok: packet array must be 8bit" severity C_SEVERITY;

    v_chksum := not f_gen_chksum(f_repack(icmp_pkt, 16), 16);
    if v_chksum = x"0000" then
      return true;
    else
      return false;
    end if;
  end function f_icmpv4_chksum_ok;

end package body nw_icmpv4_pkg;
