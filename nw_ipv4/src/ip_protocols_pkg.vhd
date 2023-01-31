-------------------------------------------------------------------------------
-- Title      : IP protocols
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: IP protocols definitions.
--
-- Source: https://en.wikipedia.org/wiki/List_of_IP_protocol_numbers
-------------------------------------------------------------------------------
-- MIT License
--
-- Copyright (c) 2023 Geir Drange
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
-- FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
-- WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-------------------------------------------------------------------------------
--! @cond
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
--! @endcond

package ip_protocols_pkg is

  --! @cond
  constant C_HOPOPT          : std_logic_vector(7 downto 0) := x"00";  -- IPv6 Hop-by-Hop Option RFC 8200
  constant C_ICMP            : std_logic_vector(7 downto 0) := x"01";  -- Internet Control Message Protocol RFC 792
  constant C_IGMP            : std_logic_vector(7 downto 0) := x"02";  -- Internet Group Management Protocol RFC 1112
  constant C_GGP             : std_logic_vector(7 downto 0) := x"03";  -- Gateway-to-Gateway Protocol RFC 823
  constant C_IP_IN_IP        : std_logic_vector(7 downto 0) := x"04";  -- IP in IP (encapsulation) RFC 2003
  constant C_ST              : std_logic_vector(7 downto 0) := x"05";  -- Internet Stream Protocol RFC 1190, RFC 1819
  constant C_TCP             : std_logic_vector(7 downto 0) := x"06";  -- Transmission Control Protocol RFC 793
  constant C_CBT             : std_logic_vector(7 downto 0) := x"07";  -- Core-based trees RFC 2189
  constant C_EGP             : std_logic_vector(7 downto 0) := x"08";  -- Exterior Gateway Protocol RFC 888
  constant C_IGP             : std_logic_vector(7 downto 0) := x"09";  -- Interior Gateway Protocol (any private interior gateway, for example Cisco's IGRP)
  constant C_BBN_RCC_MON     : std_logic_vector(7 downto 0) := x"0A";  -- BBN RCC Monitoring
  constant C_NVP_II          : std_logic_vector(7 downto 0) := x"0B";  -- Network Voice Protocol RFC 741
  constant C_PUP             : std_logic_vector(7 downto 0) := x"0C";  -- Xerox PUP
  constant C_ARGUS           : std_logic_vector(7 downto 0) := x"0D";  -- ARGUS
  constant C_EMCON           : std_logic_vector(7 downto 0) := x"0E";  -- EMCON
  constant C_XNET            : std_logic_vector(7 downto 0) := x"0F";  -- Cross Net Debugger IEN 158[2]
  constant C_CHAOS           : std_logic_vector(7 downto 0) := x"10";  -- Chaos
  constant C_UDP             : std_logic_vector(7 downto 0) := x"11";  -- User Datagram Protocol RFC 768
  constant C_MUX             : std_logic_vector(7 downto 0) := x"12";  -- Multiplexing IEN 90[3]
  constant C_DCN_MEAS        : std_logic_vector(7 downto 0) := x"13";  -- DCN Measurement Subsystems
  constant C_HMP             : std_logic_vector(7 downto 0) := x"14";  -- Host Monitoring Protocol RFC 869
  constant C_PRM             : std_logic_vector(7 downto 0) := x"15";  -- Packet Radio Measurement
  constant C_XNS_IDP         : std_logic_vector(7 downto 0) := x"16";  -- XEROX NS IDP
  constant C_TRUNK_1         : std_logic_vector(7 downto 0) := x"17";  -- Trunk-1
  constant C_TRUNK_2         : std_logic_vector(7 downto 0) := x"18";  -- Trunk-2
  constant C_LEAF_1          : std_logic_vector(7 downto 0) := x"19";  -- Leaf-1
  constant C_LEAF_2          : std_logic_vector(7 downto 0) := x"1A";  -- Leaf-2
  constant C_RDP             : std_logic_vector(7 downto 0) := x"1B";  -- Reliable Data Protocol RFC 908
  constant C_IRTP            : std_logic_vector(7 downto 0) := x"1C";  -- Internet Reliable Transaction Protocol RFC 938
  constant C_ISO_TP4         : std_logic_vector(7 downto 0) := x"1D";  -- ISO Transport Protocol Class 4 RFC 905
  constant C_NETBLT          : std_logic_vector(7 downto 0) := x"1E";  -- Bulk Data Transfer Protocol RFC 998
  constant C_MFE_NSP         : std_logic_vector(7 downto 0) := x"1F";  -- MFE Network Services Protocol
  constant C_MERIT_INP       : std_logic_vector(7 downto 0) := x"20";  -- MERIT Internodal Protocol
  constant C_DCCP            : std_logic_vector(7 downto 0) := x"21";  -- Datagram Congestion Control Protocol RFC 4340
  constant C_3PC             : std_logic_vector(7 downto 0) := x"22";  -- Third Party Connect Protocol
  constant C_IDPR            : std_logic_vector(7 downto 0) := x"23";  -- Inter-Domain Policy Routing Protocol RFC 1479
  constant C_XTP             : std_logic_vector(7 downto 0) := x"24";  -- Xpress Transport Protocol
  constant C_DDP             : std_logic_vector(7 downto 0) := x"25";  -- Datagram Delivery Protocol
  constant C_IDPR_CMTP       : std_logic_vector(7 downto 0) := x"26";  -- IDPR Control Message Transport Protocol
  constant C_TP_PLUSPLUS     : std_logic_vector(7 downto 0) := x"27";  -- TP++ Transport Protocol
  constant C_IL              : std_logic_vector(7 downto 0) := x"28";  -- IL Transport Protocol
  constant C_IPV6            : std_logic_vector(7 downto 0) := x"29";  -- IPv6 Encapsulation (6to4 and 6in4) RFC 2473
  constant C_SDRP            : std_logic_vector(7 downto 0) := x"2A";  -- Source Demand Routing Protocol RFC 1940
  constant C_IPV6_ROUTE      : std_logic_vector(7 downto 0) := x"2B";  -- Routing Header for IPv6 RFC 8200
  constant C_IPV6_FRAG       : std_logic_vector(7 downto 0) := x"2C";  -- Fragment Header for IPv6 RFC 8200
  constant C_IDRP            : std_logic_vector(7 downto 0) := x"2D";  -- Inter-Domain Routing Protocol
  constant C_RSVP            : std_logic_vector(7 downto 0) := x"2E";  -- Resource Reservation Protocol RFC 2205
  constant C_GRE             : std_logic_vector(7 downto 0) := x"2F";  -- Generic Routing Encapsulation RFC 2784, RFC 2890
  constant C_DSR             : std_logic_vector(7 downto 0) := x"30";  -- Dynamic Source Routing Protocol RFC 4728
  constant C_BNA             : std_logic_vector(7 downto 0) := x"31";  -- Burroughs Network Architecture
  constant C_ESP             : std_logic_vector(7 downto 0) := x"32";  -- Encapsulating Security Payload RFC 4303
  constant C_AH              : std_logic_vector(7 downto 0) := x"33";  -- Authentication Header RFC 4302
  constant C_I_NLSP          : std_logic_vector(7 downto 0) := x"34";  -- Integrated Net Layer Security Protocol TUBA
  constant C_SWIPE           : std_logic_vector(7 downto 0) := x"35";  -- SwIPe RFC 5237
  constant C_NARP            : std_logic_vector(7 downto 0) := x"36";  -- NBMA Address Resolution Protocol RFC 1735
  constant C_MOBILE          : std_logic_vector(7 downto 0) := x"37";  -- IP Mobility (Min Encap) RFC 2004
  constant C_TLSP            : std_logic_vector(7 downto 0) := x"38";  -- Transport Layer Security Protocol (using Kryptonet key management)
  constant C_SKIP            : std_logic_vector(7 downto 0) := x"39";  -- Simple Key-Management for Internet Protocol RFC 2356
  constant C_IPV6_ICMP       : std_logic_vector(7 downto 0) := x"3A";  -- ICMP for IPv6 RFC 4443, RFC 4884
  constant C_IPV6_NONXT      : std_logic_vector(7 downto 0) := x"3B";  -- No Next Header for IPv6 RFC 8200
  constant C_IPV6_OPTS       : std_logic_vector(7 downto 0) := x"3C";  -- Destination Options for IPv6 RFC 8200
  constant C_ANY             : std_logic_vector(7 downto 0) := x"3D";  -- host internal protocol
  constant C_CFTP            : std_logic_vector(7 downto 0) := x"3E";  -- CFTP
  constant C_ANY_1           : std_logic_vector(7 downto 0) := x"3F";  -- local network
  constant C_SAT_EXPAK       : std_logic_vector(7 downto 0) := x"40";  -- SATNET and Backroom EXPAK
  constant C_KRYPTOLAN       : std_logic_vector(7 downto 0) := x"41";  -- Kryptolan
  constant C_RVD             : std_logic_vector(7 downto 0) := x"42";  -- MIT Remote Virtual Disk Protocol
  constant C_IPPC            : std_logic_vector(7 downto 0) := x"43";  -- Internet Pluribus Packet Core
  constant C_ANY_2           : std_logic_vector(7 downto 0) := x"44";  -- distributed file system
  constant C_SAT_MON         : std_logic_vector(7 downto 0) := x"45";  -- SATNET Monitoring
  constant C_VISA            : std_logic_vector(7 downto 0) := x"46";  -- VISA Protocol
  constant C_IPCU            : std_logic_vector(7 downto 0) := x"47";  -- Internet Packet Core Utility
  constant C_CPNX            : std_logic_vector(7 downto 0) := x"48";  -- Computer Protocol Network Executive
  constant C_CPHB            : std_logic_vector(7 downto 0) := x"49";  -- Computer Protocol Heart Beat
  constant C_WSN             : std_logic_vector(7 downto 0) := x"4A";  -- Wang Span Network
  constant C_PVP             : std_logic_vector(7 downto 0) := x"4B";  -- Packet Video Protocol
  constant C_BR_SAT_MON      : std_logic_vector(7 downto 0) := x"4C";  -- Backroom SATNET Monitoring
  constant C_SUN_ND          : std_logic_vector(7 downto 0) := x"4D";  -- SUN ND PROTOCOL-Temporary
  constant C_WB_MON          : std_logic_vector(7 downto 0) := x"4E";  -- WIDEBAND Monitoring
  constant C_WB_EXPAK        : std_logic_vector(7 downto 0) := x"4F";  -- WIDEBAND EXPAK
  constant C_ISO_IP          : std_logic_vector(7 downto 0) := x"50";  -- International Organization for Standardization Internet Protocol
  constant C_VMTP            : std_logic_vector(7 downto 0) := x"51";  -- Versatile Message Transaction Protocol RFC 1045
  constant C_SECURE_VMTP     : std_logic_vector(7 downto 0) := x"52";  -- Secure Versatile Message Transaction Protocol RFC 1045
  constant C_VINES           : std_logic_vector(7 downto 0) := x"53";  -- VINES
  constant C_TTP             : std_logic_vector(7 downto 0) := x"54";  -- TTP
  constant C_IPTM            : std_logic_vector(7 downto 0) := x"54";  -- Internet Protocol Traffic Manager
  constant C_NSFNET_IGP      : std_logic_vector(7 downto 0) := x"55";  -- NSFNET-IGP
  constant C_DGP             : std_logic_vector(7 downto 0) := x"56";  -- Dissimilar Gateway Protocol
  constant C_TCF             : std_logic_vector(7 downto 0) := x"57";  -- TCF
  constant C_EIGRP           : std_logic_vector(7 downto 0) := x"58";  -- EIGRP Informational RFC 7868
  constant C_OSPF            : std_logic_vector(7 downto 0) := x"59";  -- Open Shortest Path First RFC 2328
  constant C_SPRITE_RPC      : std_logic_vector(7 downto 0) := x"5A";  -- Sprite RPC Protocol
  constant C_LARP            : std_logic_vector(7 downto 0) := x"5B";  -- Locus Address Resolution Protocol
  constant C_MTP             : std_logic_vector(7 downto 0) := x"5C";  -- Multicast Transport Protocol
  constant C_AX_25           : std_logic_vector(7 downto 0) := x"5D";  -- AX.25
  constant C_OS              : std_logic_vector(7 downto 0) := x"5E";  -- KA9Q NOS compatible IP over IP tunneling
  constant C_MICP            : std_logic_vector(7 downto 0) := x"5F";  -- Mobile Internetworking Control Protocol
  constant C_SCC_SP          : std_logic_vector(7 downto 0) := x"60";  -- Semaphore Communications Sec. Pro
  constant C_ETHERIP         : std_logic_vector(7 downto 0) := x"61";  -- Ethernet-within-IP Encapsulation RFC 3378
  constant C_ENCAP           : std_logic_vector(7 downto 0) := x"62";  -- Encapsulation Header RFC 1241
  constant C_ANY_3           : std_logic_vector(7 downto 0) := x"63";  -- private encryption scheme
  constant C_GMTP            : std_logic_vector(7 downto 0) := x"64";  -- GMTP
  constant C_IFMP            : std_logic_vector(7 downto 0) := x"65";  -- Ipsilon Flow Management Protocol
  constant C_PNNI            : std_logic_vector(7 downto 0) := x"66";  -- PNNI over IP
  constant C_PIM             : std_logic_vector(7 downto 0) := x"67";  -- Protocol Independent Multicast
  constant C_ARIS            : std_logic_vector(7 downto 0) := x"68";  -- IBM's ARIS (Aggregate Route IP Switching) Protocol
  constant C_SCPS            : std_logic_vector(7 downto 0) := x"69";  -- SCPS (Space Communications Protocol Standards) SCPS-TP[4]
  constant C_QNX             : std_logic_vector(7 downto 0) := x"6A";  -- QNX
  constant C_A_N             : std_logic_vector(7 downto 0) := x"6B";  -- Active Networks
  constant C_IPCOMP          : std_logic_vector(7 downto 0) := x"6C";  -- IP Payload Compression Protocol RFC 3173
  constant C_SNP             : std_logic_vector(7 downto 0) := x"6D";  -- Sitara Networks Protocol
  constant C_COMPAQ_PEER     : std_logic_vector(7 downto 0) := x"6E";  -- Compaq Peer Protocol
  constant C_IPX_IN_IP       : std_logic_vector(7 downto 0) := x"6F";  -- IPX in IP
  constant C_VRRP            : std_logic_vector(7 downto 0) := x"70";  -- Virtual Router Redundancy Protocol, Common Address Redundancy Protocol (not IANA assigned) RFC 5798
  constant C_PGM             : std_logic_vector(7 downto 0) := x"71";  -- PGM Reliable Transport Protocol RFC 3208
  constant C_ANY_4           : std_logic_vector(7 downto 0) := x"72";  -- 0-hop protocol
  constant C_L2TP            : std_logic_vector(7 downto 0) := x"73";  -- Layer Two Tunneling Protocol Version 3 RFC 3931
  constant C_DDX             : std_logic_vector(7 downto 0) := x"74";  -- D-II Data Exchange (DDX)
  constant C_IATP            : std_logic_vector(7 downto 0) := x"75";  -- Interactive Agent Transfer Protocol
  constant C_STP             : std_logic_vector(7 downto 0) := x"76";  -- Schedule Transfer Protocol
  constant C_SRP             : std_logic_vector(7 downto 0) := x"77";  -- SpectraLink Radio Protocol
  constant C_UTI             : std_logic_vector(7 downto 0) := x"78";  -- Universal Transport Interface Protocol
  constant C_SMP             : std_logic_vector(7 downto 0) := x"79";  -- Simple Message Protocol
  constant C_SM              : std_logic_vector(7 downto 0) := x"7A";  -- Simple Multicast Protocol draft-perlman-simple-multicast-03
  constant C_PTP             : std_logic_vector(7 downto 0) := x"7B";  -- Performance Transparency Protocol
  constant C_IS_IS           : std_logic_vector(7 downto 0) := x"7C";  -- over IPv4 Intermediate System to Intermediate System (IS-IS) Protocol over IPv4 RFC 1142 and RFC 1195
  constant C_FIRE            : std_logic_vector(7 downto 0) := x"7D";  -- Flexible Intra-AS Routing Environment
  constant C_CRTP            : std_logic_vector(7 downto 0) := x"7E";  -- Combat Radio Transport Protocol
  constant C_CRUDP           : std_logic_vector(7 downto 0) := x"7F";  -- Combat Radio User Datagram
  constant C_SSCOPMCE        : std_logic_vector(7 downto 0) := x"80";  -- Service-Specific Connection-Oriented Protocol in a Multilink and Connectionless Environment ITU-T Q.2111 (1999)
  constant C_IPLT            : std_logic_vector(7 downto 0) := x"81";  -- 
  constant C_SPS             : std_logic_vector(7 downto 0) := x"82";  -- Secure Packet Shield
  constant C_PIPE            : std_logic_vector(7 downto 0) := x"83";  -- Private IP Encapsulation within IP Expired I-D draft-petri-mobileip-pipe-00.txt
  constant C_SCTP            : std_logic_vector(7 downto 0) := x"84";  -- Stream Control Transmission Protocol RFC 4960
  constant C_FC              : std_logic_vector(7 downto 0) := x"85";  -- Fibre Channel
  constant C_RSVP_E2E_IGNORE : std_logic_vector(7 downto 0) := x"86";  -- Reservation Protocol (RSVP) End-to-End Ignore RFC 3175
  constant C_MOBILITY        : std_logic_vector(7 downto 0) := x"87";  -- Header Mobility Extension Header for IPv6 RFC 6275
  constant C_UDPLITE         : std_logic_vector(7 downto 0) := x"88";  -- Lightweight User Datagram Protocol RFC 3828
  constant C_MPLS_IN_IP      : std_logic_vector(7 downto 0) := x"89";  -- Multiprotocol Label Switching Encapsulated in IP RFC 4023, RFC 5332
  constant C_MANET           : std_logic_vector(7 downto 0) := x"8A";  -- MANET Protocols RFC 5498
  constant C_HIP             : std_logic_vector(7 downto 0) := x"8B";  -- Host Identity Protocol RFC 5201
  constant C_SHIM6           : std_logic_vector(7 downto 0) := x"8C";  -- Site Multihoming by IPv6 Intermediation RFC 5533
  constant C_WESP            : std_logic_vector(7 downto 0) := x"8D";  -- Wrapped Encapsulating Security Payload RFC 5840
  constant C_ROHC            : std_logic_vector(7 downto 0) := x"8E";  -- Robust Header Compression RFC 5856
  constant C_ETHERNET        : std_logic_vector(7 downto 0) := x"8F";  -- IPv6 Segment Routing (TEMPORARY - registered 2020-01-31, expired 2021-01-31)
  constant C_AGGFRAG         : std_logic_vector(7 downto 0) := x"90";  -- AGGFRAG encapsulation payload for ESP
  --! @endcond

end package ip_protocols_pkg;
