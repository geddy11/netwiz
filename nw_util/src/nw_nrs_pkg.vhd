-------------------------------------------------------------------------------
-- Title      : NRS package
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: 
--!\file
--!\brief Generate Non-random Sequences
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

library nw_adapt;
use nw_adapt.nw_adaptations_pkg.all;

use work.nw_types_pkg.all;
--! @endcond

--! \page nw_nrs NRS
--! \tableofcontents
--! \section nrs Non-Random Sequences
--! The NRS library provides functions for generation of non-random sequences.
--!
--! \subsection nrs_subsec1 Functionality
--! \li Generate data arrays with constant or incrementing/decrementing numbers.
--! \li Any data width and array length
--!
--! \n More details in \ref nw_nrs_pkg
--! \subsection nrs_subsec2 Example use
--! Include the libraries:
--! ~~~
--! library nw_util;
--! context nw_util.nw_util_context;
--! ~~~
--! Call f_gen_nrs() with desired parameters:
--! ~~~
--! array_8bit(0 to 127) := f_gen_nrs(x"80", 128); -- array_8bit is now (x"80", x"81", x"82", ...)
--! array_48bit(0 to 15) := f_gen_nrs(x"ff0000", 16, x"10000", False); -- array_48bit is now (x"ff0000", x"fe0000", x"fd0000", ...)
--! ~~~
--! See further examples in the test bench nw_util_tb.vhd.
package nw_nrs_pkg is

  -------------------------------------------------------------------------------
  -- Functions
  --@cond functions
  -------------------------------------------------------------------------------
  function f_gen_nrs(start_val : std_logic_vector;
                     len       : positive;
                     step      : std_logic_vector := "1";
                     step_up   : boolean          := true) return t_slv_arr;
  -- @endcond

end package nw_nrs_pkg;

package body nw_nrs_pkg is

  -------------------------------------------------------------------------------
  --! \brief Create Non-random sequence
  --! \param start_val   Start value (array will have same data width as start_val)
  --! \param len         Data array length
  --! \param step        Increment/decrement between each data word (default 1)
  --! \param step_up     True (default) for increment, False for decrement
  --! \return            PRBS sequence in data array
  --!
  --! Generate a non-random sequence. The first value is start_val and the value will increment or decrement with
  --! the step value for each word. 
  --!
  --! **Example use**
  --! ~~~
  --! array_8bit(0 to 127) := f_gen_nrs(x"00", 128); -- array_8bit is now (x"00", x"01", x"02", ...)
  --! ~~~
  -------------------------------------------------------------------------------
  function f_gen_nrs(start_val : std_logic_vector;
                     len       : positive;
                     step      : std_logic_vector := "1";
                     step_up   : boolean          := true)
    return t_slv_arr is
    constant C_MAX   : unsigned(start_val'length - 1 downto 0)                := (others => '1');
    variable v_start : unsigned(start_val'length - 1 downto 0)                := unsigned(start_val);
    variable v_step  : unsigned(step'length - 1 downto 0) := (others => '0');
    variable v_data  : t_slv_arr(0 to len - 1)(start_val'length - 1 downto 0) := (others => std_logic_vector(v_start));
  begin
    assert start_val'length >= step'length report "f_gen_nrs: the step value width must be less or equal to the start_val width" severity C_SEVERITY;

    v_step(step'length - 1 downto 0) := unsigned(step);
    for i in 1 to len - 1 loop
      if step_up then
        v_start := v_start + v_step;
      else
        v_start := v_start - v_step;
      end if;
      v_data(i) := std_logic_vector(v_start);
    end loop;
    return v_data;
  end function f_gen_nrs;

end package body nw_nrs_pkg;
