-------------------------------------------------------------------------------
-- Title      : Network Wizard PTPv2 package
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: 
--!\file
--!\brief PTPv2 library.
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

--! \page nw_ptp PTP Library
--! \tableofcontents
--! \section IEEE1588v2
--! The PTP library provides functions for creating and manipulating IEEE1588v2 packets.
--!
--! \subsection ptp_subsec1 Functionality
--! \li Create PTPv2 messages
--! \li Extract PTPv2 messages
--!
--! \n More details in \ref nw_ptpv2_pkg
--! \subsection ptp_subsec2 Example use
--! Include the libraries:
--! ~~~
--! library nw_util;
--! context nw_util.nw_util_context;
--! library nw_ptp;
--! use nw_ptp.nw_ptpv2.all;
--! library ne_ethernet;
--! context nw_ethernet.nw_ethernet_context;
--! ~~~
--! In many other NetWiz protocols a packet consists of a header and a payload. The PTP packet (or message) is contained completely in a record.
--! ~~~
--! variable v_msg : t_ptpv2_msg; -- message record
--! variable v_len : natural;
--! variable v_pkt : t_slv_arr(0 to 127)(7 downto 0);
--! ~~~
--! Example 1: Create a Sync message in an Ethernet packet.
--! ~~~
--! v_msg                              := C_DEFAULT_PTPV2_MSG; -- copy default msg
--! v_msg.header.message_type          := C_MSG_SYNC; -- Sync message
--! v_msg.header.sequence_id           := x"1234"; -- Sequence ID
--! v_msg.origin_timestamp.seconds     := x"0000511003fc"; -- seconds
--! v_msg.origin_timestamp.nanoseconds := x"0188fa34";-- nanoseconds
--! -- PTP message record is ready, now setup Ethernet header
--! v_eth_header           := C_DEFAULT_ETH_HEADER;
--! v_eth_header.mac_dest  := f_eth_mac_2_slv_arr("01:1b:19:00:00:00"); -- IEEE1588 broadcast MAC
--! v_eth_header.ethertype := C_ET_PTP; -- PTP over Ethernet
--! -- Create Ethernet packet with Sync message
--! v_len                := f_eth_create_pkt_len(v_eth_header, f_ptpv2_create_pkt(v_msg)); -- get length of packet
--! v_pkt(0 to v_len -1) := f_eth_create_pkt(v_eth_header, f_ptpv2_create_pkt(v_msg)); -- v_pkt now holds Ethernet+Sync
--! ~~~
--! See further examples in the test bench nw_ptp_tb.vhd.
package nw_ptpv2_pkg is

  -------------------------------------------------------------------------------
  -- Type definitions
  -- PTPv2 message header record - contains common fields for all PTP messages.
  -------------------------------------------------------------------------------
  type t_ptpv2_header is record
    transport_specific   : std_logic_vector(3 downto 0);  --! transportSpecific
    message_type         : std_logic_vector(3 downto 0);  --! messageType
    reserved_4           : std_logic_vector(3 downto 0);  --! reserved
    version_ptp          : std_logic_vector(3 downto 0);  --! versionPTP
    message_length       : std_logic_vector(15 downto 0);  --! messageLength
    domain_number        : std_logic_vector(7 downto 0);  --! domainNumber
    reserved_8           : std_logic_vector(7 downto 0);  --! reserved
    flag_field           : std_logic_vector(15 downto 0);  --! flagField
    correction_field     : std_logic_vector(63 downto 0);  --! correctionField
    reserved_32          : std_logic_vector(31 downto 0);  --! reserved
    source_port_identity : t_slv_arr(0 to 9)(7 downto 0);  --! sourcePortIdentity
    sequence_id          : std_logic_vector(15 downto 0);  --! seuenceID
    control_field        : std_logic_vector(7 downto 0);  --! controlField
    log_message_interval : std_logic_vector(7 downto 0);  --! logMessageInterval
  end record t_ptpv2_header;

  -- Timestamp record - used for all timestamp fields
  type t_timestamp is record
    seconds     : std_logic_vector(47 downto 0);  --! seconds
    nanoseconds : std_logic_vector(31 downto 0);  --! nanoseconds
  end record t_timestamp;

  -- Message record - contains all PTP message fields. Each message type only uses specific fields. 
  type t_ptpv2_msg is record
    header                    : t_ptpv2_header;                --! PTPv2 header (used by all messages)
    -- used by Sync, Follow_up, Pdelay_req, Delay_req
    origin_timestamp          : t_timestamp;  --! originTimestamp
    --  used by Delay_resp
    receive_timestamp         : t_timestamp;  --! receiveTimestamp
    -- used by Delay_resp, Pdelay_Resp, Pdelay_Resp_Follow_Up
    requesting_port_identity  : t_slv_arr(0 to 9)(7 downto 0);  --! requestingPortIdentity
    -- used by Pdelay_Resp_Follow_Up
    response_origin_timestamp : t_timestamp;  --! receiveTimestamp
    -- used by Pdelay_Req
    reserved_80               : t_slv_arr(0 to 9)(7 downto 0);  --! reserved
    -- used by Pdelay_Resp
    request_receipt_timestamp : t_timestamp;  --! requestReceiptTimestamp
    -- used by Announce
    current_utc_offset        : std_logic_vector(15 downto 0);  --! currentUTCoffset
    grandmaster_priority_1    : std_logic_vector(7 downto 0);  --! grandmasterPriority1 
    grandmaster_clock_quality : std_logic_vector(31 downto 0);  --! grandmasterClockQuality
    grandmaster_priority_2    : std_logic_vector(7 downto 0);  --! grandmasterPriority2
    grandmaster_identity      : t_slv_arr(0 to 7)(7 downto 0);  --! grandmasterIdentity  
    steps_removed             : std_logic_vector(15 downto 0);  --! stepsRemoved
    time_source               : std_logic_vector(7 downto 0);  --! timeSource
    -- used by Signalling, Management
    target_port_identity      : t_slv_arr(0 to 9)(7 downto 0);  --! targetPortIdentity
    -- used by Management
    starting_boundary_hops    : std_logic_vector(7 downto 0);  --! startingBoundaryHops
    boundary_hops             : std_logic_vector(7 downto 0);  --! boundaryHops
    reserved_4                : std_logic_vector(3 downto 0);  --! reserved
    action_field              : std_logic_vector(3 downto 0);  --! actionField
    -- used by Announce, Management
    reserved_8                : std_logic_vector(7 downto 0);  --! reserved
    -- TLV data
    tlv_data                  : t_slv_arr(0 to C_PTPV2_MAX_TLV_BYTES - 1)(7 downto 0);  --! TLV data
    tlv_length                : natural range 0 to C_PTPV2_MAX_TLV_BYTES;  --! TLV data length
  end record t_ptpv2_msg;

  -------------------------------------------------------------------------------
  -- Constants
  --!@cond constants
  -------------------------------------------------------------------------------
  constant C_ACC_25NS               : std_logic_vector(7 downto 0) := x"20";
  constant C_ACC_100NS              : std_logic_vector(7 downto 0) := x"21";
  constant C_ACC_250NS              : std_logic_vector(7 downto 0) := x"22";
  constant C_ACC_1US                : std_logic_vector(7 downto 0) := x"23";
  constant C_ACC_2_5US              : std_logic_vector(7 downto 0) := x"24";
  constant C_ACC_10US               : std_logic_vector(7 downto 0) := x"25";
  constant C_ACC_25US               : std_logic_vector(7 downto 0) := x"26";
  constant C_ACC_100US              : std_logic_vector(7 downto 0) := x"27";
  constant C_ACC_250US              : std_logic_vector(7 downto 0) := x"28";
  constant C_ACC_1MS                : std_logic_vector(7 downto 0) := x"29";
  constant C_ACC_2_5MS              : std_logic_vector(7 downto 0) := x"2A";
  constant C_ACC_10MS               : std_logic_vector(7 downto 0) := x"2B";
  constant C_ACC_25MS               : std_logic_vector(7 downto 0) := x"2C";
  constant C_ACC_100MS              : std_logic_vector(7 downto 0) := x"2D";
  constant C_ACC_250MS              : std_logic_vector(7 downto 0) := x"2E";
  constant C_ACC_1S                 : std_logic_vector(7 downto 0) := x"2F";
  constant C_ACC_10S                : std_logic_vector(7 downto 0) := x"30";
  constant C_ACC_10SPLUS            : std_logic_vector(7 downto 0) := x"31";
  constant C_ACC_UNKNOWN            : std_logic_vector(7 downto 0) := x"FE";
  -- message types
  constant C_MSG_SYNC               : std_logic_vector(3 downto 0) := x"0";
  constant C_MSG_DELAY_REQ          : std_logic_vector(3 downto 0) := x"1";
  constant C_MSG_PDELAY_REQ         : std_logic_vector(3 downto 0) := x"2";
  constant C_MSG_PDELAY_RESP        : std_logic_vector(3 downto 0) := x"3";
  constant C_MSG_FOLLOW_UP          : std_logic_vector(3 downto 0) := x"8";
  constant C_MSG_DELAY_RESP         : std_logic_vector(3 downto 0) := x"9";
  constant C_MSG_PDELAY_RESP_FUP    : std_logic_vector(3 downto 0) := x"a";
  constant C_MSG_ANNOUNCE           : std_logic_vector(3 downto 0) := x"b";
  constant C_MSG_SIGNALING          : std_logic_vector(3 downto 0) := x"c";
  constant C_MSG_MANAGEMENT         : std_logic_vector(3 downto 0) := x"d";
  constant C_MSG_RESERVED           : std_logic_vector(3 downto 0) := x"f";
  -- flags
  constant C_PTP_SECURITY           : std_logic_vector(15 downto 0)                      := x"8000";
  constant C_PTP_PROFILE_SPECIFIC_2 : std_logic_vector(15 downto 0)                      := x"4000";
  constant C_PTP_PROFILE_SPECIFIC_1 : std_logic_vector(15 downto 0)                      := x"2000";
  constant C_PTP_UNICAST            : std_logic_vector(15 downto 0)                      := x"0400";
  constant C_PTP_TWO_STEP           : std_logic_vector(15 downto 0)                      := x"0200";
  constant C_PTP_ALTERNATE_MASTER   : std_logic_vector(15 downto 0)                      := x"0100";
  constant C_FREQUENCY_TRACEABLE    : std_logic_vector(15 downto 0)                      := x"0020";
  constant C_TIME_TRACEABLE         : std_logic_vector(15 downto 0)                      := x"0010";
  constant C_PTP_TIMESCALE          : std_logic_vector(15 downto 0)                      := x"0008";
  constant C_PTP_UTC_OFFSET_VALID   : std_logic_vector(15 downto 0)                      := x"0004";
  constant C_PTP_LI_59              : std_logic_vector(15 downto 0)                      := x"0002";
  constant C_PTP_LI_61              : std_logic_vector(15 downto 0)                      := x"0001";

  constant C_DEFAULT_PTPV2_HEADER : t_ptpv2_header := (transport_specific   => x"0",
                                                       message_type         => C_MSG_RESERVED,
                                                       reserved_4           => x"0",
                                                       version_ptp          => x"2",
                                                       message_length       => x"0022",
                                                       domain_number        => x"00",
                                                       reserved_8           => x"00",
                                                       flag_field           => x"0000",
                                                       correction_field     => (others => '0'),
                                                       reserved_32          => x"00000000",
                                                       source_port_identity => (others => x"00"),
                                                       sequence_id          => x"0000",
                                                       control_field        => x"00",
                                                       log_message_interval => x"00");

  constant C_DEFAULT_TIMESTAMP : t_timestamp := (seconds     => (others => '0'),
                                                 nanoseconds => (others => '0'));

  constant C_DEFAULT_PTPV2_MSG : t_ptpv2_msg := (header                    => C_DEFAULT_PTPV2_HEADER,
                                                 origin_timestamp          => C_DEFAULT_TIMESTAMP,
                                                 receive_timestamp         => C_DEFAULT_TIMESTAMP,
                                                 requesting_port_identity  => (others => x"00"),
                                                 response_origin_timestamp => C_DEFAULT_TIMESTAMP,
                                                 reserved_80               => (others => x"00"),
                                                 request_receipt_timestamp => C_DEFAULT_TIMESTAMP,
                                                 current_utc_offset        => x"0000",
                                                 grandmaster_priority_1    => x"00",
                                                 grandmaster_clock_quality => x"00000000",
                                                 grandmaster_priority_2    => x"00",
                                                 grandmaster_identity      => (others => x"00"),
                                                 steps_removed             => x"0000",
                                                 time_source               => x"00",
                                                 target_port_identity      => (others => x"00"),
                                                 starting_boundary_hops    => x"00",
                                                 boundary_hops             => x"00",
                                                 reserved_4                => x"0",
                                                 action_field              => x"0",
                                                 reserved_8                => x"00",
                                                 tlv_data                  => (others => x"00"),
                                                 tlv_length                => 0);
  --!@endcond

  -------------------------------------------------------------------------------
  -- Functions
  --!@cond functions
  -------------------------------------------------------------------------------
  function f_ptpv2_create_pkt(message : t_ptpv2_msg) return t_slv_arr;

  function f_ptpv2_create_pkt_len(message : t_ptpv2_msg) return natural;

  function f_ptpv2_get_msg(ptp_pkt : t_slv_arr) return t_ptpv2_msg;
  --!@endcond

end package nw_ptpv2_pkg;

package body nw_ptpv2_pkg is

  -------------------------------------------------------------------------------
  --! Create PTPv2 message (internal)
  -------------------------------------------------------------------------------
  function f_ptpv2_create_pkt(message    : t_ptpv2_msg;
                              get_length : boolean := false)
    return t_slv_arr is
    variable v_data   : t_slv_arr(0 to 64 + C_PTPV2_MAX_TLV_BYTES)(7 downto 0);
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
    variable v_len    : natural := 34;
  begin
    -- assemble message
    v_data(0) := message.header.transport_specific & message.header.message_type;
    v_data(1) := message.header.reserved_4 & message.header.version_ptp;
    v_data(2) := message.header.message_length(15 downto 8);
    v_data(3) := message.header.message_length(7 downto 0);
    v_data(4) := message.header.domain_number;
    v_data(5) := message.header.reserved_8;
    v_data(6) := message.header.flag_field(15 downto 8);
    v_data(7) := message.header.flag_field(7 downto 0);
    for i in 0 to 7 loop
      v_data(8 + i) := message.header.correction_field((8 - i) * 8 - 1 downto (7 - i) * 8);
    end loop;
    for i in 0 to 3 loop
      v_data(16 + i) := message.header.reserved_32((4 - i) * 8 - 1 downto (3 - i) * 8);
    end loop;
    for i in 0 to 9 loop
      v_data(20 + i) := message.header.source_port_identity(i);
    end loop;
    v_data(30) := message.header.sequence_id(15 downto 8);
    v_data(31) := message.header.sequence_id(7 downto 0);
    v_data(32) := message.header.control_field;
    v_data(33) := message.header.log_message_interval;
    case message.header.message_type is
      -- 
      when C_MSG_SYNC | C_MSG_DELAY_REQ | C_MSG_FOLLOW_UP =>
        for i in 0 to 5 loop
          v_data(34 + i) := message.origin_timestamp.seconds((6 - i) * 8 - 1 downto (5 - i) * 8);
        end loop;
        for i in 0 to 3 loop
          v_data(40 + i) := message.origin_timestamp.nanoseconds((4 - i) * 8 - 1 downto (3 - i) * 8);
        end loop;
        v_len := v_len + 10;
      -- 
      when C_MSG_PDELAY_REQ =>
        for i in 0 to 5 loop
          v_data(34 + i) := message.origin_timestamp.seconds((6 - i) * 8 - 1 downto (5 - i) * 8);
        end loop;
        for i in 0 to 3 loop
          v_data(40 + i) := message.origin_timestamp.nanoseconds((4 - i) * 8 - 1 downto (3 - i) * 8);
        end loop;
        for i in 0 to 9 loop
          v_data(44 + i) := message.reserved_80(i);
        end loop;
        v_len := v_len + 20;
      --
      when C_MSG_PDELAY_RESP =>
        for i in 0 to 5 loop
          v_data(34 + i) := message.request_receipt_timestamp.seconds((6 - i) * 8 - 1 downto (5 - i) * 8);
        end loop;
        for i in 0 to 3 loop
          v_data(40 + i) := message.request_receipt_timestamp.nanoseconds((4 - i) * 8 - 1 downto (3 - i) * 8);
        end loop;
        for i in 0 to 9 loop
          v_data(44 + i) := message.requesting_port_identity(i);
        end loop;
        v_len := v_len + 20;
      --
      when C_MSG_DELAY_RESP =>
        for i in 0 to 5 loop
          v_data(34 + i) := message.receive_timestamp.seconds((6 - i) * 8 - 1 downto (5 - i) * 8);
        end loop;
        for i in 0 to 3 loop
          v_data(40 + i) := message.receive_timestamp.nanoseconds((4 - i) * 8 - 1 downto (3 - i) * 8);
        end loop;
        for i in 0 to 9 loop
          v_data(44 + i) := message.requesting_port_identity(i);
        end loop;
        v_len := v_len + 20;
      --
      when C_MSG_PDELAY_RESP_FUP =>
        for i in 0 to 5 loop
          v_data(34 + i) := message.response_origin_timestamp.seconds((6 - i) * 8 - 1 downto (5 - i) * 8);
        end loop;
        for i in 0 to 3 loop
          v_data(40 + i) := message.response_origin_timestamp.nanoseconds((4 - i) * 8 - 1 downto (3 - i) * 8);
        end loop;
        for i in 0 to 9 loop
          v_data(44 + i) := message.requesting_port_identity(i);
        end loop;
        v_len := v_len + 20;
      --
      when C_MSG_ANNOUNCE =>
        for i in 0 to 5 loop
          v_data(34 + i) := message.origin_timestamp.seconds((6 - i) * 8 - 1 downto (5 - i) * 8);
        end loop;
        for i in 0 to 3 loop
          v_data(40 + i) := message.origin_timestamp.nanoseconds((4 - i) * 8 - 1 downto (3 - i) * 8);
        end loop;
        v_data(44) := message.current_utc_offset(15 downto 8);
        v_data(45) := message.current_utc_offset(7 downto 0);
        v_data(46) := message.reserved_8;
        v_data(47) := message.grandmaster_priority_1;
        for i in 0 to 3 loop
          v_data(48 + i) := message.grandmaster_clock_quality((4 - i) * 8 - 1 downto (3 - i) * 8);
        end loop;
        v_data(52) := message.grandmaster_priority_2;
        for i in 0 to 7 loop
          v_data(53 + i) := message.grandmaster_identity(i);
        end loop;
        v_data(61) := message.steps_removed(15 downto 8);
        v_data(62) := message.steps_removed(7 downto 0);
        v_data(63) := message.time_source;
        v_len      := v_len + 30;
      -- 
      when C_MSG_SIGNALING =>
        for i in 0 to 9 loop
          v_data(34 + i) := message.target_port_identity(i);
        end loop;
        if message.tlv_length > 0 then
          for i in 0 to message.tlv_length - 1 loop
            v_data(44 + i) := message.tlv_data(i);
          end loop;
        end if;
        v_len := v_len + 10 + message.tlv_length;
      --
      when C_MSG_MANAGEMENT =>
        for i in 0 to 9 loop
          v_data(34 + i) := message.target_port_identity(i);
        end loop;
        v_data(44) := message.starting_boundary_hops;
        v_data(45) := message.boundary_hops;
        v_data(46) := message.reserved_4 & message.action_field;
        v_data(47) := message.reserved_8;
        if message.tlv_length > 0 then
          for i in 0 to message.tlv_length - 1 loop
            v_data(48 + i) := message.tlv_data(i);
          end loop;
        end if;
        v_len := v_len + 14 + message.tlv_length;
      --
      when others =>
        null;
    end case;
    -- result
    if get_length then
      v_length(0) := std_logic_vector(to_unsigned(v_len, 31));
      return v_length;
    else
      return v_data(0 to v_len - 1);
    end if;
  end function f_ptpv2_create_pkt;

  -------------------------------------------------------------------------------
  --! \brief Create PTPv2 message
  --! \param message    PTPv2 message (record)
  --! \return           PTPv2 message (8bit array)
  --!
  --! Create PTPv2 message from message record. 
  --!
  --! **Example use**
  --! ~~~
  --! v_msg  := C_DEFAULT_PTPV2_MSG;
  --! v_data := f_ptpv2_create_pkt(v_msg);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_ptpv2_create_pkt(message : t_ptpv2_msg)
    return t_slv_arr is
  begin
    return f_ptpv2_create_pkt(message, false);
  end function f_ptpv2_create_pkt;

  ------------------------------------------------------------------------------
  --! \brief Return length of PTPv2 message.
  --! \param message    PTPv2 message (record)
  --! \return           Length of PTP message
  --!
  --! Return the length of the created PTP message.
  --!
  --! **Example use**
  --! ~~~
  --! v_len                  := f_ptpv2_create_pkt_len(v_msg); 
  --! v_data(0 to v_len - 1) := f_ptpv2_create_pkt(v_msg);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_ptpv2_create_pkt_len(message : t_ptpv2_msg)
    return natural is
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    v_length := f_ptpv2_create_pkt(message, true);
    return to_integer(unsigned(v_length(0)));
  end function f_ptpv2_create_pkt_len;

  -------------------------------------------------------------------------------
  --! \brief Get PTP message
  --! \param ptp_pkt  PTPv2 message (8bit)
  --! \return         PTPv2 message (record)
  --!
  --! Extract PTPv2 message from payload. 
  --!
  --! **Example use**
  --! ~~~
  --! v_ptp_msg := f_ptpv2_get_msg(data_array_8bit); 
  --! ~~~
  -------------------------------------------------------------------------------
  function f_ptpv2_get_msg(ptp_pkt : t_slv_arr)
    return t_ptpv2_msg is
    variable v_msg     : t_ptpv2_msg := C_DEFAULT_PTPV2_MSG;
    variable v_idx     : natural     := ptp_pkt'low;
    variable v_tlv_len : natural;
  begin
    assert ptp_pkt'ascending report "f_ptpv2_get_msg: PTP packet must be ascending" severity C_SEVERITY;
    assert ptp_pkt'length >= 34 report "f_ptpv2_get_msg: PTP packet must be at least 34 bytes" severity C_SEVERITY;

    -- common header
    v_msg.header.transport_specific          := ptp_pkt(v_idx)(7 downto 4);
    v_msg.header.message_type                := ptp_pkt(v_idx)(3 downto 0);
    v_msg.header.reserved_4                  := ptp_pkt(v_idx + 1)(7 downto 4);
    v_msg.header.version_ptp                 := ptp_pkt(v_idx + 1)(3 downto 0);
    v_msg.header.message_length(15 downto 8) := ptp_pkt(v_idx + 2);
    v_msg.header.message_length(7 downto 0)  := ptp_pkt(v_idx + 3);
    v_msg.header.domain_number               := ptp_pkt(v_idx + 4);
    v_msg.header.reserved_8                  := ptp_pkt(v_idx + 5);
    v_msg.header.flag_field(15 downto 8)     := ptp_pkt(v_idx + 6);
    v_msg.header.flag_field(7 downto 0)      := ptp_pkt(v_idx + 7);
    for i in 0 to 7 loop
      v_msg.header.correction_field((8 - i) * 8 - 1 downto (7 - i) * 8) := ptp_pkt(v_idx + 8 + i);
    end loop;
    for i in 0 to 3 loop
      v_msg.header.reserved_32((4 - i) * 8 - 1 downto (3 - i) * 8) := ptp_pkt(v_idx + 16 + i);
    end loop;
    for i in 0 to 9 loop
      v_msg.header.source_port_identity(i) := ptp_pkt(v_idx + 20 + i);
    end loop;
    v_msg.header.sequence_id(15 downto 8) := ptp_pkt(v_idx + 30);
    v_msg.header.sequence_id(7 downto 0)  := ptp_pkt(v_idx + 31);
    v_msg.header.control_field            := ptp_pkt(v_idx + 32);
    v_msg.header.log_message_interval     := ptp_pkt(v_idx + 33);
    -- message specific fields
    case v_msg.header.message_type is
      -- 
      when C_MSG_SYNC | C_MSG_DELAY_REQ | C_MSG_FOLLOW_UP =>
        assert ptp_pkt'length >= 44 report "f_ptpv2_get_msg: Sync, Delay_req and Follow_up must be at least 44 bytes" severity C_SEVERITY;
        for i in 0 to 5 loop
          v_msg.origin_timestamp.seconds((6 - i) * 8 - 1 downto (5 - i) * 8) := ptp_pkt(v_idx + 34 + i);
        end loop;
        for i in 0 to 3 loop
          v_msg.origin_timestamp.nanoseconds((4 - i) * 8 - 1 downto (3 - i) * 8) := ptp_pkt(v_idx + 40 + i);
        end loop;
      -- 
      when C_MSG_PDELAY_REQ =>
        assert ptp_pkt'length >= 54 report "f_ptpv2_get_msg: PDelay_req must be at least 54 bytes" severity C_SEVERITY;
        for i in 0 to 5 loop
          v_msg.origin_timestamp.seconds((6 - i) * 8 - 1 downto (5 - i) * 8) := ptp_pkt(v_idx + 34 + i);
        end loop;
        for i in 0 to 3 loop
          v_msg.origin_timestamp.nanoseconds((4 - i) * 8 - 1 downto (3 - i) * 8) := ptp_pkt(v_idx + 40 + i);
        end loop;
        for i in 0 to 9 loop
          v_msg.reserved_80(i) := ptp_pkt(v_idx + 44 + i);
        end loop;
      --
      when C_MSG_PDELAY_RESP =>
        assert ptp_pkt'length >= 54 report "f_ptpv2_get_msg: PDelay_resp must be at least 54 bytes" severity C_SEVERITY;
        for i in 0 to 5 loop
          v_msg.request_receipt_timestamp.seconds((6 - i) * 8 - 1 downto (5 - i) * 8) := ptp_pkt(v_idx + 34 + i);
        end loop;
        for i in 0 to 3 loop
          v_msg.request_receipt_timestamp.nanoseconds((4 - i) * 8 - 1 downto (3 - i) * 8) := ptp_pkt(v_idx + 40 + i);
        end loop;
        for i in 0 to 9 loop
          v_msg.requesting_port_identity(i) := ptp_pkt(v_idx + 44 + i);
        end loop;
      --
      when C_MSG_DELAY_RESP =>
        assert ptp_pkt'length >= 54 report "f_ptpv2_get_msg: Delay_resp must be at least 54 bytes" severity C_SEVERITY;
        for i in 0 to 5 loop
          v_msg.receive_timestamp.seconds((6 - i) * 8 - 1 downto (5 - i) * 8) := ptp_pkt(v_idx + 34 + i);
        end loop;
        for i in 0 to 3 loop
          v_msg.receive_timestamp.nanoseconds((4 - i) * 8 - 1 downto (3 - i) * 8) := ptp_pkt(v_idx + 40 + i);
        end loop;
        for i in 0 to 9 loop
          v_msg.requesting_port_identity(i) := ptp_pkt(v_idx + 44 + i);
        end loop;
      --
      when C_MSG_PDELAY_RESP_FUP =>
        assert ptp_pkt'length >= 54 report "f_ptpv2_get_msg: PDelay_resp_follow_up must be at least 54 bytes" severity C_SEVERITY;
        for i in 0 to 5 loop
          v_msg.response_origin_timestamp.seconds((6 - i) * 8 - 1 downto (5 - i) * 8) := ptp_pkt(v_idx + 34 + i);
        end loop;
        for i in 0 to 3 loop
          v_msg.response_origin_timestamp.nanoseconds((4 - i) * 8 - 1 downto (3 - i) * 8) := ptp_pkt(v_idx + 40 + i);
        end loop;
        for i in 0 to 9 loop
          v_msg.requesting_port_identity(i) := ptp_pkt(v_idx + 44 + i);
        end loop;
      --
      when C_MSG_ANNOUNCE =>
        assert ptp_pkt'length >= 64 report "f_ptpv2_get_msg: Announce must be at least 64 bytes" severity C_SEVERITY;
        for i in 0 to 5 loop
          v_msg.origin_timestamp.seconds((6 - i) * 8 - 1 downto (5 - i) * 8) := ptp_pkt(v_idx + 34 + i);
        end loop;
        for i in 0 to 3 loop
          v_msg.origin_timestamp.nanoseconds((4 - i) * 8 - 1 downto (3 - i) * 8) := ptp_pkt(v_idx + 40 + i);
        end loop;
        v_msg.current_utc_offset(15 downto 8) := ptp_pkt(v_idx + 44);
        v_msg.current_utc_offset(7 downto 0)  := ptp_pkt(v_idx + 45);
        v_msg.reserved_8                      := ptp_pkt(v_idx + 46);
        v_msg.grandmaster_priority_1          := ptp_pkt(v_idx + 47);
        for i in 0 to 3 loop
          v_msg.grandmaster_clock_quality((4 - i) * 8 - 1 downto (3 - i) * 8) := ptp_pkt(v_idx + 48 + i);
        end loop;
        v_msg.grandmaster_priority_2 := ptp_pkt(v_idx + 52);
        for i in 0 to 7 loop
          v_msg.grandmaster_identity(i) := ptp_pkt(v_idx + 53 + i);
        end loop;
        v_msg.steps_removed(15 downto 8) := ptp_pkt(v_idx + 61);
        v_msg.steps_removed(7 downto 0)  := ptp_pkt(v_idx + 62);
        v_msg.time_source                := ptp_pkt(v_idx + 63);
      -- 
      when C_MSG_SIGNALING =>
        assert ptp_pkt'length >= 44 report "f_ptpv2_get_msg: Signaling must be at least 44 bytes" severity C_SEVERITY;
        for i in 0 to 9 loop
          v_msg.target_port_identity(i) := ptp_pkt(v_idx + 34 + i);
        end loop;
        v_tlv_len := minimum(to_integer(unsigned(v_msg.header.message_length)) - 34, ptp_pkt'length - 34);
        if v_tlv_len > 0 then
          v_msg.tlv_length := minimum(v_tlv_len, C_PTPV2_MAX_TLV_BYTES);
          for i in 0 to v_msg.tlv_length - 1 loop
            v_msg.tlv_data(i) := ptp_pkt(v_idx + 44 + i);
          end loop;
        end if;
      --
      when C_MSG_MANAGEMENT =>
        assert ptp_pkt'length >= 48 report "f_ptpv2_get_msg: Management must be at least 48 bytes" severity C_SEVERITY;
        for i in 0 to 9 loop
          v_msg.target_port_identity(i) := ptp_pkt(v_idx + 34 + i);
        end loop;
        v_msg.starting_boundary_hops := ptp_pkt(v_idx + 44);
        v_msg.boundary_hops          := ptp_pkt(v_idx + 45);
        v_msg.reserved_4             := ptp_pkt(v_idx + 46)(7 downto 4);
        v_msg.action_field           := ptp_pkt(v_idx + 46)(3 downto 0);
        v_msg.reserved_8             := ptp_pkt(v_idx + 47);
        v_tlv_len                    := minimum(to_integer(unsigned(v_msg.header.message_length)) - 34, ptp_pkt'length - 34);
        if v_tlv_len > 0 then
          v_msg.tlv_length := minimum(v_tlv_len, C_PTPV2_MAX_TLV_BYTES);
          for i in 0 to v_msg.tlv_length - 1 loop
            v_msg.tlv_data(i) := ptp_pkt(v_idx + 48 + i);
          end loop;
        end if;
      when others =>
        null;
    end case;

    return v_msg;
  end function f_ptpv2_get_msg;

end package body nw_ptpv2_pkg;
