-------------------------------------------------------------------------------
-- Title      : Network Wizard IPv4 context
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: 
--!\file
--!\brief IPv4 context
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

context nw_ipv4_context is
  library nw_ipv4;
  use nw_ipv4.ip_protocols_pkg.all;
  use nw_ipv4.nw_ipv4_pkg.all;
  use nw_ipv4.nw_udpv4_pkg.all;
  use nw_ipv4.nw_icmpv4_pkg.all;
  use nw_ipv4.nw_tcpv4_pkg.all;
end context nw_ipv4_context;
