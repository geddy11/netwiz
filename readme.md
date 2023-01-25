![](./netwiz.png)

## Intro
NetWiz is a stand-alone VHDL library for network protocol packet generation and manipulation. 

NetWiz requires VHDL 2008 and is designed for test bench use only, synthesis is not supported. NetWiz is licensed under the MIT license.

## Libraries
Netwiz consists of several libraries. Libraries not related to a specific network protocol are:
  * nw_util: 
    * [nw_util](@ref nw_util): Functions for data array manipulation
    * [nw_crc](@ref nw_crc): CRC and checksum generation 
    * [nw_prbs](@ref nw_prbs): Pseudo-Random Binary Sequence generation.
    * [nw_nrs](@ref nw_nrs): Non-Random Sequence generation
  * nw_pcap: 
    * [nw_pcap](@ref nw_pcap): Read network packets from PCAP/PCAPNG files (produced by Wireshark, tcmpdump et.al.)

  Protocol specific libraries:
  * nw_ethernet:
    * [nw_ethernet](@ref nw_ethernet): Create and manipulate Ethernet packets
  * nw_ipv4:
    * [nw_ipv4](@ref nw_ipv4): Create and manipulate IPv4 packets
    * [nw_udp](@ref nw_udpv4): Create and manipulate UDP packets

  Additional protocol libraries are expected to be added in the future.

  ## Documentation
  Link to GitHub pages...

