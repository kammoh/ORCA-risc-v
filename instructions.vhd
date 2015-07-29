library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

package instructions is
  function ARITH_INSTR (immediate, rs1, rd : integer; func : std_logic_vector(2 downto 0))
    return std_logic_vector;

  function ADDI (dest, srcreg, immediate : integer)
    return std_logic_vector;
  function SB (src, base, offset : integer)
    return std_logic_vector;
  function LB (dest, base, offset : integer)
    return std_logic_vector;

  function BRANCH (src1, src2, offset : integer; func : unsigned(2 downto 0))
    return std_logic_vector;
  function BEQ (src1, src2, offset : integer)
    return std_logic_vector;
  function BNE (src1, src2, offset : integer)
    return std_logic_vector;

end instructions;
package body instructions is

  function ARITH_INSTR (
    immediate, rs1, rd : integer;
    func               : std_logic_vector(2 downto 0))
    return std_logic_vector is
  begin
    return std_logic_vector(to_unsigned(immediate, 12)) &
      std_logic_vector(to_unsigned(rs1, 5))& func &
      std_logic_vector(to_unsigned(rd, 5))&"0010011";
  end;

  function ADDI (
    dest, srcreg, immediate : integer)
    return std_logic_vector is
  begin
    return ARITH_INSTR(immediate, srcreg, dest, "000");
  end;
  function SB (
    src, base, offset : integer)
    return std_logic_vector is
    variable imm : unsigned(11 downto 0);
  begin
    imm := to_unsigned(offset, 12);
    return std_logic_vector(imm(11 downto 5) &to_unsigned(src, 5) &
                            to_unsigned(base, 5)&"000"&imm(4 downto 0)&"0100011");
  end;
  function LB (
    dest, base, offset : integer)
    return std_logic_vector is
    variable imm : unsigned(11 downto 0);
  begin
    imm := to_unsigned(offset, 12);
    return std_logic_vector(imm & to_unsigned(base, 5)&"000"&to_unsigned(dest, 5)&"0000011");
  end;

  function BRANCH (
    src1, src2, offset : integer;
    func               : unsigned(2 downto 0))
    return std_logic_vector is
    variable imm : unsigned(12 downto 0);
  begin
    imm := to_unsigned(offset, 13);
    return std_logic_vector(imm(12)&imm(10 downto 5)&to_unsigned(src2, 5)
                            &to_unsigned(src1, 5)& func &
                            imm(4 downto 1)& imm(11) & "1100011");
  end;
  function BEQ (src1, src2, offset : integer)
    return std_logic_vector is
  begin
    return BRANCH(src1, src2, offset, "000");
  end;
  function BNE (src1, src2, offset : integer)
    return std_logic_vector is
  begin
    return BRANCH(src1, src2, offset, "001");
  end;
end instructions;
