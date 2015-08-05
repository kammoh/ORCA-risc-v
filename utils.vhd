library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

package utils is
  function log2 (
    i : natural)
    return integer;

end utils;
package body utils is
function log2( i : natural) return integer is
    variable temp    : integer := i;
    variable ret_val : integer := 0;
  begin
    while temp > 1 loop
      ret_val := ret_val + 1;
      temp    := temp / 2;
    end loop;
    return ret_val;
  end function;

end utils;
