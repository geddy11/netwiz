-------------------------------------------------------------------------------
-- Title      : AXI4-Stream source
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: 
--!\file nw_axis_source.vhd
--!\brief AXI4-Stream source
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

--! \page nw_axis_source AXI-Stream source
--! \tableofcontents
--!
--! The AXI-Stream source module will send a packet on the bus when `pkt_valid`
--! is asserted. The `done` signal is asserted when the transmission is complete.
--! The width of the data bus is defined by a generic.
--!
--! **Instantiation template**
--!
--! ```vhdl
--! i_axis_source : entity nw_util.axis_source
--!      generic map (
--!        GC_BYTES => 4
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
--!        done      => done,
--!        pkt_len   => pkt_len,
--!        pkt_valid => pkt_valid,
--!        pkt       => pkt
--!      );
--! ```
--! See further examples in the test bench nw_axis_tb.vhd.
entity axis_source is
  generic (
    GC_BYTES : integer range 1 to 1024 --! Width of axis data in bytes
  );
  port (
    aclk      : in  std_logic; --! AXI-Stream clock
    aresetn   : in  std_logic; --! AXI-Stream reset
    tready    : in  std_logic; --! AXI-Stream ready
    tvalid    : out std_logic; --! AXI-Stream data valid
    tdata     : out std_logic_vector(GC_BYTES * 8 - 1 downto 0); --! AXI-Stream data
    tkeep     : out std_logic_vector(GC_BYTES - 1 downto 0); --! AXI-Stream data stream qualifier
    tstrb     : out std_logic_vector(GC_BYTES - 1 downto 0); --! AXI-Stream data byte qualifier
    tlast     : out std_logic; --! AXI-Stream last data
    done      : out std_logic; --! Packet send done
    pkt_len   : in  natural; --! Packet length (bytes)
    pkt_valid : in  std_logic; --! Packet valid
    pkt       : in  t_slv_arr(open)(7 downto 0) --! Packet to send
  );
end entity axis_source;

architecture behave of axis_source is

  type t_fsm is (IDLE, TX, LAST);

  signal fsm : t_fsm;

begin

  assert pkt'ascending report "axis_source: packet array must be ascending" severity C_SEVERITY;
  assert pkt'high - pkt'low + 1 >= pkt_len report "axis_source: packet array must be as large as pkt_len" severity C_SEVERITY;

  p_source: process (aclk) is
    variable v_cnt   : natural;
    variable v_start : natural;
    variable v_end   : natural;

    procedure data (
      signal pkt : in t_slv_arr(open)(7 downto 0);
      signal tdata: out std_logic_vector;
      signal tkeep: out std_logic_vector;
      signal tstrb: out std_logic_vector;
      signal tlast: out std_logic;
      signal tvalid: out std_logic;
      variable v_cnt: inout natural;
      variable v_start : in natural;
      variable v_end : in natural
    ) is
    begin
      tlast <= '0';
      for i in 0 to GC_BYTES - 1 loop
        if v_cnt < v_end then
          tdata(i * 8 + 7 downto i * 8) <= pkt(v_cnt);
          tkeep(i) <= '1';
          tstrb(i) <= '1';
          v_cnt := v_cnt + 1;
          if v_cnt = v_end then
            tlast <= '1';
          end if;
        else
          tdata(i * 8 + 7 downto i * 8) <= x"00";
          tkeep(i) <= '0';
          tstrb(i) <= '0';
          tlast    <= '1';
        end if;
      end loop;
      tvalid <= '1';
    end procedure data;

  begin
    if falling_edge(aclk) then
      case fsm is
        when IDLE =>
          done <= '1';
          v_start := pkt'low;
          v_end := pkt'low + pkt_len;
          v_cnt := 0;
          if pkt_valid = '1' then
            data(pkt, tdata, tkeep, tstrb, tlast, tvalid, v_cnt, v_start, v_end);
            done <= '0';
            fsm <= TX;
          end if;
        when TX =>         
          if tready = '1' then
            if v_cnt = v_end then
              tvalid <= '0';
              tlast <= '0';
              tkeep <= (others => '0');
              tstrb <= (others => '0');
              tdata <= (others => '0');
              fsm <= IDLE;
            else
              data(pkt, tdata, tkeep, tstrb, tlast, tvalid, v_cnt, v_start, v_end);
            end if;
          end if;
        when LAST => 
          null;
      end case;
      if aresetn = '0' then
        fsm    <= IDLE;
        done   <= '1';
        tdata  <= (others => '0');
        tvalid <= '0';
        tkeep  <= (others => '0');
        tstrb  <= (others => '0');
        tlast  <= '0';
      end if;
    end if;
  end process p_source;

end architecture behave;
