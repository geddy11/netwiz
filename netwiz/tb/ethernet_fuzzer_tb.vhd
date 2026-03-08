-------------------------------------------------------------------------------
-- Title      : Network Wizard - Ethernet packet fuzzer
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: Test bench demonstrating an Ethernet packet fuzzer
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

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library netwiz;
context netwiz.netwiz_context;

entity ethernet_fuzzer_tb is
end entity ethernet_fuzzer_tb;

architecture tb of ethernet_fuzzer_tb is

  constant C_ETH_TYPES : t_slv_arr(0 to 4)(15 downto 0) := (C_ET_IPV4, C_ET_IPV4, C_ET_IPV4, C_ET_IPV4, C_ET_ARP); -- 80% IPv4, 20% ARP
  constant C_MAX_SIZE  : integer                        := 1550; -- max packet size

  -------------------------------------------------------------------------------
  -- rand_pkt(): Create random Ethernet packet containing either IPv4 or ARP.
  -------------------------------------------------------------------------------
  procedure rand_pkt(
    signal pkt : inout t_slv_arr(0 to C_MAX_SIZE - 1)(7 downto 0);
    signal len : out natural
  ) is
    variable v_rand48   : t_slv_arr(0 to 8)(47 downto 0);
    variable v_rand8    : t_slv_arr(0 to 39)(7 downto 0);
    variable v_pdata    : t_slv_arr(0 to C_MAX_SIZE - 1)(7 downto 0);
    variable v_eth_hdr  : t_ethernet_header;
    variable v_ipv4_hdr : t_ipv4_header;
    variable v_opts     : t_ipv4_options;
    variable v_ihl      : natural;
    variable v_len      : integer;
    variable v_arp_hdr  : t_arp_header;
    variable v_plen     : integer;
  begin
    -- Ethernet header
    v_eth_hdr           := C_DEFAULT_ETH_HEADER;
    v_eth_hdr.mac_dest  := f_randmac;
    wait for std.env.resolution_limit; -- make sure we get a new seed for f_randmac()
    v_eth_hdr.mac_src   := f_randmac((x"3d", x"fc", x"1a", x"00", x"00", x"00"),(x"ff", x"ff", x"ff", x"00", x"00", x"00"));
    v_eth_hdr.ethertype := f_randsel(C_ETH_TYPES); -- random type from list
    -- Ethernet payload: Either IPv4 or ARP
    v_rand48            := f_gen_prbs(C_POLY_X21_X19_1, 48, 9); -- random 48bit vectors
    if v_eth_hdr.ethertype = C_ET_IPV4 then -- IPv4
      v_ipv4_hdr     := C_DEFAULT_IPV4_HEADER;
      v_ihl          := f_randnat(5, 15); -- random header length
      v_ipv4_hdr.ihl := std_logic_vector(to_unsigned(v_ihl, 4)); -- header length
      if v_ihl > 5 then
        v_rand8              := f_gen_prbs(C_POLY_X18_X11_1, 8, 40); -- random 8bit vectors
        v_opts.copied        := v_rand8(0)(0);
        v_opts.option_class  := v_rand8(0)(2 downto 1);
        v_opts.option_number := v_rand8(0)(7 downto 3);
        v_opts.option_length := v_rand8(1);
        v_opts.option_data   := v_rand8(2 to 39);
        v_ipv4_hdr.options   := v_opts;
      end if;
      -- IP header fields
      -- version, length and chksum will be valid, all other fields are fuzzed
      v_ipv4_hdr.version             := x"4"; -- keep IP version 4
      v_ipv4_hdr.dscp                := v_rand48(0)(5 downto 0);  -- Differentiated Services Code Point (DSCP)
      v_ipv4_hdr.ecn                 := v_rand48(1)(1 downto 0);  -- Explicit Congestion Notification (ECN)
      v_ipv4_hdr.length              := std_logic_vector(to_unsigned(f_randnat(v_ihl*4 + 1, C_MAX_SIZE - 18), 16));  -- Total IP length (including header)
      v_ipv4_hdr.identification      := v_rand48(2)(15 downto 0);  -- Identification
      v_ipv4_hdr.flags               := v_rand48(3)(2 downto 0);  -- Flags
      v_ipv4_hdr.fragment_offs       := v_rand48(4)(12 downto 0);  -- Fragment offset
      v_ipv4_hdr.ttl                 := v_rand48(5)(7 downto 0);  -- Time to live (TTL)
      v_ipv4_hdr.protocol            := v_rand48(6)(7 downto 0);  -- Protocol
      v_ipv4_hdr.src_ip              := v_rand48(7)(31 downto 0);  -- Source address
      v_ipv4_hdr.dest_ip             := v_rand48(8)(31 downto 0);  -- Destination address
      v_pdata                        := f_gen_prbs(C_POLY_X23_X18_1, 8, C_MAX_SIZE); -- random vectors
      v_plen                         := f_ipv4_create_pkt_len(v_ipv4_hdr, v_pdata(0 to to_integer(unsigned(v_ipv4_hdr.length)) - v_ihl*4 - 1));
      v_pdata(0 to v_plen - 1)       := f_ipv4_create_pkt(v_ipv4_hdr, v_pdata(0 to to_integer(unsigned(v_ipv4_hdr.length)) - v_ihl*4 - 1));
    else -- ARP
      v_arp_hdr.htype                := v_rand48(0)(15 downto 0);  -- Hardware type
      v_arp_hdr.ptype                := v_rand48(1)(15 downto 0);  -- Protocol type
      v_arp_hdr.hlen                 := x"06";  -- Hardware address length
      v_arp_hdr.plen                 := x"04";  -- Protocol address length 
      v_arp_hdr.operation            := v_rand48(4)(15 downto 0);  -- Operation
      v_arp_hdr.sender_hw_addr       := v_rand48(5);  -- Sender hardware address
      v_arp_hdr.sender_protocol_addr := v_rand48(6)(31 downto 0);  -- Sender protocol address
      v_arp_hdr.target_hw_addr       := v_rand48(7);  -- Target hardware address
      v_arp_hdr.target_protocol_addr := v_rand48(8)(31 downto 0); -- Target protocol address
      v_plen                         := f_arp_create_pkt_len(v_arp_hdr);
      v_pdata(0 to v_plen - 1)       := f_arp_create_pkt(v_arp_hdr);
    end if;
    -- assemble Ethernet packet
    v_len               := f_eth_create_pkt_len(v_eth_hdr, v_pdata(0 to v_plen - 1));
    pkt(0 to v_len - 1) <= f_eth_create_pkt(v_eth_hdr, v_pdata(0 to v_plen - 1));
    len                 <= v_len;
  end procedure rand_pkt;

  signal aclk      : std_logic;
  signal aresetn   : std_logic;
  signal tdata     : std_logic_vector(31 downto 0);
  signal tkeep     : std_logic_vector(3 downto 0);
  signal tready    : std_logic;
  signal tlast     : std_logic;
  signal tvalid    : std_logic;
  signal done      : std_logic;
  signal pkt       : t_slv_arr(0 to C_MAX_SIZE - 1)(7 downto 0);
  signal pkt_valid : std_logic := '0';
  signal pkt_len   : natural;
  signal rx_pkt       : t_slv_arr(0 to C_MAX_SIZE - 1)(7 downto 0);
  signal rx_pkt_len   : natural;
  signal rx_pkt_valid : std_logic;

begin

  -------------------------------------------------------------------------------
  -- AXIS source: Send random packets continuously
  -------------------------------------------------------------------------------
  i_axis_source : entity nw_util.axis_source
    generic map (
      GC_BYTES => 4
    )
    port map (
      aclk      => aclk,
      aresetn   => aresetn,
      tready    => tready,
      tvalid    => tvalid,
      tdata     => tdata,
      tkeep     => tkeep,
      tstrb     => open,
      tlast     => tlast,
      done      => done, 
      pkt_len   => pkt_len,
      pkt_valid => pkt_valid,
      pkt       => pkt
    );

  -------------------------------------------------------------------------------
  -- AXIS sink: Check CRC on recevied Ethernet packets, also IP checksum
  -------------------------------------------------------------------------------
  i_axis_sink : entity nw_util.axis_sink
    generic map (
      GC_BYTES        => 4,
      GC_MAX_PKT_SIZE => C_MAX_SIZE
    )
    port map (
      aclk      => aclk,
      aresetn   => aresetn,
      tready    => tready,
      tvalid    => tvalid,
      tdata     => tdata,
      tkeep     => tkeep,
      tstrb     => "1111",
      tlast     => tlast,
      pkt_len   => rx_pkt_len,
      pkt_valid => rx_pkt_valid,
      pkt       => rx_pkt
    );

  -------------------------------------------------------------------------------
  -- Clock and reset
  -------------------------------------------------------------------------------
  p_clk : process is
  begin
    aclk <= '0';
    wait for 5 ns;
    aclk <= '1';
    wait for 5 ns;
  end process p_clk;

  p_rst : process is
  begin
    aresetn <= '0';
    wait for 120 ns;
    aresetn <= '1';
    wait;
  end process p_rst;

  -------------------------------------------------------------------------------
  -- Fuzzer: Create random packets, transmit over AXIS, check CRC and IP checksum
  -- at receiving end.
  -------------------------------------------------------------------------------
  p_fuzz : process is
    variable v_len     : integer;
    variable v_eth_hdr : t_ethernet_header;
    variable v_ip_pkt  : t_slv_arr(0 to C_MAX_SIZE - 1)(7 downto 0);
    variable v_ip_hdr  : t_ipv4_header;
  begin
    pkt_valid <= '0';
    wait until aresetn = '1';
    msg("Start packet fuzzer");
    for i in 0 to 99 loop
      if done = '0' then
        wait until done = '1';
      end if;
      wait until rising_edge(aclk);
      rand_pkt(pkt, pkt_len);
      pkt_valid <= '1';
      wait until rising_edge(aclk);
      pkt_valid <= '0';
      wait until rx_pkt_valid = '1';
      -- check Ethernet CRC
      assert f_eth_crc_ok(rx_pkt(0 to rx_pkt_len - 1))
        report "Packet #" & to_string(i+1) & " CRC error" severity failure;
      -- If IPv4, check IP checksum
      v_eth_hdr := f_eth_get_header(rx_pkt(0 to rx_pkt_len - 1));
      if v_eth_hdr.ethertype = C_ET_IPV4 then
        v_len                    := f_eth_get_payload_len(rx_pkt(0 to rx_pkt_len - 1));
        v_ip_pkt(0 to v_len - 1) := f_eth_get_payload(rx_pkt(0 to rx_pkt_len - 1));
        v_ip_hdr                 := f_ipv4_get_header(v_ip_pkt(0 to v_len - 1));
        assert f_ipv4_chksum_ok(v_ip_pkt(0 to v_len - 1))
          report "Packet #" & to_string(i+1) & " IP checksum error" severity failure;
      end if;
    end loop;

    wait for 10 ns;
    -- Finish the simulation
    msg("All tests are pass!");
    std.env.stop;
    wait; -- to stop completely
    end process p_fuzz;

end architecture  tb;
