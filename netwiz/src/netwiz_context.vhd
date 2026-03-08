-------------------------------------------------------------------------------
-- Title      : Network Wizard context
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: 
--!\file
--!\brief Netwiz context
--
-------------------------------------------------------------------------------
-- MIT License
--
-- Copyright (c) 2026 Geir Drange
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

context netwiz_context is
  library nw_adapt;
  use nw_adapt.nw_adaptations_pkg.all;
  library nw_util;
  use nw_util.nw_types_pkg.all;
  use nw_util.nw_util_pkg.all;
  use nw_util.nw_prbs_pkg.all;
  use nw_util.nw_nrs_pkg.all;
  use nw_util.nw_crc_pkg.all;
  use nw_util.nw_axis_pkg.all;
  library nw_codec;
  use nw_codec.nw_sl_codec_pkg.all;
  use nw_codec.nw_cobs_pkg.all;
  use nw_codec.nw_base_pkg.all;
  use nw_codec.nw_bitstuff_pkg.all;
  use nw_codec.nw_hamming_pkg.all;
  library nw_ethernet;
  use nw_ethernet.nw_ethernet_pkg.all;
  use nw_ethernet.nw_arp_pkg.all;
  library nw_ipv4;
  use nw_ipv4.ip_protocols_pkg.all;
  use nw_ipv4.nw_ipv4_pkg.all;
  use nw_ipv4.nw_udpv4_pkg.all;
  use nw_ipv4.nw_icmpv4_pkg.all;
  use nw_ipv4.nw_tcpv4_pkg.all;
  library nw_ipv6;
  use nw_ipv6.nw_ipv6_pkg.all;
  use nw_ipv6.nw_udpv6_pkg.all;
  use nw_ipv6.nw_icmpv6_pkg.all;
  use nw_ipv6.nw_tcpv6_pkg.all;
  library nw_pcap;
  use nw_pcap.nw_pcap_pkg.all;
  library nw_ptp;
  use nw_ptp.nw_ptpv2_pkg.all;
  library nw_rtp;
  use nw_rtp.nw_rtp_pkg.all;
  library nw_usb;
  use nw_usb.nw_usb_pkg.all;
end context netwiz_context;
