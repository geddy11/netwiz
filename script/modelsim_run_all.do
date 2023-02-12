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
#
# run: vsim -c -do modelsim_run_all.do
#
echo "\n"
echo "███    ██ ███████ ████████ ██     ██ ██ ███████ "
echo "████   ██ ██         ██    ██     ██ ██    ███  "
echo "██ ██  ██ █████      ██    ██  █  ██ ██   ███   "
echo "██  ██ ██ ██         ██    ██ ███ ██ ██  ███    "
echo "██   ████ ███████    ██     ███ ███  ██ ███████ "
echo "\n"
vmap -c
vlib  nw_adapt
vmap nw_adapt ./nw_adapt
vcom -2008 -quiet -work ./nw_adapt ../nw_adapt/src/nw_adaptations_pkg.vhd
# nw_util
vlib  nw_util
vmap nw_util ./nw_util
vcom -2008 -quiet -work ./nw_util ../nw_util/src/nw_types_pkg.vhd
vcom -2008 -quiet -work ./nw_util ../nw_util/src/nw_util_pkg.vhd
vcom -2008 -quiet -work ./nw_util ../nw_util/src/nw_crc_pkg.vhd
vcom -2008 -quiet -work ./nw_util ../nw_util/src/nw_nrs_pkg.vhd
vcom -2008 -quiet -work ./nw_util ../nw_util/src/nw_prbs_pkg.vhd
vcom -2008 -quiet -work ./nw_util ../nw_util/src/nw_util_context.vhd
vlib work
vcom -2008 -quiet -work ./work ../nw_util/tb/nw_util_tb.vhd
vsim  -quiet -c nw_util_tb -do "onerror {quit -code 1}; run -all"
echo "\n"
# nw_pcap
vlib nw_pcap
vcom -2008 -quiet -work ./nw_pcap ../nw_pcap/src/nw_pcap_pkg.vhd
vcom -2008 -quiet -work ./work ../nw_pcap/tb/nw_pcap_tb.vhd
vsim -quiet -c nw_pcap_tb -do "onerror {quit -code 1}; run -all"
echo "\n"
# nw_ethernet
vlib nw_ethernet
vcom -2008 -quiet -work ./nw_ethernet ../nw_ethernet/src/nw_ethernet_pkg.vhd
vcom -2008 -quiet -work ./nw_ethernet ../nw_ethernet/src/nw_arp_pkg.vhd
vcom -2008 -quiet -work ./nw_ethernet ../nw_ethernet/src/nw_ethernet_context.vhd
vcom -2008 -quiet -work ./work ../nw_ethernet/tb/nw_ethernet_tb.vhd
vsim -quiet -c nw_ethernet_tb -do "onerror {quit -code 1}; run -all"
echo "\n"
# nw_ipv4
vlib nw_ipv4
vcom -2008 -quiet -work ./nw_ipv4 ../nw_ipv4/src/ip_protocols_pkg.vhd
vcom -2008 -quiet -work ./nw_ipv4 ../nw_ipv4/src/nw_ipv4_pkg.vhd
vcom -2008 -quiet -work ./nw_ipv4 ../nw_ipv4/src/nw_udpv4_pkg.vhd
vcom -2008 -quiet -work ./nw_ipv4 ../nw_ipv4/src/nw_icmpv4_pkg.vhd
vcom -2008 -quiet -work ./nw_ipv4 ../nw_ipv4/src/nw_ipv4_context.vhd
vcom -2008 -quiet -work ./work ../nw_ipv4/tb/nw_ipv4_tb.vhd
vsim -quiet -c nw_ipv4_tb -do "onerror {quit -code 1}; run -all"
echo "\n"
# n4_ipv6
vlib nw_ipv6
vcom -2008 -quiet -work ./nw_ipv6 ../nw_ipv6/src/nw_ipv6_pkg.vhd
vcom -2008 -quiet -work ./nw_ipv6 ../nw_ipv6/src/nw_udpv6_pkg.vhd
vcom -2008 -quiet -work ./nw_ipv6 ../nw_ipv6/src/nw_icmpv6_pkg.vhd
vcom -2008 -quiet -work ./nw_ipv6 ../nw_ipv6/src/nw_ipv6_context.vhd
vcom -2008 -quiet -work ./work ../nw_ipv6/tb/nw_ipv6_tb.vhd
vsim -quiet -c nw_ipv6_tb -do "onerror {quit -code 1}; run -all"
echo "\n"
# nw_codec
vlib nw_codec
vcom -2008 -quiet -work ./nw_codec ../nw_codec/src/nw_sl_codec_pkg.vhd
vcom -2008 -quiet -work ./nw_codec ../nw_codec/src/nw_cobs_pkg.vhd
vcom -2008 -quiet -work ./nw_codec ../nw_codec/src/nw_codec_context.vhd
vcom -2008 -quiet -work ./work ../nw_codec/tb/nw_codec_tb.vhd
vsim -quiet -c nw_codec_tb -do "onerror {quit -code 1}; run -all"
echo "\n"
# nw_ptp
vlib nw_ptp
vcom -2008 -quiet -work ./nw_ptp ../nw_ptp/src/nw_ptpv2_pkg.vhd
vcom -2008 -quiet -work ./work ../nw_ptp/tb/nw_ptp_tb.vhd
vsim -quiet -c nw_ptp_tb -do "onerror {quit -code 1}; run -all; exit"