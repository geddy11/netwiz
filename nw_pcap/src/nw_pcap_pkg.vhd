-------------------------------------------------------------------------------
-- Title      : Network Wizard PCAP package
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: 
--!\file
--!\brief PCAP library.
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

--! \page nw_pcap PCAP library
--! \tableofcontents
--! \section PCAP
--! The PCAP library provides functions for reading network packets from PCAP files captured by \c tcpdump, \c Wireshark etc. 
--! These packets can then be used as stimuli in test benches. 
--! A collection of PCAP files can be found at for example <a href="https://packetlife.net/captures/">PacketLife</a>.
--!
--! \subsection pcap_subsec1 Functionality
--! \li Read network packets from PCAP and PCAPNG files
--! \li Count captured packets in PCAP/PCAPNG files
--!
--! \subsection pcap_subsec2 Limitations
--! \li No support for reading metadata (use e.g. Wireshark to explore PCAP files).
--! \li Only first section in PCAPNG files can be accessed.
--!
--! \n More details in \ref nw_pcap_pkg
--! \subsection pcap_subsec3 Example use
--! Include the libraries:
--! ~~~
--! library nw_util;
--! context nw_util.nw_util_context;
--! library nw_pcap;
--! use nw_pcap.nw_pcap_pkg.all;
--! ~~~
--! Define file name of PCAP file:
--! ~~~
--! constant C_FNAME : string := "/home/user/ddos_attack.pcap";
--! ~~~
--! Now, assume we have a procedure called \c schedule_pkt() that will send a packet across an interface to the DUT. 
--! Such procedures are readily available in verification frameworks like <a href="https://github.com/UVVM/UVVM">UVVM</a>.
--! The code below will schedule all the network packets in the PCAP file for transmission in the test bench:
--! ~~~
--! for i in 0 to f_pcap_get_pkt_cnt(C_FNAME) - 1 loop
--!   schedule_pkt(f_pcap_get_pkt(C_FNAME, i, f_pcap_get_pkt_len(C_FNAME, i)));
--! end loop;
--! ~~~
--! The packets in PCAP files do not always contain all the information normally transmitted on a physical link.
--! For example captured ethernet packets do not have preamble and often not the FCS. NetWiz can fix this for supported network protocols.
--! Include ethernet library to fix captured ethernet packets:
--! ~~~
--! library nw_ethernet;
--! use nw_ethernet.nw_ethernet_pkg.all;
--! ~~~
--! Add preamble and FCS to packets before scheduling:
--! ~~~
--! for i in 0 to f_pcap_get_pkt_cnt(C_FNAME) - 1 loop
--!   v_len                     := f_pcap_get_pkt_len(C_FNAME, i); -- get length of packet #i
--!   array_8bit(0 to v_len -1) := f_pcap_get_pkt(C_FNAME, i, v_len); -- get packet
--!   v_header                  := f_eth_get_header(array_8bit(0 to v_len - 1)); -- extract header
--!   v_header.mac_dest         := f_eth_mac_2_slv_arr("a2:34:56:f1:30:00"); -- maybe modify the header
--!   schedule_pkt(f_concat(C_ETH_PREAMBLE, f_eth_create_pkt(v_header, f_eth_get_payload(array_8bit(0 to v_len -1))))); -- add preamble and FCS
--! end loop;
--! ~~~
--! See further examples in the test bench nw_pcap_tb.vhd.
package nw_pcap_pkg is

  -------------------------------------------------------------------------------
  -- Functions
  -------------------------------------------------------------------------------
  impure function f_pcap_get_pkt_cnt(name : string)
    return integer;

  impure function f_pcap_get_pkt_len(name   : string;
                                     pkt_no : natural)
    return natural;

  impure function f_pcap_get_pkt(name    : string;
                                 pkt_no  : natural;
                                 pkt_len : natural)
    return t_slv_arr;
  
end package nw_pcap_pkg;

package body nw_pcap_pkg is

  -------------------------------------------------------------------------------
  -- Type definitions
  --! @cond types
  -------------------------------------------------------------------------------
  type t_pcap_file is record
    file_type : natural;
    bigendian : boolean;
    snaplen   : natural;
  end record t_pcap_file;

  type t_file is file of character;
  --! @endcond

  -------------------------------------------------------------------------------
  -- Constants
  --! @cond constants
  -------------------------------------------------------------------------------
  constant C_PCAP_US      : std_logic_vector(31 downto 0) := x"a1b2c3d4";
  constant C_PCAP_NS      : std_logic_vector(31 downto 0) := x"a1b2c34d";
  constant C_PCAPNG_BT    : std_logic_vector(31 downto 0) := x"0a0d0d0a";
  constant C_PCAPNG       : std_logic_vector(31 downto 0) := x"1a2b3c4d";
  constant C_UNKNOWN_FILE : natural                       := 0;
  constant C_PCAP_FILE    : natural                       := 1;
  constant C_PCAPNG_FILE  : natural                       := 2;
  --! @endcond

  -------------------------------------------------------------------------------
  -- Functions (internal use)
  --! @cond functions
  -------------------------------------------------------------------------------
  impure function f_pcap_read_ftype(name : string)
    return t_pcap_file is
    file file_in     : t_file open read_mode is name;
    variable v_data  : t_slv_arr(0 to 19)(7 downto 0);
    variable v_char  : character;
    variable v_type  : t_pcap_file;
    variable v_word  : std_logic_vector(31 downto 0);
    variable v_word2 : std_logic_vector(31 downto 0);
  begin
    -- read first twenty bytes
    for i in 0 to 19 loop
      read(file_in, v_char);
      v_data(i) := std_logic_vector(to_unsigned(character'pos(v_char), 8));
    end loop;
    file_close(file_in);
    -- check filetype
    v_word           := v_data(0) & v_data(1) & v_data(2) & v_data(3);
    v_word2          := v_data(8) & v_data(9) & v_data(10) & v_data(11);
    v_type.bigendian := false;
    v_type.file_type := C_UNKNOWN_FILE;
    if v_word = C_PCAP_US or v_word = C_PCAP_NS then
      v_type.file_type := C_PCAP_FILE;
      v_type.bigendian := true;
    elsif v_word = f_swap_endian(C_PCAP_US) or v_word = f_swap_endian(C_PCAP_NS) then
      v_type.file_type := C_PCAP_FILE;
    elsif v_word = C_PCAPNG_BT then
      v_type.file_type := C_PCAPNG_FILE;
      if v_word2 = C_PCAPNG then
        v_type.bigendian := true;
      elsif v_word2 /= f_swap_endian(C_PCAPNG) then
        v_type.file_type := C_UNKNOWN_FILE;
      end if;
    end if;
    -- get snaplen
    v_word := x"00000000";
    if v_type.file_type = C_PCAP_FILE then
      v_word := v_data(16) & v_data(17) & v_data(18) & v_data(19);
    elsif v_type.file_type = C_PCAPNG_FILE then
      v_word := v_data(12) & v_data(13) & v_data(14) & v_data(15);
    end if;
    if v_type.bigendian = true then
      v_word := f_swap_endian(v_word);
    end if;
    v_type.snaplen := to_integer(unsigned(v_word(30 downto 0)));
    return v_type;
  end function f_pcap_read_ftype;

  -------------------------------------------------------------------------------
  -- Get packet length (PCAPNG)
  -------------------------------------------------------------------------------
  impure function f_pcapng_read_pkt_len(name   : string;
                                        pkt_no : integer;
                                        ftype  : t_pcap_file)
    return natural is
    file file_in      : t_file open read_mode is name;
    variable v_char   : character;
    variable v_found  : boolean                       := false;
    variable v_head   : std_logic_vector(31 downto 0);
    variable v_len    : std_logic_vector(31 downto 0);
    variable v_orglen : std_logic_vector(31 downto 0) := (others => '0');
    variable v_cnt    : natural                       := 0;
    variable v_idx    : natural;

  begin
    while (not endfile(file_in)) and (not v_found) loop
      -- read block header
      v_idx := 8;
      for i in 0 to 3 loop
        read(file_in, v_char);
        v_head((i+1)*8 - 1 downto i*8) := std_logic_vector(to_unsigned(character'pos(v_char), 8));
      end loop;
      if ftype.bigendian then
        v_head := f_swap_endian(v_head);
      end if;
      -- read block length
      for i in 0 to 3 loop
        read(file_in, v_char);
        v_len((i+1)*8 - 1 downto i*8) := std_logic_vector(to_unsigned(character'pos(v_char), 8));
      end loop;
      if ftype.bigendian then
        v_len := f_swap_endian(v_len);
      end if;
      -- update packet counter
      if v_head = x"00000003" then      -- simple packet block
        v_cnt := v_cnt + 1;
        for i in 0 to 3 loop
          read(file_in, v_char);
          v_orglen((i+1)*8 - 1 downto i*8) := std_logic_vector(to_unsigned(character'pos(v_char), 8));
        end loop;
        if ftype.bigendian then
          v_orglen := f_swap_endian(v_orglen);
        end if;
        v_idx := 12;
      elsif v_head = x"00000006" then   -- enhanced packet block
        v_cnt := v_cnt + 1;
        for i in 0 to 11 loop
          read(file_in, v_char);
        end loop;
        for i in 0 to 3 loop
          read(file_in, v_char);
          v_orglen((i+1)*8 - 1 downto i*8) := std_logic_vector(to_unsigned(character'pos(v_char), 8));
        end loop;
        if ftype.bigendian then
          v_orglen := f_swap_endian(v_orglen);
        end if;
        v_idx := 24;
      end if;
      -- read rest of block
      for i in v_idx to to_integer(unsigned(v_len)) - 1 loop
        read(file_in, v_char);
      end loop;
      -- target block?
      if pkt_no /= -1 then
        if integer(v_cnt) = pkt_no + 1 then
          v_found := true;
        end if;
      end if;
    end loop;
    file_close(file_in);
    if pkt_no = -1 then
      return v_cnt;
    else
      return minimum(to_integer(unsigned(v_orglen(30 downto 0))), ftype.snaplen);
    end if;
  end function f_pcapng_read_pkt_len;

  -------------------------------------------------------------------------------
  -- Get packet length (PCAP)
  -------------------------------------------------------------------------------
  impure function f_pcap_read_pkt_len(name   : string;
                                      pkt_no : integer;
                                      ftype  : t_pcap_file)
    return natural is
    file file_in       : t_file open read_mode is name;
    variable v_char    : character;
    variable v_found   : boolean := false;
    variable v_head    : std_logic_vector(31 downto 0);
    variable v_snaplen : std_logic_vector(31 downto 0);
    variable v_orglen  : std_logic_vector(31 downto 0);
    variable v_cnt     : natural := 0;
    variable v_idx     : natural;

  begin
    -- skip file header (24 bytes)
    for i in 0 to 23 loop
      read(file_in, v_char);
    end loop;
    -- process packets
    while (not endfile(file_in)) and (not v_found) loop
      -- skip timestamps
      for i in 0 to 7 loop
        read(file_in, v_char);
      end loop;
      -- captured packet length
      for i in 0 to 3 loop
        read(file_in, v_char);
        v_orglen((i+1)*8 - 1 downto i*8) := std_logic_vector(to_unsigned(character'pos(v_char), 8));
      end loop;
      if ftype.bigendian then
        v_orglen := f_swap_endian(v_orglen);
      end if;
      -- skip original packet length
      for i in 0 to 3 loop
        read(file_in, v_char);
      end loop;
      -- skip packet
      v_cnt := v_cnt + 1;
      for i in 0 to to_integer(unsigned(v_orglen(30 downto 0))) - 1 loop
        read(file_in, v_char);
      end loop;
      -- target block?
      if pkt_no /= -1 then
        if integer(v_cnt) = pkt_no + 1 then
          v_found := true;
        end if;
      end if;
    end loop;
    file_close(file_in);
    if pkt_no = -1 then
      return v_cnt;
    else
      return minimum(to_integer(unsigned(v_orglen(30 downto 0))), ftype.snaplen);
    end if;
  end function f_pcap_read_pkt_len;

  -------------------------------------------------------------------------------
  -- Get packet (PCAPNG)
  -------------------------------------------------------------------------------
  impure function f_pcapng_read_pkt(name      : string;
                                    pkt_no    : natural;
                                    pkt_len   : natural;
                                    bigendian : boolean)
    return t_slv_arr is

    file file_in      : t_file open read_mode is name;
    variable v_char   : character;
    variable v_found  : boolean                       := false;
    variable v_head   : std_logic_vector(31 downto 0);
    variable v_len    : std_logic_vector(31 downto 0);
    variable v_orglen : std_logic_vector(31 downto 0) := (others => '0');
    variable v_cnt    : natural                       := 0;
    variable v_idx    : natural;
    variable v_data   : t_slv_arr(0 to pkt_len - 1)(7 downto 0);
  begin
    while (not endfile(file_in)) and (not v_found) loop
      -- read block header
      v_idx := 8;
      for i in 0 to 3 loop
        read(file_in, v_char);
        v_head((i+1)*8 - 1 downto i*8) := std_logic_vector(to_unsigned(character'pos(v_char), 8));
      end loop;
      if bigendian then
        v_head := f_swap_endian(v_head);
      end if;
      -- read block length
      for i in 0 to 3 loop
        read(file_in, v_char);
        v_len((i+1)*8 - 1 downto i*8) := std_logic_vector(to_unsigned(character'pos(v_char), 8));
      end loop;
      if bigendian then
        v_len := f_swap_endian(v_len);
      end if;
      -- update packet counter
      if v_head = x"00000003" then      -- simple packet block
        v_cnt := v_cnt + 1;
        for i in 0 to 3 loop
          read(file_in, v_char);
          v_orglen((i+1)*8 - 1 downto i*8) := std_logic_vector(to_unsigned(character'pos(v_char), 8));
        end loop;
        if bigendian then
          v_orglen := f_swap_endian(v_orglen);
        end if;
        v_idx := 12;
      elsif v_head = x"00000006" then   -- enhanced packet block
        v_cnt := v_cnt + 1;
        for i in 0 to 11 loop
          read(file_in, v_char);
        end loop;
        for i in 0 to 3 loop
          read(file_in, v_char);
          v_orglen((i+1)*8 - 1 downto i*8) := std_logic_vector(to_unsigned(character'pos(v_char), 8));
        end loop;
        if bigendian then
          v_orglen := f_swap_endian(v_orglen);
        end if;
        v_idx := 24;
      end if;
      -- target block?
      if pkt_no /= -1 then
        if integer(v_cnt) = pkt_no + 1 then
          v_found := true;
        end if;
      end if;
      -- read rest of block
      if not v_found then
        for i in v_idx to to_integer(unsigned(v_len)) - 1 loop
          read(file_in, v_char);
        end loop;
      else
        for i in 0 to 3 loop            -- skip org packet length field
          read(file_in, v_char);
        end loop;
        for i in 0 to to_integer(unsigned(v_orglen)) - 1 loop
          read(file_in, v_char);
          v_data(i) := std_logic_vector(to_unsigned(character'pos(v_char), 8));
        end loop;
      end if;
    end loop;
    file_close(file_in);
    return v_data;
  end function f_pcapng_read_pkt;
  --! @endcond

  -------------------------------------------------------------------------------
  -- Get packet (PCAP)
  -------------------------------------------------------------------------------
  impure function f_pcap_read_pkt(name      : string;
                                  pkt_no    : natural;
                                  pkt_len   : natural;
                                  bigendian : boolean)
    return t_slv_arr is
    file file_in       : t_file open read_mode is name;
    variable v_char    : character;
    variable v_found   : boolean := false;
    variable v_head    : std_logic_vector(31 downto 0);
    variable v_snaplen : std_logic_vector(31 downto 0);
    variable v_orglen  : std_logic_vector(31 downto 0);
    variable v_cnt     : natural := 0;
    variable v_idx     : natural;
    variable v_data    : t_slv_arr(0 to pkt_len - 1)(7 downto 0);
  begin
    -- skip file header (24 bytes)
    for i in 0 to 23 loop
      read(file_in, v_char);
    end loop;
    -- process packets
    while (not endfile(file_in)) and (not v_found) loop
      -- skip timestamps
      for i in 0 to 7 loop
        read(file_in, v_char);
      end loop;
      -- captured packet length
      for i in 0 to 3 loop
        read(file_in, v_char);
        v_orglen((i+1)*8 - 1 downto i*8) := std_logic_vector(to_unsigned(character'pos(v_char), 8));
      end loop;
      if bigendian then
        v_orglen := f_swap_endian(v_orglen);
      end if;
      -- skip original packet length
      for i in 0 to 3 loop
        read(file_in, v_char);
      end loop;
      v_cnt := v_cnt + 1;
      -- target block?
      if v_cnt = pkt_no + 1 then
        v_found := true;
      end if;
      for i in 0 to to_integer(unsigned(v_orglen(30 downto 0))) - 1 loop
        read(file_in, v_char);
        if v_found then
          v_data(i) := std_logic_vector(to_unsigned(character'pos(v_char), 8));
        end if;
      end loop;
    end loop;
    file_close(file_in);
    return v_data;
  end function f_pcap_read_pkt;

  -------------------------------------------------------------------------------
  --! \brief Get PCAP file packet count
  --! \param name       PCAP file name
  --! \return           Number of network packets in file (-1 on failure).
  --!
  --! Get the number of network packets in PCAP file. Supports both PCAP and PCAPNG formats (only the first section in the latter format).
  --!
  --! **Example use**
  --! ~~~
  --! v_cnt := f_pcap_get_pkt_cnt("../nw_pcap/tb/ipv6-smtp.pcapng");  -- v_cnt is now 17 (17 packets in this file)
  --! v_cnt := f_pcap_get_pkt_cnt("../nw_pcap/tb/PPTP_negotiation.pcap");  -- v_cnt is now 28 (28 packets in this file)
  --! ~~~
  -------------------------------------------------------------------------------
  impure function f_pcap_get_pkt_cnt(name : string)
    return integer is

    variable v_cnt  : integer := -1;
    variable v_type : t_pcap_file;
  begin
    v_type := f_pcap_read_ftype(name);
    case v_type.file_type is
      when C_PCAP_FILE =>
        return f_pcap_read_pkt_len(name, -1, v_type);
      when C_PCAPNG_FILE =>
        return f_pcapng_read_pkt_len(name, -1, v_type);
      when others =>
        assert false report "f_pcap_get_pkt_cnt: File " & name & " is unrecognised" severity C_SEVERITY;
    end case;
    return v_cnt;
  end function f_pcap_get_pkt_cnt;

  -------------------------------------------------------------------------------
  --! \brief Get length of network packet
  --! \param name       PCAP file name
  --! \param pkt_no     Index of network packet in file (0 is first)
  --! \return           Number of bytes in network packet
  --!
  --! Get the length of a specific network packet in a PCAP file.
  --!
  --! **Example use**
  --! ~~~
  --! v_len := f_pcap_get_pkt_len("../nw_pcap/tb/ipv6-smtp.pcapng", 3);  -- v_len is now 125 (length of packet #3)
  --! v_len := f_pcap_get_pkt_cnt("../nw_pcap/tb/PPTP_negotiation.pcap", 26);  -- v_len is now 138 (length of packet #26)
  --! ~~~
  -------------------------------------------------------------------------------
  impure function f_pcap_get_pkt_len(name   : string;
                                     pkt_no : natural)
    return natural is

    variable v_cnt  : integer := -1;
    variable v_type : t_pcap_file;
  begin
    v_type := f_pcap_read_ftype(name);
    case v_type.file_type is
      when C_PCAP_FILE =>
        return f_pcap_read_pkt_len(name, pkt_no, v_type);
      when C_PCAPNG_FILE =>
        return f_pcapng_read_pkt_len(name, pkt_no, v_type);
      when others =>
        assert false report "f_pcap_get_pkt_len: File " & name & " is unrecognised" severity C_SEVERITY;
    end case;
    return v_cnt;
  end function f_pcap_get_pkt_len;

  -------------------------------------------------------------------------------
  --! \brief Extract packet from file
  --! \param name       PCAP file name
  --! \param pkt_no     Index of network packet in file (0 is first)
  --! \param pkt_len    Number of bytes to read 
  --! \return           8bit data array with packet
  --!
  --! Get a specific packet from file. 
  --!
  --! **Example use**
  --! ~~~
  --! v_len                  := f_pcap_get_pkt_len("../nw_pcap/tb/ipv6-smtp.pcapng", 3);  -- v_len is now 125 (length of packet #3)
  --! v_data(0 to v_len - 1) := f_pcap_get_pkt("../nw_pcap/tb/ipv6-smtp.pcapng", 3, v_len); 
  --! ~~~
  -------------------------------------------------------------------------------
  impure function f_pcap_get_pkt(name    : string;
                                 pkt_no  : natural;
                                 pkt_len : natural)
    return t_slv_arr is

    variable v_data : t_slv_arr(0 to pkt_len - 1)(7 downto 0) := (others => x"00");
    variable v_type : t_pcap_file;
  begin
    v_type := f_pcap_read_ftype(name);
    case v_type.file_type is
      when C_PCAP_FILE =>
        return f_pcap_read_pkt(name, pkt_no, pkt_len, v_type.bigendian);
      when C_PCAPNG_FILE =>
        return f_pcapng_read_pkt(name, pkt_no, pkt_len, v_type.bigendian);
      when others =>
        assert false report "f_pcap_get_pkt: File " & name & " is unrecognised" severity C_SEVERITY;
    end case;
    return v_data;
  end function f_pcap_get_pkt;

end package body nw_pcap_pkg;
