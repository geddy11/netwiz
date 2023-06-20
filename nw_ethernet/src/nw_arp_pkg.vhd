-------------------------------------------------------------------------------
-- Title      : Network Wizard ARP package
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: 
--!\file
--!\brief ARP library.
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

use work.nw_ethernet_pkg.all;
--! @endcond

--! \page nw_arp ARP
--! \tableofcontents
--! \section ARP Address Resolution Protocol
--! The ethernet library provides functions for creating and checking ethernet packets.
--!
--! \subsection arp_subsec1 Functionality
--! \li Create ARP packets
--! \li Extract ARP headers
--!
--! \n More details in \ref nw_arp_pkg
--! \subsection arp_subsec2 Example use
--! Include the libraries:
--! ~~~
--! library nw_util;
--! context nw_util.nw_util_context;
--! library nw_ethernet;
--! context nw_ethernet.nw_ethernet_context;
--! ~~~
--! Define a few variables:
--! ~~~
--! variable v_header  : t_arp_header; -- header record
--! variable v_arp_pkt : t_slv_arr(0 to 27)(7 downto 0); -- byte array
--! variable v_len     : natural;
--! ~~~
--! First setup the header, then calculate the total ethernet packet length before creating the packet.
--! ~~~
--! v_header                  := C_DEFAULT_ARP_HEADER; -- copy default header
--! v_header.sender_hw_addr   := f_eth_mac_2_slv_arr("08:00:27:27:1a:d5"); -- change sender MAC
--! v_len                     := f_arp_create_pkt_len(v_header); -- calculate total packet length (28)
--! v_arp_pkt(0 to v_len - 1) := f_arp_create_pkt(v_header); -- create the ARP packet
--! ~~~
--! Next step is to can be to put the ARP packet into an Ethernet frame:
--! ~~~
--! v_eth_header              := C_DEFAULT_ETH_HEADER;
--! v_len                     := f_eth_create_pkt_len(v_eth_header, v_arp_pkt); -- calculate total packet length
--! v_eth_pkt(0 to v_len - 1) := f_eth_create_pkt(v_eth_header, v_arp_pkt); -- create the packet
--! ~~~
--! See further examples in the test bench nw_ethernet_tb.vhd.
package nw_arp_pkg is

  -------------------------------------------------------------------------------
  -- Type definitions
  -------------------------------------------------------------------------------
  type t_arp_header is record
    htype                : std_logic_vector(15 downto 0);  --! Hardware type
    ptype                : std_logic_vector(15 downto 0);  --! Protocol type
    hlen                 : std_logic_vector(7 downto 0);  --! Hardware address length
    plen                 : std_logic_vector(7 downto 0);  --! Protocol address length 
    operation            : std_logic_vector(15 downto 0);  --! Operation
    sender_hw_addr       : std_logic_vector(47 downto 0);  --! Sender hardware address
    sender_protocol_addr : std_logic_vector(31 downto 0);  --! Sender protocol address
    target_hw_addr       : std_logic_vector(47 downto 0);  --! Target hardware address
    target_protocol_addr : std_logic_vector(31 downto 0);  --! Target protocol address
  end record t_arp_header;

  -------------------------------------------------------------------------------
  -- Constants
  --!@cond constants
  -------------------------------------------------------------------------------
  constant C_OP_RESERVED               : std_logic_vector(15 downto 0) := x"0000";
  constant C_OP_REQUEST                : std_logic_vector(15 downto 0) := x"0001";
  constant C_OP_REPLY                  : std_logic_vector(15 downto 0) := x"0002";
  constant C_OP_REQUEST_REVERSE        : std_logic_vector(15 downto 0) := x"0003";
  constant C_OP_REPLY_REVERSE          : std_logic_vector(15 downto 0) := x"0004";
  constant C_OP_DRARP_REQUEST          : std_logic_vector(15 downto 0) := x"0005";
  constant C_OP_DRARP_REPLY            : std_logic_vector(15 downto 0) := x"0006";
  constant C_OP_DRARP_ERROR            : std_logic_vector(15 downto 0) := x"0007";
  constant C_OP_INARP_REQUEST          : std_logic_vector(15 downto 0) := x"0008";
  constant C_OP_INARP_REPLY            : std_logic_vector(15 downto 0) := x"0009";
  constant C_OP_ARP_NAK                : std_logic_vector(15 downto 0) := x"000A";
  constant C_OP_MARS_REQUEST           : std_logic_vector(15 downto 0) := x"000B";
  constant C_OP_MARS_MULTI             : std_logic_vector(15 downto 0) := x"000C";
  constant C_OP_MARS_MSERV             : std_logic_vector(15 downto 0) := x"000D";
  constant C_OP_MARS_JOIN              : std_logic_vector(15 downto 0) := x"000E";
  constant C_OP_MARS_LEAVE             : std_logic_vector(15 downto 0) := x"000F";
  constant C_OP_MARS_NAK               : std_logic_vector(15 downto 0) := x"0010";
  constant C_OP_MARS_UNSERV            : std_logic_vector(15 downto 0) := x"0011";
  constant C_OP_MARS_SJOIN             : std_logic_vector(15 downto 0) := x"0012";
  constant C_OP_MARS_SLEAVE            : std_logic_vector(15 downto 0) := x"0013";
  constant C_OP_MARS_GROUPLIST_REQUEST : std_logic_vector(15 downto 0) := x"0014";
  constant C_OP_MARS_GROUPLIST_REPLY   : std_logic_vector(15 downto 0) := x"0015";
  constant C_OP_MARS_REDIRECT_MAP      : std_logic_vector(15 downto 0) := x"0016";
  constant C_OP_MAPOS_UNARP            : std_logic_vector(15 downto 0) := x"0017";
  constant C_OP_OP_EXP1                : std_logic_vector(15 downto 0) := x"0018";
  constant C_OP_OP_EXP2                : std_logic_vector(15 downto 0) := x"0019";

  constant C_HTYPE_RESERVED                                : std_logic_vector(15 downto 0) := x"0000";
  constant C_HTYPE_ETHERNET                                : std_logic_vector(15 downto 0) := x"0001";
  constant C_HTYPE_EXPERIMENTAL_ETHERNET                   : std_logic_vector(15 downto 0) := x"0002";
  constant C_HTYPE_AMATEUR_RADIO_AX_25                     : std_logic_vector(15 downto 0) := x"0003";
  constant C_HTYPE_PROTEON_PRONET_TOKEN_RING               : std_logic_vector(15 downto 0) := x"0004";
  constant C_HTYPE_CHAOS                                   : std_logic_vector(15 downto 0) := x"0005";
  constant C_HTYPE_IEEE_802_NETWORKS                       : std_logic_vector(15 downto 0) := x"0006";
  constant C_HTYPE_ARCNET                                  : std_logic_vector(15 downto 0) := x"0007";
  constant C_HTYPE_HYPERCHANNEL                            : std_logic_vector(15 downto 0) := x"0008";
  constant C_HTYPE_LANSTAR                                 : std_logic_vector(15 downto 0) := x"0009";
  constant C_HTYPE_AUTONET_SHORT_ADDRESS                   : std_logic_vector(15 downto 0) := x"000A";
  constant C_HTYPE_LOCALTALK                               : std_logic_vector(15 downto 0) := x"000B";
  constant C_HTYPE_LOCALNET                                : std_logic_vector(15 downto 0) := x"000C";
  constant C_HTYPE_ULTRA_LINK                              : std_logic_vector(15 downto 0) := x"000D";
  constant C_HTYPE_SMDS                                    : std_logic_vector(15 downto 0) := x"000E";
  constant C_HTYPE_FRAME_RELAY                             : std_logic_vector(15 downto 0) := x"000F";
  constant C_HTYPE_ATM                                     : std_logic_vector(15 downto 0) := x"0010";
  constant C_HTYPE_HDLC                                    : std_logic_vector(15 downto 0) := x"0011";
  constant C_HTYPE_FIBRE_CHANNEL                           : std_logic_vector(15 downto 0) := x"0012";
  constant C_HTYPE_ATM2                                    : std_logic_vector(15 downto 0) := x"0013";
  constant C_HTYPE_SERIAL_LINE                             : std_logic_vector(15 downto 0) := x"0014";
  constant C_HTYPE_ATM3                                    : std_logic_vector(15 downto 0) := x"0015";
  constant C_HTYPE_MIL_STD_188_220                         : std_logic_vector(15 downto 0) := x"0016";
  constant C_HTYPE_METRICOM                                : std_logic_vector(15 downto 0) := x"0017";
  constant C_HTYPE_IEEE_1394                               : std_logic_vector(15 downto 0) := x"0018";
  constant C_HTYPE_MAPOS                                   : std_logic_vector(15 downto 0) := x"0019";
  constant C_HTYPE_TWINAXIAL                               : std_logic_vector(15 downto 0) := x"001A";
  constant C_HTYPE_EUI_64                                  : std_logic_vector(15 downto 0) := x"001B";
  constant C_HTYPE_HIPARP                                  : std_logic_vector(15 downto 0) := x"001C";
  constant C_HTYPE_IP_AND_ARP_OVER_ISO_7816_3              : std_logic_vector(15 downto 0) := x"001D";
  constant C_HTYPE_ARPSEC                                  : std_logic_vector(15 downto 0) := x"001E";
  constant C_HTYPE_IPSEC_TUNNEL                            : std_logic_vector(15 downto 0) := x"001F";
  constant C_HTYPE_INFINIBAND                              : std_logic_vector(15 downto 0) := x"0020";
  constant C_HTYPE_TIA_102_PROJECT_25_COMMON_AIR_INTERFACE : std_logic_vector(15 downto 0) := x"0021";
  constant C_HTYPE_WIEGAND_INTERFACE                       : std_logic_vector(15 downto 0) := x"0022";
  constant C_HTYPE_PURE_IP                                 : std_logic_vector(15 downto 0) := x"0023";
  constant C_HTYPE_HW_EXP1                                 : std_logic_vector(15 downto 0) := x"0024";
  constant C_HTYPE_HFI                                     : std_logic_vector(15 downto 0) := x"0025";
  constant C_HTYPE_UNIFIED_BUS                             : std_logic_vector(15 downto 0) := x"0026";
  constant C_HTYPE_HWEXP2                                  : std_logic_vector(15 downto 0) := x"0100";
  constant C_HTYPE_AETHERNET                               : std_logic_vector(15 downto 0) := x"0101";

  constant C_DEFAULT_ARP_HEADER : t_arp_header := (htype                => C_HTYPE_ETHERNET, ptype => C_ET_IPV4, hlen => x"06", plen => x"06",
                                                   operation            => C_OP_REQUEST, sender_hw_addr => x"7c10c9161c56",
                                                   sender_protocol_addr => x"c0a800a7",
                                                   target_hw_addr       => x"000000000000", target_protocol_addr => x"c0a800b5");
  --!@endcond

  -------------------------------------------------------------------------------
  -- Functions
  --!@cond functions
  -------------------------------------------------------------------------------
  function f_arp_create_pkt(header     : t_arp_header) return t_slv_arr;

  function f_arp_create_pkt_len(header : t_arp_header) return natural;

  function f_arp_get_header(arp_pkt : t_slv_arr) return t_arp_header;
  --!@endcond

end package nw_arp_pkg;

package body nw_arp_pkg is

  -------------------------------------------------------------------------------
  -- Create ARP packet (internal)
  --!@cond functions
  -------------------------------------------------------------------------------
  function f_arp_create_pkt(header     : t_arp_header;
                            get_length : boolean := false)
    return t_slv_arr is
    variable v_data   : t_slv_arr(0 to 27)(7 downto 0);
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    -- assemble packet
    v_data(0) := header.htype(15 downto 8);
    v_data(1) := header.htype(7 downto 0);
    v_data(2) := header.ptype(15 downto 8);
    v_data(3) := header.ptype(7 downto 0);
    v_data(4) := header.hlen;
    v_data(5) := header.plen;
    v_data(6) := header.operation(15 downto 8);
    v_data(7) := header.operation(7 downto 0);
    for i in 0 to 5 loop
      v_data(8 + i)  := header.sender_hw_addr((6 - i) * 8 - 1 downto (5 - i) * 8);
      v_data(18 + i) := header.target_hw_addr((6 - i) * 8 - 1 downto (5 - i) * 8);
    end loop;
    for i in 0 to 3 loop
      v_data(14 + i) := header.sender_protocol_addr((4 - i) * 8 - 1 downto (3 - i) * 8);
      v_data(24 + i) := header.target_protocol_addr((4 - i) * 8 - 1 downto (3 - i) * 8);
    end loop;
    -- result
    if get_length then
      v_length(0) := std_logic_vector(to_unsigned(28, 31));
      return v_length;
    else
      return v_data;
    end if;
  end function f_arp_create_pkt;
  --!@endcond

  -------------------------------------------------------------------------------
  --! \brief Create ARP packet
  --! \param header     ARP header
  --! \return           ARP packet (8bit array)
  --!
  --! Create ARP packet. 
  --!
  --! **Example use**
  --! ~~~
  --! v_arp_header  := C_DEFAULT_ARP_HEADER;
  --! v_packet_8bit := f_arp_create_pkt(v_arp_header);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_arp_create_pkt(header     : t_arp_header)
    return t_slv_arr is
    begin
      return f_arp_create_pkt(header, false);
    end function f_arp_create_pkt;

  ------------------------------------------------------------------------------
  --! \brief Return length of ARP packet.
  --! \param header     ARP header
  --! \return           Length of ARP packet
  --!
  --! Return the length of the created ARP packet.
  --!
  --! **Example use**
  --! ~~~
  --! v_len                      := f_arp_create_pkt_len(v_arp_header); 
  --! v_pkt_8bit(0 to v_len - 1) := f_arp_create_pkt(v_arp_header);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_arp_create_pkt_len(header : t_arp_header)
    return natural is
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    v_length := f_arp_create_pkt(header, true);
    return to_integer(unsigned(v_length(0)));
  end function f_arp_create_pkt_len;

  -------------------------------------------------------------------------------
  --! \brief Get ARP header
  --! \param arp_pkt  ARP packet (8bit)
  --! \return         ARP header
  --!
  --! Extract ARP header from ARP packet. 
  --!
  --! **Example use**
  --! ~~~
  --! v_arp_header := f_arp_get_header(data_array_8bit); 
  --! ~~~
  -------------------------------------------------------------------------------
  function f_arp_get_header(arp_pkt : t_slv_arr)
    return t_arp_header is
    variable v_header : t_arp_header;
    variable v_idx    : natural := arp_pkt'low;
  begin
    assert arp_pkt'ascending report "f_arp_get_header: ARP packet must be ascending" severity C_SEVERITY;
    assert arp_pkt'length >= 28 report "f_arp_get_header: ARP packet must be at least 14 bytes" severity C_SEVERITY;

    v_header.htype(15 downto 8)     := arp_pkt(v_idx + 0);
    v_header.htype(7 downto 0)      := arp_pkt(v_idx + 1);
    v_header.ptype(15 downto 8)     := arp_pkt(v_idx + 2);
    v_header.ptype(7 downto 0)      := arp_pkt(v_idx + 3);
    v_header.hlen                   := arp_pkt(v_idx + 4);
    v_header.plen                   := arp_pkt(v_idx + 5);
    v_header.operation(15 downto 8) := arp_pkt(v_idx + 6);
    v_header.operation(7 downto 0)  := arp_pkt(v_idx + 7);
    for i in 0 to 5 loop
      v_header.sender_hw_addr((6 - i) * 8 - 1 downto (5 - i) * 8) := arp_pkt(v_idx + 8 + i);
      v_header.target_hw_addr((6 - i) * 8 - 1 downto (5 - i) * 8) := arp_pkt(v_idx + 18 + i);
    end loop;
    for i in 0 to 3 loop
      v_header.sender_protocol_addr((4 - i) * 8 - 1 downto (3 - i) * 8) := arp_pkt(v_idx + 14 + i);
      v_header.target_protocol_addr((4 - i) * 8 - 1 downto (3 - i) * 8) := arp_pkt(v_idx + 24 + i);
    end loop;

    return v_header;
  end function f_arp_get_header;

end package body nw_arp_pkg;
