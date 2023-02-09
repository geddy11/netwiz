-------------------------------------------------------------------------------
-- Title      : Network Wizard adaptations package
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: 
--!\file
--!\brief This package contains parameters that can be used to tailor netwiz for specific projects.
--
-------------------------------------------------------------------------------
-- MIT License
--
-- Copyright (c) 2023 Geir Drange
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
--! @endcond

package nw_adaptations_pkg is

  -------------------------------------------------------------------------------
  -- Severity level of assertion violations.
  -------------------------------------------------------------------------------
  constant C_SEVERITY : severity_level := error;

  -------------------------------------------------------------------------------
  -- Width (chars) of timestamp in msg() output.
  -------------------------------------------------------------------------------
  constant C_TIME_WIDTH : integer := 15;

  -------------------------------------------------------------------------------
  -- IPv6 options
  -------------------------------------------------------------------------------
  constant C_IPV6_MAX_EXT_HEADERS     : natural := 8;  -- Maximum number of extension headers to support
  constant C_IPV6_MAX_EXT_HEADER_SIZE : natural := 256;  -- Maximum size (bytes) of extension header options

  -------------------------------------------------------------------------------
  -- PTPv2 options
  -------------------------------------------------------------------------------
  constant C_PTPV2_MAX_TLV_BYTES : natural := 256; -- Maximum number of bytes of TLV data (total)

end package nw_adaptations_pkg;
