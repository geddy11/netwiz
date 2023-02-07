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
ghdl -a --std=08 -frelaxed-rules --work=nw_adapt ../nw_adapt/src/nw_adaptations_pkg.vhd
# nw_util
echo -e "\nTesting nw_util:"
ghdl -a --std=08 -frelaxed-rules --work=nw_util ../nw_util/src/nw_types_pkg.vhd
ghdl -a --std=08 -frelaxed-rules --work=nw_util ../nw_util/src/nw_util_pkg.vhd
ghdl -a --std=08 -frelaxed-rules --work=nw_util ../nw_util/src/nw_crc_pkg.vhd
ghdl -a --std=08 -frelaxed-rules --work=nw_util ../nw_util/src/nw_nrs_pkg.vhd
ghdl -a --std=08 -frelaxed-rules --work=nw_util ../nw_util/src/nw_prbs_pkg.vhd
ghdl -a --std=08 -frelaxed-rules --work=nw_util ../nw_util/src/nw_util_context.vhd
ghdl -a --std=08 -frelaxed-rules --work=work ../nw_util/tb/nw_util_tb.vhd
ghdl -e --std=08 -frelaxed-rules --work=work nw_util_tb
ghdl -r --std=08 -frelaxed-rules --work=work nw_util_tb
# nw_pcap
echo -e "\nTesting nw_pcap:"
ghdl -a --std=08 -frelaxed-rules --work=nw_pcap ../nw_pcap/src/nw_pcap_pkg.vhd
ghdl -a --std=08 -frelaxed-rules --work=work ../nw_pcap/tb/nw_pcap_tb.vhd
ghdl -e --std=08 -frelaxed-rules --work=work nw_pcap_tb
ghdl -r --std=08 -frelaxed-rules --work=work nw_pcap_tb
# nw_ethernet
echo -e "\nTesting nw_ethernet:"                                                                 
ghdl -a --std=08 -frelaxed-rules --work=nw_ethernet ../nw_ethernet/src/nw_ethernet_pkg.vhd
ghdl -a --std=08 -frelaxed-rules --work=nw_ethernet ../nw_ethernet/src/nw_arp_pkg.vhd
ghdl -a --std=08 -frelaxed-rules --work=nw_ethernet ../nw_ethernet/src/nw_ethernet_context.vhd
ghdl -a --std=08 -frelaxed-rules --work=work ../nw_ethernet/tb/nw_ethernet_tb.vhd
ghdl -e --std=08 -frelaxed-rules --work=work nw_ethernet_tb
ghdl -r --std=08 -frelaxed-rules --work=work nw_ethernet_tb
# nw_ipv4
echo -e "\nTesting nw_ipv4"
ghdl -a --std=08 -frelaxed-rules --work=nw_ipv4 ../nw_ipv4/src/ip_protocols_pkg.vhd
ghdl -a --std=08 -frelaxed-rules --work=nw_ipv4 ../nw_ipv4/src/nw_ipv4_pkg.vhd
ghdl -a --std=08 -frelaxed-rules --work=nw_ipv4 ../nw_ipv4/src/nw_udpv4_pkg.vhd
ghdl -a --std=08 -frelaxed-rules --work=nw_ipv4 ../nw_ipv4/src/nw_icmpv4_pkg.vhd
ghdl -a --std=08 -frelaxed-rules --work=nw_ipv4 ../nw_ipv4/src/nw_ipv4_context.vhd
ghdl -a --std=08 -frelaxed-rules --work=work ../nw_ipv4/tb/nw_ipv4_tb.vhd
ghdl -e --std=08 -frelaxed-rules --work=work nw_ipv4_tb
ghdl -r --std=08 -frelaxed-rules --work=work nw_ipv4_tb -gGC_GHDL=1
# nw_ipv6
echo -e "\nTesting nw_ipv6"
ghdl -a --std=08 -frelaxed-rules --work=nw_ipv6 ../nw_ipv6/src/nw_ipv6_pkg.vhd
ghdl -a --std=08 -frelaxed-rules --work=nw_ipv6 ../nw_ipv6/src/nw_udpv6_pkg.vhd
ghdl -a --std=08 -frelaxed-rules --work=nw_ipv6 ../nw_ipv6/src/nw_icmpv6_pkg.vhd
ghdl -a --std=08 -frelaxed-rules --work=nw_ipv6 ../nw_ipv6/src/nw_ipv6_context.vhd
ghdl -a --std=08 -frelaxed-rules --work=work ../nw_ipv6/tb/nw_ipv6_tb.vhd
ghdl -e --std=08 -frelaxed-rules --work=work nw_ipv6_tb
ghdl -r --std=08 -frelaxed-rules --work=work nw_ipv6_tb -gGC_GHDL=1
# nw_codec
echo -e "\nTesting nw_codec"
ghdl -a --std=08 -frelaxed-rules --work=nw_codec ../nw_codec/src/nw_sl_codec_pkg.vhd
ghdl -a --std=08 -frelaxed-rules --work=nw_codec ../nw_codec/src/nw_codec_context.vhd
ghdl -a --std=08 -frelaxed-rules --work=work ../nw_codec/tb/nw_codec_tb.vhd
ghdl -e --std=08 -frelaxed-rules --work=work nw_codec_tb
ghdl -r --std=08 -frelaxed-rules --work=work nw_codec_tb -gGC_GHDL=1