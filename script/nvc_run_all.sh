#!/bin/bash
# MIT License
#
# Copyright (c) 2023 Geir Drange
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
echo -e "\n"
echo "███    ██ ███████ ████████ ██     ██ ██ ███████ "
echo "████   ██ ██         ██    ██     ██ ██    ███  "
echo "██ ██  ██ █████      ██    ██  █  ██ ██   ███   "
echo "██  ██ ██ ██         ██    ██ ███ ██ ██  ███    "
echo "██   ████ ███████    ██     ███ ███  ██ ███████ "
# nw_adapt
nvc --std=2008 --work=nw_adapt -a ../nw_adapt/src/nw_adaptations_pkg.vhd
# nw_util
echo -e "\nTesting nw_util:"
nvc --std=2008 --work=nw_util -a ../nw_util/src/nw_types_pkg.vhd
nvc --std=2008 --work=nw_util -L . -a ../nw_util/src/nw_util_pkg.vhd
nvc --std=2008 --work=nw_util -L . -a ../nw_util/src/nw_crc_pkg.vhd
nvc --std=2008 --work=nw_util -L . -a ../nw_util/src/nw_nrs_pkg.vhd
nvc --std=2008 --work=nw_util -L . -a ../nw_util/src/nw_prbs_pkg.vhd
nvc --std=2008 --work=nw_util -L . -a ../nw_util/src/nw_util_context.vhd
nvc --std=2008 -L . -a  ../nw_util/tb/nw_util_tb.vhd -e nw_util_tb -r
# nw_pcap
echo -e "\nTesting nw_pcap:"
nvc --std=2008 --work=nw_pcap -L . -a ../nw_pcap/src/nw_pcap_pkg.vhd
nvc --std=2008 -L . -a ../nw_pcap/tb/nw_pcap_tb.vhd -e nw_pcap_tb -r
# nw_ethernet
echo -e "\nTesting nw_ethernet:"                                                                 
nvc --std=2008 --work=nw_ethernet -L . -a ../nw_ethernet/src/nw_ethernet_pkg.vhd
nvc --std=2008 --work=nw_ethernet -L . -a ../nw_ethernet/src/nw_arp_pkg.vhd
nvc --std=2008 --work=nw_ethernet -L . -a ../nw_ethernet/src/nw_ethernet_context.vhd
nvc --std=2008 --work=work -L . -a ../nw_ethernet/tb/nw_ethernet_tb.vhd -e nw_ethernet_tb -r
# nw_ipv4
echo -e "\nTesting nw_ipv4"
nvc --std=2008 --work=nw_ipv4 -L . -a ../nw_ipv4/src/ip_protocols_pkg.vhd
nvc --std=2008 --work=nw_ipv4 -L . -a ../nw_ipv4/src/nw_ipv4_pkg.vhd
nvc --std=2008 --work=nw_ipv4 -L . -a ../nw_ipv4/src/nw_udpv4_pkg.vhd
nvc --std=2008 --work=nw_ipv4 -L . -a ../nw_ipv4/src/nw_icmpv4_pkg.vhd
nvc --std=2008 --work=nw_ipv4 -L . -a ../nw_ipv4/src/nw_tcpv4_pkg.vhd
nvc --std=2008 --work=nw_ipv4 -L . -a ../nw_ipv4/src/nw_ipv4_context.vhd
nvc --std=2008 --work=work -L . -a ../nw_ipv4/tb/nw_ipv4_tb.vhd -e nw_ipv4_tb -r
# nw_ipv6
echo -e "\nTesting nw_ipv6"
nvc --std=2008 --work=nw_ipv6 -L . -a ../nw_ipv6/src/nw_ipv6_pkg.vhd
nvc --std=2008 --work=nw_ipv6 -L . -a ../nw_ipv6/src/nw_udpv6_pkg.vhd
nvc --std=2008 --work=nw_ipv6 -L . -a ../nw_ipv6/src/nw_icmpv6_pkg.vhd
nvc --std=2008 --work=nw_ipv6 -L . -a ../nw_ipv6/src/nw_tcpv6_pkg.vhd
nvc --std=2008 --work=nw_ipv6 -L . -a ../nw_ipv6/src/nw_ipv6_context.vhd
nvc --std=2008 --work=work -L . -a ../nw_ipv6/tb/nw_ipv6_tb.vhd -e nw_ipv6_tb -r
# nw_codec
echo -e "\nTesting nw_codec"
nvc --std=2008 --work=nw_codec -L . -a ../nw_codec/src/nw_sl_codec_pkg.vhd
nvc --std=2008 --work=nw_codec -L . -a ../nw_codec/src/nw_cobs_pkg.vhd
nvc --std=2008 --work=nw_codec -L . -a ../nw_codec/src/nw_base_pkg.vhd
nvc --std=2008 --work=nw_codec -L . -a ../nw_codec/src/nw_bitstuff_pkg.vhd
nvc --std=2008 --work=nw_codec -L . -a ../nw_codec/src/nw_hamming_pkg.vhd
nvc --std=2008 --work=nw_codec -L . -a ../nw_codec/src/nw_codec_context.vhd
nvc --std=2008 --work=work -L . -a ../nw_codec/tb/nw_codec_tb.vhd -e nw_codec_tb -r
# nw_ptp
echo -e "\nTesting nw_ptp"
nvc --std=2008 --work=nw_ptp -L . -a ../nw_ptp/src/nw_ptpv2_pkg.vhd
nvc --std=2008 --work=work -L . -a ../nw_ptp/tb/nw_ptp_tb.vhd -e nw_ptp_tb -r
# nw_usb
echo -e "\nTesting nw_usb"
nvc --std=2008 --work=nw_usb -L . -a ../nw_usb/src/nw_usb_pkg.vhd
nvc --std=2008 --work=nw_usb -L . -a ../nw_usb/src/nw_usb_context.vhd
nvc --std=2008 --work=work -L . -a ../nw_usb/tb/nw_usb_tb.vhd -e nw_usb_tb -r
