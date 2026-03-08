-------------------------------------------------------------------------------
-- Title      : AXI4-Stream package
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: 
--!\file
--!\brief AXI4-Stream sink and source
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

use work.nw_types_pkg.all;
use work.nw_util_pkg.all;
--! @endcond

--! See nw_axis.vhd for a description of the components.

package nw_axis_pkg is

  component axis_source is
    generic (
      GC_BYTES : integer range 1 to 1024
    );
    port ( 
      aclk      : in  std_logic;
      aresetn   : in  std_logic;
      tready    : in  std_logic;
      tvalid    : out std_logic;
      tdata     : out std_logic_vector(GC_BYTES * 8 - 1 downto 0);
      tkeep     : out std_logic_vector(GC_BYTES - 1 downto 0);
      tstrb     : out std_logic_vector(GC_BYTES - 1 downto 0);
      tlast     : out std_logic;
      done      : out std_logic;
      pkt_len   : in  natural;
      pkt_valid : in  std_logic;
      pkt       : in  t_slv_arr
    );
  end component axis_source;

  component axis_sink is
    generic (
      GC_BYTES        : integer range 1 to 1024;
      GC_MAX_PKT_SIZE : positive := 2000
    );
    port (
      aclk      : in  std_logic;
      aresetn   : in  std_logic;
      tready    : out  std_logic;
      tvalid    : in  std_logic;
      tdata     : in  std_logic_vector(GC_BYTES * 8 - 1 downto 0);
      tkeep     : in  std_logic_vector(GC_BYTES - 1 downto 0);
      tstrb     : in  std_logic_vector(GC_BYTES - 1 downto 0);
      tlast     : in  std_logic;
      pkt_len   : out  natural;
      pkt_valid : out  std_logic;
      pkt       : out  t_slv_arr(0 to GC_MAX_PKT_SIZE - 1)(7 downto 0)
    );
  end component axis_sink;

end package nw_axis_pkg;
