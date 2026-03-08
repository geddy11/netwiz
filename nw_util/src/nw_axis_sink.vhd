-------------------------------------------------------------------------------
-- Title      : AXI4-Stream sink
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: 
--!\file nw_axis_sink.vhd
--!\brief AXI4-Stream sink
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
--! @cond libraries
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library nw_adapt;
use nw_adapt.nw_adaptations_pkg.all;
library nw_util;
context nw_util.nw_util_context;
--! @endcond

--! \page nw_axis_sink AXI-Stream sink
--! \tableofcontents
--!
--! The AXI-Stream sink module will receive data packets on the bus.
--! When `tlast` is asserted, marking the end of the packet, the `pkt_valid`
--! signal is asserted for one clock cycle.
--!
--! **Instantiation template**
--!
--! ```vhdl
--! i_axis_sink : entity nw_util.axis_sink
--!      generic map (
--!        GC_BYTES        => 4,
--!        GC_MAX_PKT_SIZE => 1600
--!      )
--!      port map (
--!        aclk      => aclk,
--!        aresetn   => aresetn,
--!        tready    => tready,
--!        tvalid    => tvalid,
--!        tdata     => tdata,
--!        tkeep     => tkeep,
--!        tstrb     => tstrb,
--!        tlast     => tlast,
--!        pkt_len   => pkt_len,
--!        pkt_valid => pkt_valid,
--!        pkt       => pkt
--!      );
--! ```
--! See further examples in the test bench nw_axis_tb.vhd.
entity axis_sink is
  generic (
    GC_BYTES        : integer range 1 to 1024; --! Width of axis data in bytes
    GC_MAX_PKT_SIZE : positive := 2000 --! Max paket size (bytes) to receive
  );
  port (
    aclk      : in  std_logic; --! AXI-Stream clock
    aresetn   : in  std_logic; --! AXI-Stream reset
    tready    : out std_logic; --! AXI-Stream ready
    tvalid    : in  std_logic; --! AXI-Stream data valid
    tdata     : in  std_logic_vector(GC_BYTES * 8 - 1 downto 0); --! AXI-Stream data
    tkeep     : in  std_logic_vector(GC_BYTES - 1 downto 0); --! AXI-Stream data stream qualifier
    tstrb     : in  std_logic_vector(GC_BYTES - 1 downto 0); --! AXI-Stream data byte qualifier
    tlast     : in  std_logic; --! AXI-Stream last data
    pkt_len   : out natural                                         := 0; --! Packet length
    pkt_valid : out std_logic                                       := '0'; --! Packet valid strobe
    pkt       : out t_slv_arr(0 to GC_MAX_PKT_SIZE - 1)(7 downto 0) := (others => (others => '0')) --! Packet received
  );
end entity axis_sink;

architecture behave of axis_sink is
begin

  p_sink: process (aclk) is
    variable v_pkt : t_slv_arr(0 to GC_MAX_PKT_SIZE - 1)(7 downto 0);
    variable v_cnt : integer := 0;
  begin
    if falling_edge(aclk) then
      pkt_valid <= '0';
      tready    <= '1';
      if tvalid = '1' then
        for i in 0 to GC_BYTES - 1 loop
          if tkeep(i) = '1' and tstrb(i) = '1' and v_cnt < GC_MAX_PKT_SIZE then
            v_pkt(v_cnt) := tdata(i*8 + 7 downto i*8);
            v_cnt        := v_cnt + 1;
          end if;
        end loop;
        if tlast = '1' then
          pkt       <= v_pkt;
          pkt_len   <= v_cnt;
          pkt_valid <= '1';
          v_cnt     := 0;
        end if;
      end if;
      if aresetn = '0' then
        tready    <= '0';
        pkt_valid <= '0';
        pkt_len   <= 0;
        pkt       <= (others => (others => '0'));
        v_cnt     := 0;
      end if;
    end if;
  end process p_sink;

end architecture behave;
