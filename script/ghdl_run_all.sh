#!/bin/bash
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
#nw_ipv6
echo -e "\nTesting nw_ipv6"
ghdl -a --std=08 -frelaxed-rules --work=nw_ipv6 ../nw_ipv6/src/nw_ipv6_pkg.vhd
ghdl -a --std=08 -frelaxed-rules --work=nw_ipv6 ../nw_ipv6/src/nw_udpv6_pkg.vhd
ghdl -a --std=08 -frelaxed-rules --work=nw_ipv6 ../nw_ipv6/src/nw_icmpv6_pkg.vhd
ghdl -a --std=08 -frelaxed-rules --work=nw_ipv6 ../nw_ipv6/src/nw_ipv6_context.vhd
ghdl -a --std=08 -frelaxed-rules --work=work ../nw_ipv6/tb/nw_ipv6_tb.vhd
ghdl -e --std=08 -frelaxed-rules --work=work nw_ipv6_tb
ghdl -r --std=08 -frelaxed-rules --work=work nw_ipv6_tb -gGC_GHDL=1