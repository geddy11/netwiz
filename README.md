![](./netwiz.png)

<p style="text-align: center;">
<a href="https://github.com/geddy11/netwiz/actions/workflows/netwiz_ci.yml"><img alt="Actions Status" src="https://github.com/geddy11/netwiz/actions/workflows/netwiz_ci.yml/badge.svg"></a>
<a href="https://github.com/geddy11/netwiz/actions/workflows/pages/pages-build-deployment"><img alt="Doc build" src="https://github.com/geddy11/netwiz/actions/workflows/pages/pages-build-deployment/badge.svg"></a>
<a href="https://github.com/geddy11/netwiz/releases"><img alt="GitHub Release" src="https://img.shields.io/github/v/release/geddy11/netwiz"></a>
<a><img alt="Top language" src="https://img.shields.io/github/languages/top/geddy11/netwiz"></a>
<a href="https://doi.org/10.5281/zenodo.18139293"><img alt="Zenodo DOI" src="https://zenodo.org/badge/DOI/10.5281/zenodo.18139293.svg" alt="DOI"></a>
</p>

## Intro
NetWiz is a stand-alone VHDL library for network protocol packet generation and manipulation. NetWiz offers a stateless and functional [**API**](https://geddy11.github.io/netwiz/functions_func.html).

NetWiz requires VHDL 2008 and is designed for test bench use only, synthesis is not supported. NetWiz is licensed under the MIT license.

## Libraries
Netwiz consists of several libraries. Libraries not related to a specific network protocol are:
  * nw_adapt:
    * Configurable settings
  * nw_codec:
    * [nw_sl_codec](@ref nw_sl_codec): Stateless generic codec
    * [nw_cobs](@ref nw_cobs): Consistent Overhead Byte Stuffing
    * [nw_bitstuff](@ref nw_bstuff): Bit stuffing
    * [nw_base](@ref nw_base): Base64/32/16 codec
    * [nw_hamming](@ref nw_hamming): Hamming encoding/decoding
  * nw_pcap: 
    * [nw_pcap](@ref nw_pcap): Read network packets from PCAP/PCAPNG files (produced by Wireshark, tcmpdump et.al.)
  * nw_util: 
    * [nw_util](@ref nw_util): Functions for data array manipulation
    * [nw_crc](@ref nw_crc): CRC and checksum generation 
    * [nw_prbs](@ref nw_prbs): Pseudo-Random Binary Sequence generation.
    * [nw_nrs](@ref nw_nrs): Non-Random Sequence generation
  
  Protocol specific libraries:
  * nw_ethernet:
    * [nw_ethernet](@ref nw_ethernet): Create and manipulate Ethernet packets
    * [nw_arp](@ref nw_arp): Create and manipulate ARP packets
  * nw_ipv4:
    * [nw_ipv4](@ref nw_ipv4): Create and manipulate IPv4 packets
    * [nw_udp](@ref nw_udpv4): Create and manipulate UDP packets for IPv4
    * [nw_icmp](@ref nw_icmpv4): Create and manipulate ICMPv4 packets
    * [nw_tcp](@ref nw_tcpv4): Create and manipulate TCP packets for IPv4
  * nw_ipv6:
    * [nw_ipv6](@ref nw_ipv6): Create and manipulate IPv6 packets
    * [nw_udp](@ref nw_udpv6): Create and manipulate UDP packets for IPv6
    * [nw_icmp](@ref nw_icmpv6): Create and manipulate ICMPv6 packets
    * [nw_tcp](@ref nw_tcpv6): Create and manipulate TCP packets for IPv6
  * nw_ptp:
    * [nw_ptpv2](@ref nw_ptp): Create and manipulate IEEE1588v2 packets
  * nw_rtp:
    * [nw_rtp](@ref nw_rtp): Create and manipulate RTP packets
  * nw_usb:
    * [nw_usb](@ref nw_usb): Create and manipulate USB packets

  Additional protocol libraries are expected to be added in the future.

  ## Documentation
  The NetWiz API is [**documented here**](https://geddy11.github.io/netwiz/).

