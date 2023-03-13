-------------------------------------------------------------------------------
-- Title      : Network Wizard USB package
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: 
--!\file
--!\brief USB library.
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

--! \page nw_usb USB Library
--! \tableofcontents
--! \section USB
--! This library provides functions for creating and extracting USB v1 and v2 packets.
--!
--! \subsection usb_subsec1 Functionality
--! \li Create USB packets
--! \li Extract USB packets
--! \li Packet types: Token, Start-of-Frame, Data, Handshake, Split Transaction
--!
--! \n More details in \ref nw_usb_pkg
--! \subsection usb_subsec2 Example use
--! Include the libraries:
--! ~~~
--! library nw_util;
--! context nw_util.nw_util_context;
--! library nw_usb;
--! context nw_usb.nw_usb_context;
--! ~~~
--! In many other NetWiz protocols a packet consists of a header and a payload. The USB packet is contained completely in a record.
--! The CRC5 or CRC16 is added according to packet type.
--! ~~~
--! variable v_usb_pkt : t_usb_packet; -- packet record
--! variable v_len     : natural;
--! variable v_pkt     : t_slv_arr(0 to 127)(7 downto 0); -- data array
--! ~~~
--! Example 1: Create a data packet.
--! ~~~
--! v_usb_pkt                       := C_DEFAULT_USB_PACKET; -- copy default packet
--! v_usb_pkt.pkt_type              := DATA; -- define the type of packet to create
--! v_usb_pkt.data_pkt.data(0 to 5) := (x"01", x"02", x"33", x"44", x"50", x"06"); -- set the data packet payload (6 bytes)
--! v_usb_pkt.data_pkt.data_len     := 6; -- set the data length
--! v_len                           := f_usb_create_pkt_len(v_usb_pkt); -- get length of USB packet (optional)
--! v_pkt(0 to v_len - 1)           := f_usb_create_pkt(v_usb_pkt); -- v_pkt now holds the USB packet in 8bit format
--! ~~~
--! See further examples in the test bench nw_usb_tb.vhd.
package nw_usb_pkg is

  -------------------------------------------------------------------------------
  -- Type definitions
  -- USB message header record - contains common fields for all PTP messages.
  -------------------------------------------------------------------------------
  type t_usb_pkt_type is (DATA, SOF, TOKEN, SPLIT, HANDSHAKE);  --! USB packet type

  type t_usb_data_pkt is record
    pid      : std_logic_vector(7 downto 0);      --! PID
    data     : t_slv_arr(0 to 1023)(7 downto 0);  --! data
    data_len : natural range 0 to 1024;           --! Data length (bytes)
    crc16    : std_logic_vector(15 downto 0);     --! CRC16
  end record t_usb_data_pkt;

  type t_usb_sof_pkt is record
    pid          : std_logic_vector(7 downto 0);   --! PID
    frame_number : std_logic_vector(10 downto 0);  --! Frame number
    crc5         : std_logic_vector(4 downto 0);   --! CRC5
  end record t_usb_sof_pkt;

  type t_usb_handshake_pkt is record
    pid : std_logic_vector(7 downto 0);  --! PID
  end record t_usb_handshake_pkt;

  type t_usb_token_pkt is record
    pid  : std_logic_vector(7 downto 0);  --! PID
    addr : std_logic_vector(6 downto 0);  --! Address
    endp : std_logic_vector(3 downto 0);  --! Endpoint
    crc5 : std_logic_vector(4 downto 0);  --! CRC5
  end record t_usb_token_pkt;

  type t_usb_split_pkt is record
    pid         : std_logic_vector(7 downto 0);  --! PID
    hub_addr    : std_logic_vector(6 downto 0);  --! Hub address
    sc          : std_logic;            --! Start/complete
    port_number : std_logic_vector(6 downto 0);  --! port number
    s           : std_logic;            --! Start
    e_u         : std_logic;  --! End (start-split) / Unused (complete-split)
    et          : std_logic_vector(1 downto 0);  --! Endpoint type
    crc5        : std_logic_vector(4 downto 0);  --! CRC5
  end record t_usb_split_pkt;

  type t_usb_packet is record
    pkt_type      : t_usb_pkt_type;     --! USB packet type contained in record
    data_pkt      : t_usb_data_pkt;     --! Data packet record
    sof_pkt       : t_usb_sof_pkt;      --! SOF packet record
    handshake_pkt : t_usb_handshake_pkt;  --! Handshake record
    token_pkt     : t_usb_token_pkt;    --! Token record
    split_pkt     : t_usb_split_pkt;    --! Start/complete-split token record
  end record t_usb_packet;

  -------------------------------------------------------------------------------
  -- Constants
  --!@cond constants
  -------------------------------------------------------------------------------
  constant C_USB_PID_OUT   : std_logic_vector(3 downto 0) := x"1";  --! Address + endpoint number in host-to-function transaction
  constant C_USB_PID_IN    : std_logic_vector(3 downto 0) := x"9";  --! Address + endpoint number in function-to-host transaction
  constant C_USB_PID_SOF   : std_logic_vector(3 downto 0) := x"5";  --! Start-of-Frame marker and frame number
  constant C_USB_PID_SETUP : std_logic_vector(3 downto 0) := x"d";  --! Address + endpoint number in host-to-function transaction for SETUP to a control pipe
  constant C_USB_PID_DATA0 : std_logic_vector(3 downto 0) := x"3";  --! Data packet PID even
  constant C_USB_PID_DATA1 : std_logic_vector(3 downto 0) := x"b";  --! Data packet PID odd
  constant C_USB_PID_DATA2 : std_logic_vector(3 downto 0) := x"7";  --! Data packet PID high-speed
  constant C_USB_PID_MDATA : std_logic_vector(3 downto 0) := x"f";  --! Data packet PID high-speed for split
  constant C_USB_PID_ACK   : std_logic_vector(3 downto 0) := x"2";  --! Receiver accepts error-free data packet
  constant C_USB_PID_NAK   : std_logic_vector(3 downto 0) := x"a";  --! Receiving device cannot accept data or transmitting device cannot send data
  constant C_USB_PID_STALL : std_logic_vector(3 downto 0) := x"e";  --! Endpoint is halted or a control pipe request is not supported
  constant C_USB_PID_NYET  : std_logic_vector(3 downto 0) := x"6";  --! No response yet from receiver 
  constant C_USB_PID_PRE   : std_logic_vector(3 downto 0) := x"c";  --! (Token) Host-issued preamble
  constant C_USB_PID_ERR   : std_logic_vector(3 downto 0) := x"c";  --! (Handshake) Split Transaction Error Handshake
  constant C_USB_PID_SPLIT : std_logic_vector(3 downto 0) := x"8";  --! (Token) High-speed Split Transaction Token
  constant C_USB_PID_PING  : std_logic_vector(3 downto 0) := x"4";  --! (Token) High-speed flow control probe for a bulk/control endpoint

  constant C_DEFAULT_USB_DATA_PKT : t_usb_data_pkt := (pid      => C_USB_PID_DATA0 & not C_USB_PID_DATA0,
                                                       data     => (others => x"00"),
                                                       data_len => 2,
                                                       crc16    => x"0000");

  constant C_DEFAULT_USB_SOF_PKT : t_usb_sof_pkt := (pid          => C_USB_PID_SOF & not C_USB_PID_SOF,
                                                     frame_number => (others => '0'),
                                                     crc5         => "00000");

  constant C_DEFAULT_HANDSHAKE_PKT : t_usb_handshake_pkt := (pid => C_USB_PID_ACK & not C_USB_PID_ACK);

  constant C_DEFAULT_USB_TOKEN_PKT : t_usb_token_pkt := (pid  => C_USB_PID_OUT & not C_USB_PID_OUT,
                                                         addr => (others => '0'),
                                                         endp => (others => '0'),
                                                         crc5 => "00000");

  constant C_DEFAULT_USB_SPLIT_PKT : t_usb_split_pkt := (pid         => C_USB_PID_SPLIT & not C_USB_PID_SPLIT,
                                                         hub_addr    => "0001100",
                                                         sc          => '0',
                                                         port_number => "0000001",
                                                         s           => '0',
                                                         e_u         => '0',
                                                         et          => "00",
                                                         crc5        => "00000");

  constant C_DEFAULT_USB_PACKET : t_usb_packet := (pkt_type      => DATA,
                                                   data_pkt      => C_DEFAULT_USB_DATA_PKT,
                                                   sof_pkt       => C_DEFAULT_USB_SOF_PKT,
                                                   handshake_pkt => C_DEFAULT_HANDSHAKE_PKT,
                                                   token_pkt     => C_DEFAULT_USB_TOKEN_PKT,
                                                   split_pkt     => C_DEFAULT_USB_SPLIT_PKT);

  constant C_USB_CRC5  : std_logic_vector(4 downto 0)  := "00101";  --! USB CRC5 polynomial
  constant C_USB_CRC16 : std_logic_vector(15 downto 0) := "1000000000000101";  --! USB CRC16 polynomial
  --!@endcond

  -------------------------------------------------------------------------------
  -- Functions
  --!@cond functions
  -------------------------------------------------------------------------------
  function f_usb_create_pkt(pkt : t_usb_packet) return t_slv_arr;

  function f_usb_create_pkt_len(pkt : t_usb_packet) return natural;

  function f_usb_get_pkt(usb_pkt : t_slv_arr) return t_usb_packet;
  --!@endcond

end package nw_usb_pkg;

package body nw_usb_pkg is

  -------------------------------------------------------------------------------
  --! Create USB packet (internal)
  -------------------------------------------------------------------------------
  function f_usb_create_pkt(pkt        : t_usb_packet;
                            get_length : boolean := false)
    return t_slv_arr is
    variable v_data   : t_slv_arr(0 to 1023)(7 downto 0) := (others => x"00");
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
    variable v_len    : natural;
    variable v_crc5   : std_logic_vector(4 downto 0);
    variable v_crc16  : std_logic_vector(15 downto 0);
    variable v_token  : t_slv_arr(0 to 0)(10 downto 0);
    variable v_split  : t_slv_arr(0 to 0)(18 downto 0);
  begin
    v_len := 3;  -- length 3 unless otherwise defined below
    case pkt.pkt_type is
      when DATA =>
        v_data(0) := pkt.data_pkt.pid;
        if pkt.data_pkt.data_len > 0 then
          for i in 0 to pkt.data_pkt.data_len - 1 loop
            v_data(1+i) := pkt.data_pkt.data(i);
          end loop;
          v_crc16                           := not f_gen_crc(C_USB_CRC16, pkt.data_pkt.data(0 to pkt.data_pkt.data_len - 1), x"ffff", false);
          v_data(pkt.data_pkt.data_len + 1) := v_crc16(15 downto 8);
          v_data(pkt.data_pkt.data_len + 2) := v_crc16(7 downto 0);
        else
          v_data(1) := x"00";
          v_data(2) := x"00";
        end if;
        v_len := 3 + pkt.data_pkt.data_len;
      when SOF =>
        v_data(0)  := pkt.sof_pkt.pid;
        v_data(1)  := pkt.sof_pkt.frame_number(10 downto 3);
        v_token(0) := pkt.sof_pkt.frame_number;
        v_crc5     := not f_gen_crc(C_USB_CRC5, v_token, "11111");
        v_data(2)  := pkt.sof_pkt.frame_number(2 downto 0) & v_crc5;
      when TOKEN =>
        v_data(0)  := pkt.token_pkt.pid;
        v_data(1)  := pkt.token_pkt.addr & pkt.token_pkt.endp(3);
        v_token(0) := pkt.token_pkt.addr & pkt.token_pkt.endp;
        v_crc5     := not f_gen_crc(C_USB_CRC5, v_token, "11111");
        v_data(2)  := pkt.token_pkt.endp(2 downto 0) & v_crc5;
      when SPLIT =>
        v_data(0)  := pkt.split_pkt.pid;
        v_data(1)  := pkt.split_pkt.hub_addr & pkt.split_pkt.sc;
        v_data(2)  := pkt.split_pkt.port_number & pkt.split_pkt.s;
        v_split(0) := v_data(0) & v_data(1) & pkt.split_pkt.e_u & pkt.split_pkt.et;
        v_crc5     := not f_gen_crc(C_USB_CRC5, v_split, "11111");
        v_data(3)  := pkt.split_pkt.e_u & pkt.split_pkt.et & v_crc5;
        v_len      := 4;
      when HANDSHAKE =>
        v_data(0) := pkt.handshake_pkt.pid;
        v_len     := 1;
    end case;

    -- result
    if get_length then
      v_length(0) := std_logic_vector(to_unsigned(v_len, 31));
      return v_length;
    else
      return v_data(0 to v_len - 1);
    end if;
  end function f_usb_create_pkt;

  -------------------------------------------------------------------------------
  --! \brief Create USB packet
  --! \param  pkt    USB packet (record)
  --! \return        USB packet (8bit array)
  --!
  --! Create USB packet from packet record. 
  --!
  --! **Example use**
  --! ~~~
  --! v_pkt  := C_DEFAULT_USB_PACKET; -- default data packet
  --! v_data := f_usb_create_pkt(v_pkt);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_usb_create_pkt(pkt : t_usb_packet)
    return t_slv_arr is
  begin
    return f_usb_create_pkt(pkt, false);
  end function f_usb_create_pkt;

  ------------------------------------------------------------------------------
  --! \brief Return length of USB packet.
  --! \param pkt        USB packet (record)
  --! \return           Length of USB packet
  --!
  --! Return the length of the created USB packet.
  --!
  --! **Example use**
  --! ~~~
  --! v_len                  := f_usb_create_pkt_len(v_pkt); 
  --! v_data(0 to v_len - 1) := f_usb_create_pkt(v_pkt);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_usb_create_pkt_len(pkt : t_usb_packet)
    return natural is
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    v_length := f_usb_create_pkt(pkt, true);
    return to_integer(unsigned(v_length(0)));
  end function f_usb_create_pkt_len;

  -------------------------------------------------------------------------------
  --! \brief Get PTP message
  --! \param usb_pkt  USB packet (8bit)
  --! \return         USB packet (record)
  --!
  --! Extract USB packet from payload. 
  --!
  --! **Example use**
  --! ~~~
  --! v_usb_pkt := f_usb_get_pkt(data_array_8bit); 
  --! ~~~
  -------------------------------------------------------------------------------
  function f_usb_get_pkt(usb_pkt : t_slv_arr)
    return t_usb_packet is
    variable v_pkt  : t_usb_packet := C_DEFAULT_USB_PACKET;
    variable v_data : t_slv_arr(0 to usb_pkt'length - 1)(7 downto 0);
  begin
    assert usb_pkt'ascending report "f_usb_get_pkt: USB packet must be ascending" severity C_SEVERITY;
    assert usb_pkt'length >= 2 report "f_usb_get_pkt: USB packet must be at least 2 bytes" severity C_SEVERITY;
    assert usb_pkt(usb_pkt'low)'length = 8 report "f_usb_get_pkt: USB packet must be 8bit array" severity C_SEVERITY;

    v_data := usb_pkt;
    case v_data(0) is
      -- data packet
      when C_USB_PID_DATA0 & not C_USB_PID_DATA0 |
        C_USB_PID_DATA1 & not C_USB_PID_DATA1 |
        C_USB_PID_DATA2 & not C_USB_PID_DATA2 |
        C_USB_PID_MDATA & not C_USB_PID_MDATA =>
        v_pkt.pkt_type     := DATA;
        v_pkt.data_pkt.pid := v_data(0);
        if v_data'length < 3 then
          assert false report "f_usb_get_pkt: Data packet must be at least 3 bytes long" severity C_SEVERITY;
        else
          v_pkt.data_pkt.data_len := v_data'length - 3;
          if v_data'length > 3 then
            for i in 0 to v_data'length - 4 loop
              v_pkt.data_pkt.data(i) := v_data(1+i);
            end loop;
          end if;
          v_pkt.data_pkt.crc16 := v_data(v_data'length - 2) & v_data(v_data'length - 1);
        end if;
      -- handshake
      when C_USB_PID_ACK & not C_USB_PID_ACK |
        C_USB_PID_NAK & not C_USB_PID_NAK |
        C_USB_PID_STALL & not C_USB_PID_STALL |
        C_USB_PID_NYET & not C_USB_PID_NYET |
        C_USB_PID_ERR & not C_USB_PID_ERR =>
        v_pkt.pkt_type          := HANDSHAKE;
        v_pkt.handshake_pkt.pid := v_data(0);
      -- token
      when C_USB_PID_OUT & not C_USB_PID_OUT |
        C_USB_PID_IN & not C_USB_PID_IN |
        C_USB_PID_SETUP & not C_USB_PID_SETUP |
        C_USB_PID_PING & not C_USB_PID_PING =>
        v_pkt.pkt_type      := TOKEN;
        v_pkt.token_pkt.pid := v_data(0);
        if v_data'length < 2 then
          assert false report "f_usb_get_pkt: Token packet must be at least 2 bytes long" severity C_SEVERITY;
        else
          v_pkt.token_pkt.addr := v_data(1)(7 downto 1);
          v_pkt.token_pkt.endp := v_data(1)(0) & v_data(2)(7 downto 5);
          v_pkt.token_pkt.crc5 := v_data(2)(4 downto 0);
        end if;
      -- token (SOF)
      when C_USB_PID_SOF & not C_USB_PID_SOF =>
        v_pkt.pkt_type    := SOF;
        v_pkt.sof_pkt.pid := v_data(0);
        if v_data'length < 2 then
          assert false report "f_usb_get_pkt: SOF packet must be at least 2 bytes long" severity C_SEVERITY;
        else
          v_pkt.sof_pkt.frame_number := v_data(1)(7 downto 0) & v_data(2)(7 downto 5);
          v_pkt.sof_pkt.crc5         := v_data(2)(4 downto 0);
        end if;
      -- split transaction
      when C_USB_PID_SPLIT & not C_USB_PID_SPLIT =>
        v_pkt.pkt_type      := SPLIT;
        v_pkt.split_pkt.pid := v_data(0);
        if v_data'length < 4 then
          assert false report "f_usb_get_pkt: Split transaction packet must be at least 4 bytes long" severity C_SEVERITY;
        else
          v_pkt.split_pkt.hub_addr    := v_data(1)(7 downto 1);
          v_pkt.split_pkt.sc          := v_data(1)(0);
          v_pkt.split_pkt.port_number := v_data(2)(7 downto 1);
          v_pkt.split_pkt.s           := v_data(2)(0);
          v_pkt.split_pkt.e_u         := v_data(3)(7);
          v_pkt.split_pkt.et          := v_data(3)(6 downto 5);
          v_pkt.split_pkt.crc5        := v_data(3)(4 downto 0);
        end if;
      when others =>
        assert false report "f_usb_get_pkt: Unsupported PID (" & to_string(v_data(0)) & ")" severity C_SEVERITY;
    end case;

    return v_pkt;
  end function f_usb_get_pkt;

end package body nw_usb_pkg;
